describe "Create interfaces" do
  ### Build-up ###
  before(:all) do

     puts "+#{Time.now}: IF-MIB performance test  preconfig started"

     #Load Environment Data
     @env = YAML::load(File.open('Environment.yaml'))
     @points = EventPointEater.eat_header(@env['build_dir'])
     @tftp = [@env["tftpserver"]["ip"],
              @env["tftpserver"]["dir"]]
     @timestamp = Time.now.strftime("%b%d-%H%M%S")
     @csvs = Array.new

     #Establish XR connections
     @conn = XrTelnet.new(@env['console'],
                          @env['auxilary'],
                          @env["workspace"]+ '/' + @timestamp)


     @conn.config do |console|
       #Prevent MORE from running
       console.cmd("line con 0")
       console.cmd("length 0")

       #Configure SNMP
       console.cmd("logging console debugging")
       console.cmd("snmp-server community public RW SystemOwner")
       console.cmd("snmp-server community sdr_owner SDROwner")
       console.cmd("snmp-server community sys_owner SystemOwner")
     end

   end


  ### Test Case ###

  it "Create 200 interfaces sampling time on every 100th" do
    total = 10000
    interval = 100
    (total/interval).times do |num|
      @name = [@timestamp, "sample_#{num}"]

      #Create config file with interfaces
      ConfigCreate.create_loopback_conf(:start => (num * interval),
                                        :size => (interval - 1),
#                                        :no => true,
                                        :loc => "/tftpboot/#{@tftp[1]}")

     #Copy config file
      @conn.exec("copy tftp://#{@tftp.join('/')}/running.config nvram:changeset\n\n")

      #Load changes
      @conn.config("load nvram:changeset")

      @conn.config(:log => true,
                  :command => "int l#{((num + 1) * interval)}",
                  :time => 1)

      #Copy logs of UUT

      @conn.copy_log(@tftp.join('/'), "#{@name.join('_')}.kev")

      #Cook kev file into csv
      @csvs.push Cooker.cook("/tftpboot/#{@tftp[1]}",
                             @env["workspace"],
                             @name,
                             @points)
    end
  end

   ### Tear-Down ###

   after(:all) do
     aggr_csvs = Array.new
     x = 1
     @csvs.each do |files|
       for file in files
         @points.each do |key, value|
           tag = /(\w+)_START/.match(value)
           if tag && file.match(tag[1])
             `mkdir -p #{@env['workspace']}/#{@timestamp}/#{tag[1]}`
             csv = "#{@env['workspace']}/#{@timestamp}/#{tag[1]}/#{tag[1]}.csv"
             delta = File.read(file).split(',')[1]
             File.open(csv, "a") {|out| out.puts("#{x},#{delta}")}
             aggr_csvs.push csv
           end
         end
       end
       x += 1
     end

     #Graph csv data using gnuplot
     aggr_csvs.each {|csv| GraphPerf.graph_test(csv)}

     #Close XR connections
     @conn.close
   end

end
