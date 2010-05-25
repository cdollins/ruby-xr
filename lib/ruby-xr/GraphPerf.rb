require 'gnuplot'
class GraphPerf

  def GraphPerf.graph_test(file, options=nil)
    puts "+#{Time.now}: Grapher stated"
    start = 1
    interval = 1

    if !options.nil? 
      if options.kind_of? Hash
        start = options[:start] if options.has_key? :start
        interval = options[:interval] if options.has_key? :interval
      end
    end

    iface = Array.new
    time = Array.new
    x = 1
    File.new(file,"r").each do |line|
      if ((x - start) % interval == 0)
        a,b = line.split(',')
        iface.push a
        time.push  b
        x += 1
      end
    end

    dat = /(\/[\w+\/|\w+\-]+\w+).csv/.match file
    File.open(dat[1]+".dat","w") do |out|
      Gnuplot::Plot.new( out ) do |plot|
        plot.ylabel "Time(usec)"
        plot.xlabel "Interface Created"
        plot.set("term png")
        data = [iface, time]
        plot.data << Gnuplot::DataSet.new(data) do |ds|
          ds.with = "impulses"
          ds.title = "Array data"
        end
      end
    end
    `gnuplot #{dat[1]}.dat > #{dat[1]}.png`
  end

end
