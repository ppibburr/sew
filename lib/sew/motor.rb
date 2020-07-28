GEAR_UNITS = {
  F: {
	F:   "Foot-mounted",
	FAB: "Foot-mounted / Hollow shaft",
	FVB: "Foot-mounted / Hollow shaft / Splined hollow shaft",
	FHB: "Foot-mounted / Hollow shaft / Shrink disc",
	FF:  "B5 flange-mounted",
	FAF: "B5 Flange-mounted / Hollow shaft",
	FVF: "B5 Flange-mounted / Hollow shaft / Splined hollow shaft",
	FHF: "B5 Flange-mounted / Hollow shaft / Shrink disc",
	FA:  "Hollow shaft",
	FV:  "Hollow shaft / Splined hollow shaft",
	FH:  "Hollow shaft / Shrink disc",
	FT:  "Hollow shaft / TorqLOC",
	FAZ: "B14 Flange-mounted / Hollow shaft",
	FVZ: "B14 Flange-mounted / Hollow shaft / Splined hollow shaft",
	FHZ: "B14 Flange-mounted / Hollow shaft / Shrink disc"
  },

  K: {
	K:   "Foot-mounted",
	KAB: "Foot-mounted / Hollow shaft",
	KVB: "Foot-mounted / Hollow shaft / Splined hollow shaft",
	KHB: "Foot-mounted / Hollow shaft / Shrink disc",
	KF:  "B5 flange-mounted",
	KAF: "B5 Flange-mounted / Hollow shaft",
	KVF: "B5 Flange-mounted / Hollow shaft / Splined hollow shaft",
	KHF: "B5 Flange-mounted / Hollow shaft / Shrink disc",
	KA:  "Hollow shaft",
	KV:  "Hollow shaft / Splined hollow shaft",
	KH:  "Hollow shaft / Shrink disc",
	KT:  "Hollow shaft / TorqLOC",
	KAZ: "B14 Flange-mounted / Hollow shaft",
	KVZ: "B14 Flange-mounted / Hollow shaft / Splined hollow shaft",
	KHZ: "B14 Flange-mounted / Hollow shaft / Shrink disc"
  }
}


Motor = Struct.new(:nameplate, :replacements) do
  def self.new *o
    ins=super
    ins.replacements = []
    ins
  end
  
  def replace so
    out = `ruby ./bin/so.rb #{so}`.strip
    nm = YAML.load(out)
    (nm.replacements ||= []) << nameplate['SO_NUMBER']
    nm
  end

  def query k, v, operators={}
    self[k.to_sym]
  end
  
  def input
    out = nameplate['OUTPUT_SPEED']
    r   = nameplate['GEAR_RATIO']
    r*out.to_f
  end
  
  def gear_unit
    h={}
    m = nameplate['MODEL_TYPE']
    h[:MTG_POSITION] = nameplate['MTG_POSITION']
    h[:GEAR_RATIO]   = nameplate['GEAR_RATIO']
    case m
    when /^([A-Z])/
      return h unless GEAR_UNITS[series = $1.to_sym]
      gu = nil
      b  = false
      table = $1
     
      if m =~ /^#{series}([A-Z]+)([0-9]+)B[A-Z]+[0-9]+/
        gu = "#{$1}#{$2}B"
        table << $1 << "B"
      elsif m=~/^#{series}([0-9]+)[A-Z]+[0-9]+/
        gu = "#{$1}"
      elsif m=~/^#{series}([A-Z]+)([0-9]+)[A-Z]+[0-9]+/
        gu = "#{$1}#{$2}"
        table << $1
      end
      
      h[:SERIES] = series
      h[:UNIT]   = "#{series}#{gu}"
      table.to_sym
      notes = GEAR_UNITS[series][table.to_sym]
      h[:NOTES] = notes
      
      gu=~/([0-9]+)/
      h[:SIZE]  = $1.to_i
    end
    
    h
  end
end

Err = Struct.new(:message)

def fmt m
  h = m.nameplate
  r = {}
  if t = h[k='out_torque_(lb-in)']
    r['OUT_TORQUE']   = t
    r['TORQUE_UNITS'] = 'lb-in'
    #h.delete k
  end
  
  h.delete 'out_torque_(lb-in)'
  
  h.each_pair do |k,v|
    if k=~ /^[a-z]+/
      n = k.upcase
      n = 'SO_NUMBER' if k =~ /^so\#/
      r[n] = v
      #h.delete k
    else
      r[k]=v
    end
  end
  
  r['GEAR_SF'] ||= (h['gear_s.f.'] || h['GEAR_S.F.'])
  r.delete 'gear_s.f.'
  r.delete 'GEAR_S.F.'
  
  nr = {}
  r.keys.sort.each do |k|
    nr[k] = r[k]
  end
  
  nr['XTRA_NOTES'] ||= nr['OTHER']
  nr.delete 'OTHER'
  
  m.nameplate = nr
  
  m
end
