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

$conf = "#{ENV['HOME']}/git/sew/axi.yml"



def load_db
  Object.class_eval do
    const_set :DB,YAML.load(open($conf).read)
  end
end


if !File.exist?($conf)
  DB=[]
  save_db
else
  load_db
end




def fmt_all
  DB.map do |a| fmt a.motor end
  save_db
end
