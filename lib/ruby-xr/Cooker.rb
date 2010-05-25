require 'EventParser.rb'
require 'EventPointEater.rb'
class Cooker
  
  def Cooker.traceprinter(path)
    `/users/dbarach/bin.linux/traceprinter -f #{path}.kev > #{path}.txt`
  end
  
  def Cooker.x2cpel(path)
    `/users/dbarach/bin.linux/x2cpel --i #{path}.txt --o #{path}.out`
  end
  
  def Cooker.cpeldump(path)
    `/users/dbarach/bin.linux/cpeldump --input_file #{path}.out > #{path}.cpeldump`
  end
  
  def Cooker.snmp_grep(path)
    `cat #{path}.cpeldump | grep snmp > #{path}.snmp`    
  end
  
  def Cooker.csv(path, name, points)
    files = Array.new
    tmpEvents = Hash.new
    points.each {|key,value| tmpEvents[key] = Array.new}
    
    EventParser.parse("#{path}/#{name}.snmp", points).each do |event|
      tmpEvents[event.event_id.to_i].push event
    end

    tmpEvents.each do |key, group|
      if((key % 2) == 1 && group.size > 0)
        tag = /(\w+)_START/.match points[key]
        at = "#{path}/#{tag[1]}"
        `mkdir -p #{at}`
        files.push("#{at}/#{tag[1]}.csv")
        File.open("#{at}/#{tag[1]}.csv","w") do |file|
          0.upto(group.size - 1) do |int|
            if(!tmpEvents[key+1][int].nil?)
             file.puts("#{int+1},#{group[int].delta(tmpEvents[key+1][int])}")
            end
          end    
        end
      end
    end
    return files
  end

  def Cooker.cook(tftp, at, name, points)
    puts "+#{Time.now}: Cooker stated"
    f_path = "#{tftp}/#{name.join('_')}"
    t_path = "#{at}/#{name.join('/')}"
    loc = "#{t_path}/#{name[1]}"
    `cp #{f_path}.kev #{loc}.kev`
    
    Cooker.traceprinter(loc)
    Cooker.x2cpel(loc)
    Cooker.cpeldump(loc)
    Cooker.snmp_grep(loc)
    next_f = Cooker.csv(t_path, name[1], points)
    `tar --remove-files -czvf #{loc}.tar.gz -C #{t_path} -- \`ls #{t_path} | grep #{name[1]}\``
    return next_f
  end

end
