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
  }
}


Motor = Struct.new(:nameplate) do
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
    when /^F/
      gu = nil
      b  = false
      table = "F"
     
      if m =~ /^F(.*)([0-9]+)B[A-Z]+[0-9]+/
        gu = "#{$1}#{$2}B"
        table << $1 << "B"
      elsif m=~/^F([0-9]+)[A-Z]+[0-9]+/
        gu = "#{$1}"
      elsif m=~/^F([A-Z]+)([0-9]+)[A-Z]+[0-9]+/
        gu = "#{$1}#{$2}"
        table << $1
      end
      
      h[:SERIES] = "F"
      h[:UNIT]   = "F#{gu}"
      
      notes = GEAR_UNITS[:F][table.to_sym]
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
