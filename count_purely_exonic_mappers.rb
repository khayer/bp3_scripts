#!/usr/bin/env ruby
require 'optparse'
require 'logger'

$logger = Logger.new(STDERR)
$genes = []

# Initialize logger
def setup_logger(loglevel)
  case loglevel
  when "debug"
    $logger.level = Logger::DEBUG
  when "warn"
    $logger.level = Logger::WARN
  when "info"
    $logger.level = Logger::INFO
  else
    $logger.level = Logger::ERROR
  end
end

def setup_options(args)
  options = {:single_end=>false, :out_file=>"counts.txt"}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] file.sam file.gtf"
    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: counts.txt") do |a|
      options[:out_file] = a
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
    end

    #opts.on("-c", "--cut_off",:REQUIRED, Integer, "Set cut_off default is 1000") do |v|
    #  options[:cut_off] = v
    #end

    opts.on("-s", "--single_end", "Run in Single End mode? Default:false") do |v|
      options[:single_end] = true
    end
  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  raise "Please specify the sam files" if args.length == 0
  options
end

def read_gtf(gtf)
  genes = {}
  chr = 0
  feature = 2
  start = 3
  stop = 4
  strand = 6
  ids = 8
  File.open(gtf).each do |line|
    line.chomp!
    line = line.split("\t")
    #chr1  mm9_refGene start_codon 134212807 134212809 0.000000  + . gene_id "NM_028778"; transcript_id "NM_028778";
    next unless line[feature] == "exon"
    genes[line[chr]] ||= {}
    genes[line[chr]][[line[start].to_i,line[stop].to_i]] = line[ids]
  end
  genes
end

def read_sam(sam,out_file)
  counts = []
  #seq.1  83  chr17 31991179  255 93M8S = 31988304  2967
  #GGTTCAAAAGTTTCATGAGCTGGACCTCCCGGTAGATCTTCTCCAGATTGCTAGAATCTAACCGTGTCTTGTCAATTATTTTTATTGCAACCTGCGTTTTN
  # #1=DFFFFHHHFHIJJIHGIIJIIJJIIIHJIJIIIGIJJJHJIHIJJJJJJGHIJIJIGGGGHGHAHHDDBBCB>?<CDDDDD>@CC@>CCACDC><@>8
  #XO:A:F  NH:i:1  HI:i:1
  name = 0
  bin = 1
  chr = 2
  pos = 3
  cigar = 5
  tags = 11...-1

  counts[0] = 0

  #positions = []
  #cur_name = "dummy"
  sam_handle = File.open(sam)
  sam_handle.each do |line|
    next if line =~ /^@/
    line.chomp!
    line.gsub!(/IH\:i\:/,"NH:i:")
    next unless line =~ /NH\:i\:1/
    line = line.split("\t")
    pair = sam_handle.readline()
    pair = pair.split("\t")
    next unless line[chr] = pair[chr]
    next unless $genes[line[chr]]
    selected_genes = $genes[line[chr]].keys.keep_if {|v| (v[0]-500000 < line[pos].to_i && v[0]+500000 > line[pos].to_i)}
    fragments_line = make_fragment(line[pos].to_i,line[cigar])
    fragments_pair = make_fragment(pair[pos].to_i,pair[cigar])
    if test_fragments(line[chr],fragments_pair,fragments_line,selected_genes)
      counts[0] += 1
      out_file.puts line[name]
    end
  end
  counts
end

def test_fragments(chr,fragments_pair,fragments_line,selected_genes)
  #passed = false
  line_id = nil
  pair_id = nil
  selected_genes.each do |member|
    unless line_id
      fragments_line.each do |frag|
        line_id = $genes[chr][member] if (frag[0] >= member[0] &&
        frag[1] <= member[1])
      end
    end

    unless pair_id
      fragments_pair.each do |frag|
        pair_id = $genes[chr][member] if (frag[0] >= member[0] &&
        frag[1] <= member[1])
      end
    end
    break if pair_id && line_id
  end

    #fragments_line.each do |frag|
    #  line_id << $genes[chr][member] if (frag[0] >= member[0] &&
    #    frag[1] <= member[1])
    #end
#
    #fragments_pair.each do |frag|
    #  pair_id << $genes[chr][member] if (frag[0] >= member[0] &&
    #    frag[1] <= member[1])
    #end

  #puts "line_id #{line_id.join("\t")}"
  #puts "pair_id #{pair_id.join("\t")}"
  line_id && pair_id
end

def make_fragment(pos,cigar)
  fragments=[]
  nums = cigar.split(/\D/).map { |e| e.to_i  }
  letters = cigar.split(/\d/).keep_if {|v| !v.empty?}
  cur_pos = pos
  letters.each_with_index do |e,i|
    case e
    when "M"
      fragments << [cur_pos,cur_pos+nums[i]-1]
      cur_pos += nums[i]
    when /[ND]/
      cur_pos += nums[i]
    else
    end
  end
  fragments
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)

  $genes = read_gtf(ARGV[1])
  out_file = File.open(options[:out_file],'w')
  counts = read_sam(ARGV[0],out_file)
  out_file.puts "SUM: #{counts[0]}"
end

if __FILE__ == $0
  run(ARGV)
end

