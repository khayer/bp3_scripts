spliceforms = ARGV[0]
list_of_diff_genes = ARGV[1]
refseq_to_symbol = ARGV[2]

names = {}
File.open(refseq_to_symbol).each { |line| names[line.chomp.split("\t")[1]] = line.chomp.split("\t")[0] }


spliceforms_num = {}
File.open(spliceforms).each { |line| spliceforms_num[line.chomp.split("\t")[2]] = line.chomp.split("\t")[3] }
#puts spliceforms_num

cutoff = 0.01
header = %w{feature_type feature_id  chromosome  start end mean_celecoxib_il1b mean_control_il1b q-value fold  symbol  description ucsc_id}

genes = []
out = []

File.open(list_of_diff_genes).each do |line|
  line.chomp!
  line = line.split("\t")
  next unless line[header.index("feature_type")] == "gene"
  next unless line[header.index("q-value")].to_f < cutoff
  # IS IT ONLY ONE SPLICEFORM?
  #STDERR.puts line[header.index("symbol")]
  if spliceforms_num[names[line[header.index("symbol")]]]  == "1"

    puts "#{line[header.index("symbol")]}\t#{line[header.index("fold")]}\t#{line[5]}\t#{line[6]}" unless genes.include?(line[header.index("symbol")])
    genes << line[header.index("symbol")] unless genes.include?(line[header.index("symbol")])
  end
end
