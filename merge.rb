require "csv"
file1 = ARGV[0]
file2 = ARGV[1]
file3 = ARGV[2]


header = %w{ensembl symbol fold_change mean_g1 mean_g2 cov_g1 cov_g2}
counts_1 = {}

#File.open(file1).each do |line|
CSV.foreach(file1,:col_sep => "\t",:headers => true) do |ps|
  counts_1[ps["ensembl"]] = [ps["fold_change"].to_f,ps["mean_g1"].to_f,ps["mean_g2"].to_f,
    ps["cov_g1"].to_f,ps["cov_g2"].to_f]
end

counts_2 = {}

#File.open(file2).each do |line|
CSV.foreach(file2,:col_sep => "\t",:headers => true) do |ps|
  #next unless line =~ /ENS/
  #line.chomp!
  #fields = line.split("\t")
  #counts_2[fields[header.index("ensembl")]] = fields[header.index("fold_change")].to_f
  counts_2[ps["ensembl"]] = [ps["fold_change"].to_f,ps["mean_g1"].to_f,ps["mean_g2"].to_f,
    ps["cov_g1"].to_f,ps["cov_g2"].to_f]
end

#puts counts_2
#exit

puts "ensembl\tsymbol\tfold_change_average\tcoe_of_var_aver\tfold_change_cele\tfold_change_vehicle\tfold_change_rofe\tcoe_of_var_g1_cele\tcoe_of_var_g2_cele\tcoe_of_var_g1_vehicle\tcoe_of_var_g2_vehicle\tcoe_of_var_g1_rofe\tcoe_of_var_g2_rofe"
CSV.foreach(file3,:col_sep => "\t",:headers => true) do |ps|
#File.open(file3).each do |line|
  if counts_1[ps["ensembl"]] && counts_2[ps["ensembl"]]
    average = (ps["fold_change"].to_f+ counts_1[ps["ensembl"]][0] +
      counts_2[ps["ensembl"]][0]) / 3.0
    average_cov = (ps["cov_g1"].to_f+ ps["cov_g2"].to_f+counts_1[ps["ensembl"]][3] +
      counts_1[ps["ensembl"]][4] +counts_2[ps["ensembl"]][3] +counts_2[ps["ensembl"]][4] ) / 6.0
    l = "#{ps["ensembl"]}\t#{ps["symbol"]}\t#{average}\t#{average_cov}\t#{counts_1[ps["ensembl"]][0]}\t#{counts_2[ps["ensembl"]][0]}\t#{ps["fold_change"].to_f}"
    l += "\t#{counts_1[ps["ensembl"]][3]}\t#{counts_1[ps["ensembl"]][4]}\t#{counts_2[ps["ensembl"]][3]}\t#{counts_2[ps["ensembl"]][4]}"
    l += "\t#{ps["cov_g1"]}\t#{ps["cov_g2"]}"
    puts l
  end
end