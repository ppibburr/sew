Motor = Struct.new(:nameplate) do
  def query k, v, operators={}
    self[k.to_sym]
  end
end

Err = Struct.new(:message)
