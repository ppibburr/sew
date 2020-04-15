$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'sew/motor'
require 'sew/equipment'
require 'optparse'

options={}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] [ID]"

  opts.on("-d", "--department NAME", "set department") do |v|
    options[:dept] = v
  end
  
  opts.on("-l", "--location", "list all in location") do |v|
    options[:location] = v
  end  

  opts.on("-h", "--help", "Show this message") do |v|
    puts opts
    exit
  end 
end.parse!

if !options[:dept]
  puts(DB.find_all do |a| a.name.downcase =~ /#{ARGV[-1].downcase}/ end.to_yaml)
end
