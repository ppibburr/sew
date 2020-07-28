$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'sew/motor'
require 'sew/equipment'

units = DB[:motors].map do |a|
 a
end.uniq.sort do |a,b| a.nameplate['SO_NUMBER'] <=> b.nameplate['SO_NUMBER'] end

class CSV
  attr_reader :fields
  def initialize
    @fields = [:so,:model,:volts,:amps,:hz,:ratio,:speed,:position,:sf,:torque,:shaft]
  end
  
  def row m
    fields.map do |f| f.to_s.upcase end.join(",")+"\n"+
    fields.map do |f|
      send f, m
    end.join(",")+"\n"+
    +gear(m)+"\n"+
    locations(m)
  end
  
  def locations m
    "Locations,#{[:DEPT,:LOCATION,:NAME].join(',')}\n"+
    DB[:axi].find_all do |a|
      a.motor.nameplate['SO_NUMBER'] == m.nameplate['SO_NUMBER']
    end.map do |a|
      ","+[a.department,a.location,a.name].join(",")
    end.join("\n")
  end
  
  def brake m
    ((m.nameplate['BRAKE_RECTIFIER']||"")+" "+(float(m.nameplate['BRAKE_VOLTAGE']))).strip
  end
  
  def volts m
    float m.nameplate['MOTOR_VOLTAGE']
  end
  
  def amps m
    float m.nameplate['MOTOR_AMPS']
  end
  
  def model m
    m.nameplate['MODEL_TYPE']
  end
  
  def so m
    m.nameplate['SO_NUMBER']
  end
  
  def shaft m
    float m.nameplate['SHAFT_DIAMETER']
  end
  
  def torque m
    float m.nameplate['OUT_TORQUE']
  end
  
  def ratio m
    float m.nameplate['GEAR_RATIO']
  end
  
  def sf m
    float m.nameplate['GEAR_SF']
  end
  
  def position m
    m.nameplate['MTG_POSITION']
  end
  
  def speed m
    float m.nameplate['OUTPUT_SPEED']
  end
  
  def hz m
    float m.nameplate['FREQUENCY']
  end
  
  def gear m
    h = m.gear_unit
    a=["GEAR_UNIT"].push(*[:UNIT,:SERIES,:SIZE])
    a.delete(:NOTES)
    a<< :NOTES
    o=[""]
    for i in 1..(a.length-1)
      o << h[a[i]]
    end
    
    a.join(",")+"\n"+
    o.join(",")
  end
end

def float q
  q=q.to_s.strip
  if q =~ /^([0-9]+\.[0-9]+)$/
    q = ("%.2f" % $1.to_f)
  end
  q
end

csv=CSV.new
doc = units.map do |u|
  csv.row u
end

puts doc.join("\n\n")
