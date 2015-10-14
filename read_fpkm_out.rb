###
#
# IN:
# [hayer@node061 fpkm]$ find . -name "Sam*"
# ./Sample_4721.txt
# ./Sample_4126.txt
# ./Sample_4128.txt
# ./Sample_4129.txt
# ./Sample_4130.txt
# OUT: Summary
#
###
all = []
names = ["GeneID"]
num_splice = ["NumIso"]
count = 0
borders = []
first = true
ARGV[0..-1].each do |arg|
  info = []
  arg =~ /_(\d*)./
  info << "S#{$1}"
  File.open(arg).each do |line|
    line.chomp!
    fields = line.split("\t")
    info << fields[1]
    names << fields[0] if first
    num_splice << fields[-1] if first
  end
  first = false
  all << info.flatten
end

names.flatten!
num_splice.flatten!
#info.flatten!

#puts "aligner\ttotal_number_of_bases_of_reads\taccuracy over all bases\taccuracy over uniquely aligned bases"

names.each_with_index do |name, j|
  print "#{name}\t"
  print "#{num_splice[j]}\t"
  res = []
  for i in 0...ARGV.length
    res << all[i][j]
  end
  print res.join("\t")
  print "\n"
end
