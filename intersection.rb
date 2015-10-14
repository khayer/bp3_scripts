require 'csv'

ensembl_id = []

CSV.open(ARGV[0], :headers => true).each do |row|
  #puts row["GeneID"]
  #exit
  #STDERR.puts row["Bonferroni"]
  if row["NumIso"].to_i == 1 && row["Bonferroni"].to_f < 0.05
    ensembl_id << row["GeneID"]
  end
end

ensembl_id2 = []

CSV.open(ARGV[1], :headers => true).each do |row|
  #puts row["GeneID"]
  #exit
  #STDERR.puts row["Bonferroni"]
  if row["NumIso"].to_i == 1 && row["Bonferroni"].to_f < 0.05
    ensembl_id2 << row["GeneID"]
  end
end

k = ensembl_id & ensembl_id2
puts k.length