$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'sew/motor'
require 'sew/equipment'
require 'optparse'

options={}
filters={}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] [S.O. Number]"

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

  opts.on("-h", "--help", "Show this message") do |v|
    puts opts
    exit
  end 
end.parse!

if filters.empty? && options.empty? && !ARGV.empty?
  puts(DB.find_all do |a| a.motor.nameplate['so#'].gsub(".",'') =~ /#{ARGV.join}/ end.to_yaml)
elsif !filters.empty?
  ma=DB.map do |a| a.motor end

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
  
  puts(ma.uniq.map do |m| "#{m.nameplate['so#']} #{m.nameplate['model_type']} V:#{m.nameplate['motor_voltage']} HP:#{m.nameplate['motor_hp']} RPM:#{m.nameplate['output_speed']} POSITION:#{m.nameplate['mtg_position']}" end.to_yaml)
end
