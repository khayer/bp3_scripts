#!/usr/bin/env ruby
require 'optparse'
require 'logger'
require 'parallel'


$logger = Logger.new(STDERR)
$genes = []
$bin_length = 300000
$exclude = ""

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
  options = {:single_end=>false, :out_file=>"counts_filtered.txt", :exclude=>nil}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] seq_list.txt exclude_list.txt"
    opts.separator ""
    opts.on("-o", "--out_file [OUT_FILE]",
      :REQUIRED,String,
      "File for the output, Default: counts_filtered.txt") do |a|
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

def read_file(in_file,out_file)
  counts = []

  process_queue = []


  width     = 50
  processed = 0
  printed   = 0
  total     = `wc -l #{in_file}`.to_i
  puts "TOTAL #{total}"

  sam_handle = File.open(in_file.gsub(/"/,""))
  sam_handle.each do |line|
    line.chomp!

    processed += 1
    wanted = (100.0/total.to_f * processed.to_f).to_i
    print "\r"
    print "-" * (wanted/2)
    print " " * (50 - wanted/2) + "| #{wanted}%"
        #printed = wanted
    process_queue << line
    next unless (process_queue.size == 50 || sam_handle.eof?)
    results = Parallel.map(process_queue,:in_processes=>4) do |e|
      #puts "grep -w #{e} #{$exclude}"
      $exclude.include?(e)
    end
    results.each_with_index do |k,i|
      out_file.puts process_queue[i] unless k
    end
    process_queue = []
  end
end

def read_exclude_list(exclude_file)
  exclude = []
  File.open(exclude_file).each do |line|
    line.chomp!
    exclude << line unless exclude.include?(line)
  end
  exclude
end

def run(argv)
  options = setup_options(argv)
  setup_logger(options[:log_level])
  $logger.debug(options)
  $logger.debug(argv)
  #$exclude = read_exclude_list(argv[1])
  ##$logger.debug("Excluding: " + $exclude.join(":"))
  #out_file = File.open(options[:out_file],'w')
  #counts = read_file(argv[0],out_file)
  tmp1 = "#{argv[0]}_tmp1"
  tmp2 = "#{argv[0]}_tmp2"
  `grep -v "SUM:" #{argv[0]} | sort > #{tmp1}`
  `sort #{argv[1]} > #{tmp2}`
  `diff #{tmp1} #{tmp2} | grep "<" | awk '{print $2}' |  sort -t$'.' -k2n > #{options[:out_file]}`
  counts = `wc -l #{options[:out_file]}`.to_i
  file = File.open(options[:out_file], 'a') {|file| file.puts "SUM: #{counts}"}
  File.delete(tmp1)
  File.delete(tmp2)
  #out_file.puts "SUM: #{counts}"
  puts "SUM: #{counts}"
end

if __FILE__ == $0
  run(ARGV)
end

