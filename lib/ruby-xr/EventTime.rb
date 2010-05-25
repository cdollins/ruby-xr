class EventTime
   attr_reader :my_time

   def initialize(time)
      @my_time_s = time
      @my_time = time.split(':')
   end

   def delta(that)
      tmp =  @my_time <=> that.my_time
      if tmp >= 1
         minus(that.my_time)
      else tmp == -1
         that.minus(@my_time)
      end
   end

   def minus(that_time)
      a = borrow(to_i(that_time))
      b = to_i(that_time)
      c = Array.new
      for i in 0..4
         c[i] = a[i] - b[i]
      end
      return EventTime.new(c.join(':'))
   end

   def borrow(that_time)
     a = to_i(@my_time)
     b = that_time
     base = [60, 60, 1000, 1000]
     for i in 0..3
        num = 4 - i
        if a[num] < b[num]
           a[num] += base[num-1]
           a[num-1] -= 1
        end
     end
     return a
   end

   def to_i(array)
      a = Array.new
      array.each do |i|
         a.push i.to_i
      end
      return a
   end

   def to_s()
      return @my_time_s
   end

   def to_norm()
     micro = 0
     a = to_i(@my_time)
     base = [86400000, 3600000, 60000, 1000, 1]
     for i in 0..4
        micro += a[i] * base[i]
     end
     return micro
   end

end
