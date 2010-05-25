require 'EventTime.rb'
class Event
   attr_reader :time, :event_id
   def initialize(time, process, thread_pid, event_id, signal)
      @time = EventTime.new(time)
      @process = process
      @thread_pid = thread_pid
      @event_id, = event_id
      @signal = signal
   end
   
   def delta(that)
     return @time.delta(that.time).to_norm
   end
   
   def to_s(pretty=nil)
     if !pretty
       "#{@time},#{@process},#{@thread_pid},#{@event_id},#{@signal}"
     else
       "#{@time},#{@process},#{@thread_pid},#{pretty},#{@signal}"
     end
   end
   
end
