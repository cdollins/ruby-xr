describe "Get non-statistical interface attributes" do
 
   ### Build-Up ###
   before(:all) do
     puts "+#{Time.now}: Preconfig started"

     #Load Environment Data
     @env = YAML::load(File.open('Environment.yaml'))
     @points = EventPointEater.eat_header(@env['build_dir'])
     @tftp = [@env["tftpserver"]["ip"], 
              @env["tftpserver"]["dir"]]
     @timestamp = Time.now.strftime("%b%d-%H%M%S")

     @name = [@timestamp]


     @ifTable_nonstat_columns = ["ifIndex",
                                "ifDescr",
                                "ifType",
                                "ifMtu",
                                "ifSpeed",
                                "ifPhysAddress",
                                "ifAdminStatus",
                                "ifOperStatus",
                                "ifLastChange",
                                "ifName",
                                "ifLinkUpDownTrapEnable",
                                "ifPromiscuousMode",
                                "ifConnectorPresent",
                                "ifAlias"]


     #Establish XR connections
     @conn = XrTelnet.new(@env['console'],                 
                          @env['auxilary'], 
                          @env["workspace"]+ '/' + @name.join('/'))

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

   
   ### Test Cases ###
   it "Get non-statistical attribute for interface" do
     100.times do |num|

       #Create config file with interfaces
       ConfigCreate.create_loopback_conf(:start => (num * 100),
                                         :size => 100,
                                         :copy_loc => "/tftpboot/#{@tftp[1]}")

       #Copy config file
       @conn.exec("copy tftp://#{@tftp.join('/')}/running.config nvram:changeset\n\n")

       #Load changes
       @conn.config("load nvram:changeset")

         @ifTable_nonstat_columns.each do |attr|

             @name = [@timestamp, "sample_#{num}"]
             SNMP::Manager.open(:Host => @mgmt_port) do |manager|
#             @conn.start_logger(10)
#              manager.get(attr) {}
             end

             #Copy logs of UUT
#             @conn.copy_log(@tftp.join('/'), "#{@name.join('_')}.kev")

#             Cook kev file into csv
#             csvs = Cooker.cook("/tftpboot/#{@tftp[1]}",
#                                @env["workspace"],
#                                @name,
#                                @points)

#             Graph csv data using gnuplot
#             csvs.each {|csv| GraphPerf.graph_test(csv, 
#                                                   :start => 100,
#                                                   :iterval => 100)}
       end
     end
   end

   ### Tear-Down ###

   after(:all) do
     #Close XR connections
     @conn.close
   end

end
