spliceforms = ARGV[0]
list_of_diff_genes = ARGV[1]
refseq_to_symbol = ARGV[2]
counts_table = ARGV[3]

names = {}
File.open(refseq_to_symbol).each { |line| names[line.chomp.split("\t")[1]] = line.chomp.split("\t")[0] }

spliceforms_num = {}
File.open(spliceforms).each { |line| spliceforms_num[line.chomp.split("\t")[0]] = line.chomp.split("\t")[1] }

cutoff = 0.01
header = %w{feature_type feature_id  chromosome  start end mean_celecoxib_il1b mean_control_il1b q-value fold  symbol  description ucsc_id}

genes = []

File.open(list_of_diff_genes).each do |line|
  line.chomp!
  line = line.split("\t")
  next unless line[header.index("feature_type")] == "exon"
  next unless line[header.index("q-value")].to_f < cutoff
  # IS IT ONLY ONE SPLICEFORM?
  #STDERR.puts line[header.index("symbol")]
  if spliceforms_num[names[line[header.index("symbol")]]]  == "1"
    genes << line[header.index("symbol")] unless genes.include?(line[header.index("symbol")])
  end
end


STDERR.puts genes.length
#STDERR.puts genes

counts = {}
File.open(counts_table).each do |line|
  line.chomp!
  line = line.split("\t")
  #puts line.length
  #puts line[-3]
  if line[-2] =~ /,/
    all_names = line[-2].split(",")
  else
    all_names = [line[-2]]
  end
  yes = false
  gene_name = ""
  all_names.each do |name|
    yes = genes.include?(name)
    gene_name = name
    break if yes
  end
  if yes #genes.include?(line[-2])
    il1b = line[17..24].inject(0) {|sum, i|  sum + i.to_i }
    no_il1b = line[41..48].inject(0) {|sum, i|  sum + i.to_i }

    counts[gene_name] ||= [0,0]
    counts[gene_name] = [counts[gene_name][0]+il1b,counts[gene_name][1]+no_il1b]
  end
end

counts.each_pair do |key, value|
  fold_change = (value[0].to_f + 1) / (value[1].to_f + 1)
  puts "#{key}\t#{fold_change}\t#{value.join("\t")}"
end
