$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'sew/motor'
require 'sew/equipment'
require 'optparse'

axi = []
list=nil
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] [S.O. Number]"

  opts.on("-d", "--department NAME", "Specify department name") do |v|
    axi[0]=v
  end

  opts.on("-l", "--department NAME", "Specify location name") do |v|
    axi[1]=v
  end

  opts.on("-a", "--axis NAME", "Specify axis name") do |v|
    axi[2]=v
  end
  
  opts.on("-L", "--list PATH", "Specify CSV input list") do |v|
    list = v
  end  

  opts.on("-h", "--help", "Show this message") do |v|
    puts opts
    exit
  end 
end.parse!

tasks=[[ARGV.join,axi]]
if list
  last = nil
  tasks = []
  open(list).read.strip.split("\n").each do |l|
    a=l.split(",").map do |q| q.gsub('"','') end
    a[0] = last if a[0] == ''
    tasks << [last=a.shift, a]
  end
end
  
mtr  = nil
last = nil
tasks.each do |so,axi|    
  dept,loc,axi = axi
  
  unless so == last
    if !a=DB[:motors].find do |q| q.nameplate['SO_NUMBER'].gsub(".",'') =~ /^#{so.gsub(".",'')}/ end
      mtr=YAML.load(`ruby #{ENV['HOME']}/git/sew/bin/so.rb #{so}`.strip)
      DB[:motors] << mtr
    else 
      mtr = a
    end
  end
  
  last = so
  
  if mtr.is_a?(Err)
    puts mtr.to_yaml
    raise "No SO# found" 
  elsif !mtr
    raise "NilMotorError"
  end
  
  
  if a=DB[:axi].find do |e| e.name.strip.downcase == axi.strip.downcase end
  
  else
    _ = axi.strip.split(" ")
    _[0] = _[0].upcase
    axi = _.join(" ")
    DB[:axi] << a=Axis.new(axi,dept.upcase,loc.upcase, mtr)
    
  end

  save_db

  puts mtr.to_yaml
end
