require 'yaml'
require 'sew/motor'
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

$conf = "/root/git/sew/axi.yml"
if !File.exist?($conf)
  DB=[]
  save_db
else
  DB = YAML.load(open($conf).read)
end



def fmt_all
  DB.map do |a| fmt a.motor end
  save_db
end
