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

  opts.on("-R", "--replace SO_NUMBER", "replace SO_NUMBER with value") do |v|
    options[:replace] = v
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

  opts.on("-F", "--correct-format", "Fix nameplate field formatting") do |v|
    fmt_all
  end 


  opts.on("-G", "--gear-unit", "view gear unit info for SO#") do |v|
    options[:view_gear] = true
  end 

  opts.on("-h", "--help", "Show this message") do |v|
    puts opts
    exit
  end 
end.parse!

list = nil

if old=options[:replace]
  p old: old, new: ARGV.last
  mtr = DB[:motors].find_all do |a| a.nameplate['SO_NUMBER'].gsub(".",'') =~ /#{old.gsub(".",'')}/ end.uniq
 
  if !mtr.last
    puts "Unit #{old}, not in DataBase."
    puts "Add? (Y/n)"
    if STDIN.gets.chomp.downcase == "y"
      mtr << nm = YAML.load(`ruby bin/so.rb #{old}`.strip)
      DB[:motors] << nm
      save_db
    else
      puts "Bye!"
      exit
    end
    mtr.last.replace ARGV.last
  end

  save_db
  p mtr.last.replacements
  exit
end

if filters.empty? && options.empty? && !ARGV.empty?
  list = DB[:motors].find_all do |a| a.nameplate['SO_NUMBER'].gsub(".",'') =~ /#{ARGV.join}/ end.uniq
  
elsif ARGV[0] && v=options[:find]
  u = DB[:motors].find_all do |a| a.nameplate['SO_NUMBER'].gsub(".",'') =~ /#{ARGV.join}/ end[0]
  type=nil;size=nil
  case v
  when /gear/
    u.nameplate['MODEL_TYPE'] =~ /^([A-Z]+)([0-9]+)/
    type,size = $1,$2
      
  when /motor/
    u.nameplate['MODEL_TYPE'] =~ /^[A-Z]+[0-9]+.*([A-Z][A-Z])([0-9]+)/
    type,size = $1,$2    
  end

  q=u.nameplate['MOTOR_HP']
  list = DB[:motors].find_all do |a|
    a.nameplate['MODEL_TYPE'] =~ /#{type}([A-Z]|.*)#{size}/
  end.uniq.sort do |a,b| 
    a.nameplate['MOTOR_HP'] <=> b.nameplate['MOTOR_HP'] 
  end.sort do |a,b| 
    ((a.nameplate['MOTOR_HP'] == q) ? 1 : 0) <=> ((b.nameplate['MOTOR_HP'] == q) ? 1 : 0)
  end
  
elsif !filters.empty?
  ma=DB[:motors].map do |a| a end.uniq

  filters.each_pair do |k,t|
    ma=ma.find_all do |m| 
      va=[m.nameplate[k.to_s.upcase]]
      
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
elsif options[:view_gear]
  list = DB[:motors].find_all do |a| a.nameplate['SO_NUMBER'].gsub(".",'') =~ /#{ARGV.join}/ end.uniq  
  STDERR.puts "SO#: #{ARGV.join}"
  puts list[-1].gear_unit.to_yaml
  exit
end

if list
  list = list.map do |m|
    "#{m.nameplate['SO_NUMBER']} #{m.nameplate['MODEL_TYPE'].ljust(20)} V:#{m.nameplate['MOTOR_VOLTAGE'].to_s.ljust(10)} HP:#{m.nameplate['MOTOR_HP'].to_s.ljust(7)} RPM:#{m.nameplate['OUTPUT_SPEED'].to_s.ljust(6)} POSITION:#{m.nameplate['MTG_POSITION'].ljust(5)} Brake:#{m.nameplate['BRAKE_VOLTAGE']} #{m.input.to_i}rpm" 
  end

  if session
    i = -1
    puts(list.map do |m| "#{(i+=1).to_s.ljust(3)} #{m}" end)
    puts "enter selection # or 'enter' to quit."
    
    if (i=STDIN.gets.strip) != ''
      i=i.to_i
      system "ruby -e \"puts('#{m=DB[:motors].find do |a| a.nameplate['SO_NUMBER'] == list[i].split(" ")[0] end;m.to_yaml}')\" | less"
      puts "Selected: #{i}, SO# #{so=m.nameplate['SO_NUMBER']}\n View equipment utilisation? [Y/n]"
     
      if STDIN.gets.strip.downcase != 'n'
        puts cmd="ruby bin/equip.rb -s #{so}"
        system cmd
      end
    end
  else
    puts list
  end
else
end
