$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'sew/motor'
require 'sew/equipment'
require 'optparse'

axi = []
list=nil
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] [S.O. Number]"

  opts.on("-a", "--axis NAME", "Specify axis name") do |v|
    axi << v
  end
  
  opts.on("-l", "--list PATH", "Specify CSV input list") do |v|
    list = v
  end  

  opts.on("-h", "--help", "Show this message") do |v|
    puts opts
    exit
  end 
end.parse!

tasks=[[ARGV.join,axi]]
if list
  tasks = []
  open(list).read.strip.split("\n").each do |l|
    a=l.split(",")
    tasks << [a.shift, a]
  end
end
  
tasks.each do |so,axi|  
  sleep 0.3
  mtr=YAML.load(`ruby ./bin/so.rb #{so}`.strip)
  if mtr.is_a?(Err)
    puts mtr.to_yaml
    raise "No SO# found" 
  end
  axi.map do |q|
    if a=DB.find do |e| e.name == q end
  
    else
      DB << a=Axis.new(q)
    end
    a
  end.each do |a|
    a.motor = mtr
  end

  save_db

  puts mtr.to_yaml
end
