$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib/gnuplot-2.2/lib/"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib/snmp-1.0.2/lib/"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib/ruby-xr"))

require 'yaml'
require 'Cooker.rb'
require 'GraphPerf.rb'
require 'ConfigCreate.rb'
require 'XrTelnet.rb'
require 'pp'

interval = 100
total = 200
describe "Performance Analysis" do
 
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
     @csvs = Array.new

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

   (total/interval).times do |num|
     it "Create Many Kev files" do
       @name = [@timestamp, "sample_#{num}"]

       #Create config file with interfaces
       ConfigCreate.create_loopback_conf(:start => (num * interval),
                                         :size => (interval - 1),
                                         :no => true,
                                         :loc => "/tftpboot/#{@tftp[1]}")

       #Copy config file
       @conn.exec("copy tftp://#{@tftp.join('/')}/running.config nvram:changeset\n\n")

       #Load changes
       @conn.config("load nvram:changeset")


       @conn.config(:log => true,
                    :command => "int l#{((num + 1) * interval)}",
                    :time => 1)
     end
   end

   ### Tear-Down ###

   after(:each) do

     #Copy logs of UUT
     @conn.copy_log(@tftp.join('/'), "#{@name.join('_')}.kev")

     #Cook kev file into csv
     @csvs.push Cooker.cook("/tftpboot/#{@tftp[1]}",
                        @env["workspace"],
                        @name,
                        @points)
   end

   after(:all) do

     @csvs.each do |files|
       for file in files
         @points.each do |key, value|
           tag = /(\w+)_(START|STOP)/.match value
           puts "file: #{file} Value: #{tag[1]}"
           if tag[1].match file
            puts "cat #{file} >> #{@env['workspace']}/#{@timestamp}/#{tag}.csv"
           end
         end
       end
     end

#     Graph csv data using gnuplot
#     csvs.each {|csv| GraphPerf.graph_test(csv, 
#                                           :start => 100,
#                                           :iterval => 100)}

     #Close XR connections
     @conn.close
   end

end
