require 'csv'

ensembl_id = []

CSV.open(ARGV[0], :headers => true).each do |row|
  #puts row["GeneID"]
  #exit
  #STDERR.puts row["Bonferroni"]
  if row["NumIso"].to_i == 1 && row["FDR"].to_f < 0.05
    ensembl_id << row["GeneID"]
  end
end

STDERR.puts ensembl_id.join(":::")

puts CSV.read(ARGV[1], :headers => true, :col_sep => "\t").headers().join("\t")

CSV.open(ARGV[1], :headers => true, :col_sep => "\t").each do |row|

  if ensembl_id.include?(row["GeneID"])
    out = []
    row.each {|k| out << k[1]}
    puts out.join("\t")
    #puts row.join("\t")
    #exit
  end
end