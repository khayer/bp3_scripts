require "csv"
spliceforms = ARGV[0]
list_of_diff_genes = ARGV[1]
refseq_to_symbol = ARGV[2]
counts = ARGV[3] # data.txt

def sample_variance(num_array)
  m = mean(num_array)
  sum = num_array.inject(0){|accum, i| accum + (i - m) ** 2 }
  return sum / (num_array.length - 1).to_f
end

def sd(num_array)
  return Math.sqrt(sample_variance(num_array))
end

def mean(num_array)
  num_array.instance_eval { reduce(:+) / size.to_f }
end

def coefficient_of_variation(num_array)
  c = sd(num_array)/mean(num_array)
end

cov = {}
CSV.foreach(counts,:col_sep => "\t") do |ps|
  next unless ps[0] =~ /^gene/
  num_array = ps[1..4].map { |e|  e.to_f + 1.0 }
  mean_g1 = mean(num_array)
  sd_g1 = sd(num_array)
  cov_g1 = coefficient_of_variation(num_array)
  #cov_g1 = 0 if cov_g1.nan?
  num_array = ps[5..8].map { |e|  e.to_f + 1.0 }
  mean_g2 = mean(num_array)
  sd_g2 = sd(num_array)
  cov_g2 = coefficient_of_variation(num_array)
  #cov_g2 = 0 if cov_g2.nan?
  cov[ps[0].split(":")[1]] = [cov_g1,mean_g1,sd_g1,cov_g2,mean_g2,sd_g2]
end

puts cov
exit

names = {}
File.open(refseq_to_symbol).each { |line| names[line.chomp.split("\t")[1]] = line.chomp.split("\t")[0] }


spliceforms_num = {}
File.open(spliceforms).each { |line| spliceforms_num[line.chomp.split("\t")[2]] = line.chomp.split("\t")[3] }
#puts spliceforms_num

cutoff = 0.01
header = %w{feature_type feature_id  chromosome  start end mean_celecoxib_il1b mean_control_il1b q-value fold  symbol  description ucsc_id}

genes = []
out = []

puts "ensembl\tsymbol\tfold_change\tmean_g1\tmean_g2\tcov_g1\tcov_g2"
File.open(list_of_diff_genes).each do |line|
  line.chomp!
  line = line.split("\t")
  next unless line[header.index("feature_type")] == "gene"
  next unless line[header.index("q-value")].to_f < cutoff
  # IS IT ONLY ONE SPLICEFORM?
  #STDERR.puts line[header.index("symbol")]
  if spliceforms_num[names[line[header.index("symbol")]]]  == "1"

    puts "#{line[header.index("feature_id")]}\t#{line[header.index("symbol")]}\t#{line[header.index("fold")]}\t#{line[5]}\t#{line[6]}\t#{cov[line[header.index("feature_id")]][0]}\t#{cov[line[header.index("feature_id")]][1]}" unless genes.include?(line[header.index("feature_id")])
    genes << line[header.index("feature_id")] unless genes.include?(line[header.index("feature_id")])
  end
end
