a  = open('./replace.txt').read.split("\n").map do |q| q.split(",") end

a.each do |o,n|
  system "ruby bin/motor.rb -R #{o} #{n}"
end 


