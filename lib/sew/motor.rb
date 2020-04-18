Motor = Struct.new(:nameplate) do
  def query k, v, operators={}
    self[k.to_sym]
  end
  
  def input
    out = nameplate['output_speed']
    r   = nameplate['gear_ratio']
    r*out.to_f
  end
end

Err = Struct.new(:message)
