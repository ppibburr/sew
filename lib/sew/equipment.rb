require 'yaml'

Axis = Struct.new(:name,:department, :location, :motor, :manual,:mark)

Equipment = Struct.new(:department, :location, :id, :axi) do
  def self.new *o
    ins=super *o
    ins.axi=[]
  end
end


def save_db
  File.open($conf,'w') do |f| f.puts DB.to_yaml end
end

$conf = "./axi.yml"
if !File.exist?($conf)
  DB=[]
  save_db
else
  DB = YAML.load(open($conf).read)
end

