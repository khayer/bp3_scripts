require 'logger'
path = File.expand_path(File.dirname(__FILE__))
require "#{path}/logging"
include Logging
require 'optparse'

#####
#
# Script fixes the following problem:
# HTSeq shows the following output:
#
# - /home/hayer/tools/HTSeq-0.6.1/build/scripts-2.6/htseq-count -s no -m intersection-strict ../gsnap_out/Sample_4139_neu.sam /home/hayer/index/ensembl_mm9_oct_2015_fixed.gtf > ../htseq/Sample_4139_htscounts_fixed_ns.txt
# - Error occured when processing SAM input (line 47 of file ../gsnap_out/Sample_4139_neu.sam):
#   ("Malformed SAM line: MRNM == '*' although flag bit &0x0008 cleared", 'line 47 of file ../gsnap_out/Sample_4139_neu.sam')
# -   [Exception type: ValueError, raised in _HTSeq.pyx:1323]
# - IS:
#
#     - seq.5a    69    *    0    0    *    chr1    24621370    0
#     - seq.5a    129    chr1    24621370    3    101M    *    0    0
# - Should be:
#
#     - seq.5a    69    *    0    0    *    chr1    24621370    0
#     - seq.5a    137    chr1    24621370    3    101M    *    0    0
# - Since mate is unmapped!!!!
#
####

# 2016/1/20 Katharina Hayer

$logger = Logger.new(STDERR)

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
  options = {
    :out_file =>  "counts.txt",
    :loglevel => "error",
    :debug => false
  }

  opt_parser = OptionParser.new do |opts|
    opts.banner = "\nUsage: ruby add_num_iso.rb [options] txt_file gtf_file"
    opts.separator ""
    opts.separator "txt_file: output of PORT"
    opts.separator "gtf_file: maybe from UCSC; needs to be the same as the one used for prev. step"
    opts.separator ""
    # enumeration
    #opts.on('-a', '--algorithm ENUM', [:all,:clc, :contextmap2,
    #  :crac, :gsnap, :hisat, :hisat2, :mapsplice2, :novoalign, :olego, :rum,
    #  :star,:soapsplice, :subread, :tophat2],'Choose from below:','all: DEFAULT',
    #  'clc','contextmap2','crac','gsnap','hisat', 'hisat2', 'mapsplice2','novoalign',
    #  'olego','rum','star','soapsplice','subread','tophat2') do |v|
    #  options[:algorithm] = v
    #end

    opts.on("-d", "--debug", "Run in debug mode") do |v|
      options[:log_level] = "debug"
      options[:debug] = true
    end

    #opts.on("-o", "--out_file [OUT_FILE]",
    #  :REQUIRED,String,
    #  "File for the output, Default: overview_table.xls") do |anno_file|
    #  options[:out_file] = anno_file
    #end

    #opts.on("-s", "--species [String]",
    #  :REQUIRED,String,
    #  "Spiecies, Default: human") do |s|
    #  options[:species] = s
    #end

    opts.on("-v", "--verbose", "Run verbosely") do |v|
      options[:log_level] = "info"
    end

    opts.separator ""
  end

  args = ["-h"] if args.length == 0
  opt_parser.parse!(args)
  setup_logger(options[:log_level])
  if args.length != 2
    $logger.error("You only provided #{args.length} fields, but 2 required!")
    raise "Please specify the input ( txt_file and gtf_file)"
  end
  options
end

#class Job
#  def initialize(jobnumber, cmd, status, working_dir)
#    @jobnumber = jobnumber
#    @cmd = cmd
#    @status = status
#    @working_dir = working_dir
#  end
#
#  attr_accessor :jobnumber, :cmd, :status
#
#  def to_s
#    "Jobnumber #{@jobnumber}; Cmd: #{@cmd}; Status: #{@status}; WD: #{@working_dir}"
#  end
#
#  def update_status
#    begin
#      l = `bjobs -l #{@jobnumber}`
#    rescue Exception => e
#      $logger.error(e)
#      $logger.error("bjobs not found!\n#{self}")
#      @status = "EXIT"
#      return
#    end
#    # if @status == "EXIT"
#    l.chomp!
#    if l == ""
#      $logger.error("Jobnumber #{@jobnumber} not found! #{self}")
#      @status = "EXIT"
#    else
#      l = l.delete(" \n")
#      @status = l.split("Status")[1].split(",")[0].gsub(/\W/,"")
#    end
#  end
#
#end

def read_gtf(filename)
  lengths = {}
  File.open(filename).each do |line|
    line.chomp!
    next unless line =~ /\texon\t/
    fields = line.split("\t")
    fields[-1] =~ /(ENSMUSG\d*)/
    gene_id = $1
    fields[-1] =~ /(ENSMUST\d*)/
    trans_id = $1
    lengths[gene_id] ||= {}
    lengths[gene_id][trans_id] ||= 0
    lengths[gene_id][trans_id] += fields[4].to_i - fields[3].to_i
  end
  lengths
end

def write_new(port_out, lengths)
  first = true
  File.open(port_out).each do |line|
    line.chomp!
    fields = line.split("\t")
    if first
      fields.insert(1,"NumIso")
      first = false
    else
      fields.insert(1,lengths[fields[0]].values.length)
    end
    #   Definition of FPKM:
    #   FPKM stands for Fragments Per Kilobase of transcript
    #   per Million mapped reads. In RNA-Seq, the relative
    #   expression of a transcript is proportional to the number
    #   of cDNA fragments that originate from it.
    puts fields.join("\t")
  end
end

def run(argv)
  options = setup_options(argv)
  port_out = argv[0]
  gtf_file = argv[1]

  lengths = read_gtf(gtf_file)
  $logger.debug(lengths)

  write_new(port_out, lengths)

  #setup_logger(options[:log_level])
  $logger.info("Hallo")
  $logger.debug("DEBUG")
  $logger.debug(options)
  $logger.debug(argv)


  $logger.info("All done!")
end

if __FILE__ == $0
  run(ARGV)
end