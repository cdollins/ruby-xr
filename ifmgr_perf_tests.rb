$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib/snmp-1.0.2/lib/"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/lib/ruby-xr"))

require 'yaml'
require 'Cooker.rb'
require 'GraphPerf.rb'
require 'ConfigCreate.rb'
require 'XrTelnet.rb'
require 'pp'

describe "Test for performance of IF-MIB on XR platform" do

  ### Test Suites Go Here ###

  load 'create_interfaces_test.rb'

#  load 'delete_interfaces_test.rb'

#  load 'get_non_stat_interface.rb'

#  load 'get_stat_interface.rb'


end
