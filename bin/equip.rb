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
  
  opts.on("-l", "--location NAME", "list all in location") do |v|
    options[:location] = v
  end  

  opts.on("-s", "--so-number DIGITS", "list all with motors matching DIGITS (accepts partial so numbers)") do |v|
    options[:so] = v
  end  

  opts.on("-h", "--help", "Show this message") do |v|
    puts opts
    exit
  end 
end.parse!

a=nil

if so=options[:so]
  a=DB[:axi].find_all do |a| a.motor.nameplate['SO_NUMBER'].to_s.gsub(".",'') =~ /#{so.gsub(/\./,'')}/ end
  a.push(*DB[:motors].find_all do |a| (a.replacements ||=[]).find do |r| r.to_s.gsub(".",'') =~ /#{so.gsub(/\./,'')}/ end end)
  a=a.uniq
elsif !dept=options[:dept]
  a=DB[:axi].find_all do |a| a.name.downcase =~ /#{ARGV[-1].downcase}/ end
elsif loc=options[:location]
  a=DB[:axi].find_all do |a| (a.department.downcase =~ /#{dept.downcase}/) && (a.location.downcase =~ /#{loc.strip.downcase}/) end
else
  a=DB[:axi].find_all do |a| (a.department.downcase =~ /#{dept}/) end
end

if a
  a=a.map do |a| "#{a.motor.nameplate['SO_NUMBER']} #{a.department.ljust(15)} #{a.location.ljust(15)} #{a.name}" end
  puts a.to_yaml
end
