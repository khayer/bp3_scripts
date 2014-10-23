require "csv"
file1 = ARGV[0]
file2 = ARGV[1]
file3 = ARGV[2]

def mean(num_array)
  num_array.instance_eval { reduce(:+) / size.to_f }
end

header = %w{ensembl symbol fold_change mean_g1 mean_g2 cov_g1 cov_g2}
counts_1 = {}

#File.open(file1).each do |line|
CSV.foreach(file1,:col_sep => "\t",:headers => true) do |ps|
  #counts_1[ps["ensembl"]] = [ps["fold_change"].to_f,ps["mean_g1"].to_f,ps["mean_g2"].to_f,
  #  ps["cov_g1"].to_f,ps["cov_g2"].to_f]
  counts_1[ps["ensembl"]] = {"fold_change" => ps["fold_change"].to_f, "mean_g1" => ps["mean_g1"].to_f,
    "mean_g2" => ps["mean_g2"].to_f, "cov_g1" => ps["cov_g1"].to_f,
    "cov_g2" => ps["cov_g2"].to_f, "sd_g1" => ps["sd_g1"].to_f,
    "sd_g2" => ps["sd_g2"].to_f,"P" => ps["P"].to_f,"Q" => ps["Q"].to_f}
end

#puts counts_1
#puts counts_1["ENSMUSG00000039354"]["fold_change"]


counts_2 = {}

#File.open(file2).each do |line|
CSV.foreach(file2,:col_sep => "\t",:headers => true) do |ps|
  #next unless line =~ /ENS/
  #line.chomp!
  #fields = line.split("\t")
  #counts_2[fields[header.index("ensembl")]] = fields[header.index("fold_change")].to_f
  counts_2[ps["ensembl"]] = {"fold_change" => ps["fold_change"].to_f, "mean_g1" => ps["mean_g1"].to_f,
    "mean_g2" => ps["mean_g2"].to_f, "cov_g1" => ps["cov_g1"].to_f,
    "cov_g2" => ps["cov_g2"].to_f, "sd_g1" => ps["sd_g1"].to_f,
    "sd_g2" => ps["sd_g2"].to_f,"P" => ps["P"].to_f,"Q" => ps["Q"].to_f}
end

#puts counts_2["ENSMUSG00000039354"]["mean_g1"]
#puts counts_2

l = "ensembl\tsymbol\tfold_change_average\tcoe_of_var_aver\tfold_change_cele\tfold_change_vehicle\tfold_change_rofe\tcoe_of_var_g1_cele\tcoe_of_var_g2_cele\tcoe_of_var_g1_vehicle\tcoe_of_var_g2_vehicle\tcoe_of_var_g1_rofe\tcoe_of_var_g2_rofe"
l += "\taverage_mean\taverage_sd\tlog_average_mean\tlog_average_sd\taverage_P\taverage_Q"
puts l
CSV.foreach(file3,:col_sep => "\t",:headers => true) do |ps|
#File.open(file3).each do |line|
  if counts_1[ps["ensembl"]] && counts_2[ps["ensembl"]]
    average = (ps["fold_change"].to_f+ counts_1[ps["ensembl"]]["fold_change"] +
      counts_2[ps["ensembl"]]["fold_change"]) / 3.0
    average_cov = (ps["cov_g1"].to_f + ps["cov_g2"].to_f+counts_1[ps["ensembl"]]["cov_g1"] +
      counts_1[ps["ensembl"]]["cov_g2"] + counts_2[ps["ensembl"]]["cov_g1"] + counts_2[ps["ensembl"]]["cov_g2"] ) / 6.0
    average_mean = mean([ps["mean_g1"].to_f, ps["mean_g2"].to_f,counts_1[ps["ensembl"]]["mean_g1"],
      counts_1[ps["ensembl"]]["mean_g2"],counts_2[ps["ensembl"]]["mean_g1"],counts_2[ps["ensembl"]]["mean_g2"]])
    average_sd = mean([ps["sd_g1"].to_f, ps["sd_g2"].to_f,counts_1[ps["ensembl"]]["sd_g1"],
      counts_1[ps["ensembl"]]["sd_g2"],counts_2[ps["ensembl"]]["sd_g1"],counts_2[ps["ensembl"]]["sd_g2"]])
    average_p = mean([ps["P"].to_f, counts_1[ps["ensembl"]]["P"], counts_2[ps["ensembl"]]["P"]])
    average_q = mean([ps["Q"].to_f, counts_1[ps["ensembl"]]["Q"], counts_2[ps["ensembl"]]["Q"]])
    l = "#{ps["ensembl"]}\t#{ps["symbol"]}\t#{average}\t#{average_cov}\t#{counts_1[ps["ensembl"]]["fold_change"]}\t#{counts_2[ps["ensembl"]]["fold_change"]}\t#{ps["fold_change"].to_f}"
    l += "\t#{counts_1[ps["ensembl"]]["cov_g1"]}\t#{counts_1[ps["ensembl"]]["cov_g2"]}\t#{counts_2[ps["ensembl"]]["cov_g1"]}\t#{counts_2[ps["ensembl"]]["cov_g2"]}"
    l += "\t#{ps["cov_g1"]}\t#{ps["cov_g2"]}\t#{average_mean}\t#{average_sd}\t#{Math.log10(average_mean)}\t#{Math.log10(average_sd)}"
    l += "\t#{average_p}\t#{average_q}"
    puts l
  end
end