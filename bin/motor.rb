$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'sew/motor'
require 'sew/equipment'
require 'optparse'

options={}
filters={}
session=true
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] [S.O. Number]"

  opts.on("-f", "--find VALUE", "find matching VALUE's (gear or motor)") do |v|
    options[:find] = v
  end

  opts.on("-v", "--motor-voltage VALUE", "filter by motor voltage") do |v|
    filters[:motor_voltage] = v
  end 
  
  opts.on("-b", "--brake-voltage VALUE", "filter by brake voltage") do |v|
    filters[:brake_voltage] = v
  end  

  opts.on("-s", "--shaft-diameter DIAMETER", "filter by shaft-diameter") do |v|
    filters[:shaft_diameter] = v
  end  

  opts.on("-r", "--gear-ratio RATIO", "filter by gear-ratio") do |v|
    filters[:gear_ratio] = v
  end  

  opts.on("-o", "--output-speed SPEED", "filter by output-speed") do |v|
    filters[:output_speed] = v
  end  

  opts.on("-p", "--mtg-position VALUE", "filter by mtg-position") do |v|
    filters[:mtg_position] = v
  end 
  
  opts.on("-m", "--model-type VALUE", "filter by model-type") do |v|
    filters[:model_type] = v
  end     

  opts.on("-H", "--motor-hp VALUE", "filter by motor-hp") do |v|
    filters[:motor_hp] = v
  end 

  opts.on("-z", "--no-session", "Don't prompt for selection") do |v|
    session=false
  end 

  opts.on("-h", "--help", "Show this message") do |v|
    puts opts
    exit
  end 
end.parse!

list = nil

if filters.empty? && options.empty? && !ARGV.empty?
  list = DB.find_all do |a| a.motor.nameplate['so#'].gsub(".",'') =~ /#{ARGV.join}/ end.map do |a| a.motor end.uniq
  
elsif ARGV[0] && v=options[:find]
  u = DB.find_all do |a| a.motor.nameplate['so#'].gsub(".",'') =~ /#{ARGV.join}/ end[0]
  type=nil;size=nil
  case v
  when /gear/
    u.motor.nameplate['model_type'] =~ /^([A-Z]+)([0-9]+)/
    type,size = $1,$2
      
  when /motor/
    
  end

  list = DB.find_all do |a|
    a.motor.nameplate['model_type'] =~ /^#{type}#{size}/
  end.map do |a| a.motor end.uniq
  
elsif !filters.empty?
  ma=DB.map do |a| a.motor end.uniq

  filters.each_pair do |k,t|
    ma=ma.find_all do |m| 
      va=[m.nameplate[k.to_s]]
      
      if va[-1].is_a?(String)
        va=va[-1].split("/") unless k == :model_type
      end
      
      case t
      when /^\>([0-9]+.*)/
        va.find do |v|
          v.to_f > $1.to_f
        end
      when /^\>\=([0-9]+.*)/
        va.find do |v|
          v.to_f >= $1.to_f
        end
      when /^\<([0-9]+.*)/
        va.find do |v|
          v.to_f < $1.to_f
        end
      when /^\<\=([0-9]+.*)/
        va.find do |v|
          v.to_f <= $1.to_f
        end
      when /^\=\=(.*)/
        one=$1
        if va.length > 1
          va=va.map do |v|
            v.to_s.gsub(/[a-zA-Z]/,'')
          end
        end
  
        va.find do |v|
          v.to_s == one
        end
      else
        va.find do |v|
          v.to_s =~ /#{t}/
        end
      end
    end
  end
  
  list=ma
end

if list
  list = list.map do |m|
    "#{m.nameplate['so#']} #{m.nameplate['model_type'].ljust(20)} V:#{m.nameplate['motor_voltage'].to_s.ljust(10)} HP:#{m.nameplate['motor_hp'].to_s.ljust(7)} RPM:#{m.nameplate['output_speed'].to_s.ljust(6)} POSITION:#{m.nameplate['mtg_position'].ljust(5)} Brake:#{m.nameplate['brake_voltage']} #{m.input.to_i}rpm" 
  end

  if session
    i = -1
    puts(list.map do |m| "#{(i+=1).to_s.ljust(3)} #{m}" end)
    puts "enter selection # or 'enter' to quit."
    
    if (i=STDIN.gets.strip) != ''
      i=i.to_i
      system "ruby -e \"puts('#{a=DB.find do |a| a.motor.nameplate['so#'] == list[i].split(" ")[0] end;a.motor.to_yaml}')\" | less"
      puts "Selected: #{i}, SO# #{so=a.motor.nameplate['so#']}\n View equipment utilisation? [Y/n]"
     
      if gets.strip.downcase!= 'n'
        puts cmd="ruby bin/equip.rb -s #{so}"
        system cmd
      end
    end
  else
    puts list
  end
else
end
