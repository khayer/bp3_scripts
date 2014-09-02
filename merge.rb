file1 = ARGV[0]
file2 = ARGV[1]
file3 = ARGV[2]

counts_1 = {}

File.open(file1).each do |line|
  line.chomp!
  fields = line.split("\t")
  counts_1[fields[0]] = fields[1].to_f
end

counts_2 = {}

File.open(file2).each do |line|
  line.chomp!
  fields = line.split("\t")
  counts_2[fields[0]] = fields[1].to_f
end

File.open(file3).each do |line|
  line.chomp!
  fields = line.split("\t")
  if counts_1[fields[0]] && counts_2[fields[0]]
    average = (fields[1].to_f+ counts_1[fields[0]] + counts_2[fields[0]]) / 3.0
    puts "#{fields[0]}\t#{average}"
  end
end