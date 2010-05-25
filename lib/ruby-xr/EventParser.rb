require 'Event.rb'
class EventParser
   def EventParser.parse(file, event_hash)
      events = Array.new
      File.new(file, "r").each do |line|
         (x,y,z,a,b) = line.split
         if !event_hash[a.to_i].nil?
            events.push(Event.new(x,y,z,a,b))
         end
      end
      return events
   end
end
