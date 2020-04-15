require 'nokogiri'

def key
  if File.exist?(f="./key.key")
    $key ||= open(f).read.strip
  else
    $key = "(S(uyji3bzbigoo3y0kr11qfwb4))"
  end
end

def get sn=ARGV.join
  sn=sn.gsub(".",'')
  so = []
  so << sn[0..2]
  so << sn[3..8]
  so << (sn[9..10] || '04')
  so[-1] = "04" if so[-1] == ''
  so << (sn[11..12] || '04')
  so[-1] = "04" if so[-1] == ''  
  so << (sn[13..15] || '001')
  so[-1] = "001" if so[-1] == ''  
  
  STDERR.puts so: so
  
  cmd = "curl 'http://v5.ptpilot.com/SoInformation/#{key}/SoInfoWeb.aspx' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'Origin: http://v5.ptpilot.com' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H 'Referer: http://v5.ptpilot.com/SoInformation/(S(vyknth0xfhddhigkh3jvuuje))/SoInfoWeb.aspx' -H 'Accept-Language: en-US,en;q=0.9' -H 'Cookie: __utmc=17271998; __utma=17271998.686954446.1568543605.1586894506.1586899995.3; __utmz=17271998.1586899995.3.2.utmcsr=seweurodrive.com|utmccn=(referral)|utmcmd=referral|utmcct=/s_ptpilot/so_information.php5; __utmt=1; __utmb=17271998.4.10.1586899995' --data '__VIEWSTATE=WkZHlniFfQAH0HORV8V1d1evohUaOoxCj7aYD8iHR7kkcmAL2wIGSJTh0c1IOdqId2N%2B%2FVdQXfw0x9x%2FrgJKh0%2BXixR2TAcDvLqbSxmK%2BVk%3D&__VIEWSTATEGENERATOR=4970F6BC&SO_1=#{so[0]}&SO_2=#{so[1]}&SO_3=#{so[2]}&SO_4=#{so[3]}&SO_5=#{so[4]}&Operation=1' --compressed --insecure"
  buff=`#{cmd}`
  if buff =~ /\/SoInformation\/(\(S\(.*?\)\))\/SoInfoWeb/m
    $key = $1
    `echo "#{key}" > key.key`
    return get(sn)
  end
  
  File.open("./out.html",'w') do |f|
    f.puts buff
  end
  
  so
end

def parse max_guess: nil, sn: ARGV.join
  so  = get sn
  doc = Nokogiri::HTML(open('./out.html'))

  buff=doc.at_css("div#soinfo_vpos").css("table")[-4..-1].map do |t| 
    t.inner_text 
  end.join("\n").split("\n").find_all do |l| 
    l.strip !='' 
  end.map do |l| 
    l.strip.gsub(/^[[:space:]]/, '')
  end

  if (buff[1] !~ /^[0-9]+/) || (buff[3] =~ /^MC/)
    so[2] = "07"
    so[3] = "07"
    
    return parse(max_guess: true, sn: so.join) unless max_guess
    puts Err.new("SO# not found").to_yaml
  else
    np = {}
    field = nil
    buff.each_with_index do |l,i|
      field = l if i.even?
      if i.odd?
        v=l
        v=v.to_i if l=~/^[0-9]+$/
        v=v.to_f if l=~/^[0-9]+\.[0-9]+$/
        v=v.to_f if l=~/^\.[0-9]+$/
        np[field.downcase.gsub("/",' ').split(' ').join("_")] = v
      end
    end
    
    if np['motor_hp']==''
      np['motor_hp'] = ((np['motor_amps'].to_s.split("/")[-1].to_f * np['motor_voltage'].to_s.split("/")[-1].to_f * 0.9) / 746).ceil.to_i
    end
    
    puts Motor.new(np).to_yaml
  end
rescue => e
  puts Err.new("#{e}").to_yaml
end

require 'yaml'
$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
require 'sew/motor'
parse

File.open("./key.key","w") do |f|
  f.puts key
end
