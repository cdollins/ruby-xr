require 'net/telnet'
require 'pp'
class XrTelnet
  
  def initialize(console, auxilary, loc)
    puts "+#{Time.now}: Telnet initialized"
    `mkdir -p #{loc}`
    @con_conn = open_console(console, "#{loc}/console.log")
    @aux_conn = open_console(auxilary, "#{loc}/auxilary.log")
    @configs = Array.new
  end

  def open_console(info, loc)
    #Establish a raw telnet connection with XR console

    connection = Net::Telnet::new(
      "Host" => info["host"],
      "Port" => info["port"],
      "Prompt" => /(\#\s*$)|(\>$)/,
      "Output_log" => loc)

    str = connection.cmd("String" => "\n",
                         "Timeout" => false,
                         "Match" => /(^Username:)|(\#\s*$)|(\>$)|(config)/)
    if /^Username:/.match str
      #Attempt to login
      pass = connection.cmd("String" => info['username'], 
                     "Match" => /^Password:/)
      connection.cmd(info['password'])
    elsif /config/.match str
      #Console may be in config mode
      connection.cmd("end\nno")
    elsif /(\#\s*$)|(\>$)/.match str
       #Console may already be logged into too
    else
       raise Errno::ECONNREFUSED
    end
    return connection
  end

  def close
     close_console
     close_auxilary
    puts "+#{Time.now}: Telnet closed"
  end

  def close_console
    while(unconfig); end
#    @con_conn.puts("exit")
    @con_conn.close
  end
  
  def close_auxilary
    @aux_conn.close
  end
  
  def start_logger(secs)
    puts "+#{Time.now}: Starting logger for #{secs}"
    @aux_conn.cmd(
      "String" => 
      "tracelogger -F 1 -F 2 -F 6 -F 11 -n 0 -s #{secs} -M -S 100M -vvv",
      "Timeout" => false,
      "Match" => /^Set/)
  end

  def stop_logger
    @aux_conn.cmd("\C-c")
  end
  
  def copy_log(tftpserver, name)
    puts "+#{Time.now}: Copying logs to tftp://#{tftpserver}/#{name}"
    aux_cmd("cp /dev/shmem/tracebuffer.kev tftp://#{tftpserver}/#{name}")
  end
  
  def exec(string="")
    puts "+#{Time.now}: Executing #{string}"
    if(block_given?)
          yield @con_conn    
    end
    @con_conn.cmd("String" => string,
                  "Timeout" => false)
  end

  def config(options=nil)
    puts "+#{Time.now}: Configure w/ options => #{pp(options)}"

    log = false
    time = 60
    command = "!configure"
    

    @con_conn.cmd("String" => "conf t",
                   "Timout" => false)
    if(block_given?)
      yield @con_conn    
    end

    if !options.nil?
      if options.kind_of? Hash
        log = options[:log] if options.has_key? :log
        time = options[:time] if options.has_key? :time
        command = options[:command] if options.has_key? :command
      else
        command = options
      end
    end

    @con_conn.cmd("String" => command,
                  "Timeout" => false)

    start_logger time if log

    str = @con_conn.cmd("String" => "commit", 
                        "Timeout" => false)

    if /changes\s(\d+)/.match str
      change = (/changes\s(\d+)/.match str)[1]
    end
    
    @con_conn.cmd("end")
    
    @configs.push change
  end
  
  def unconfig(options=nil)
    puts "+#{Time.now}: Unconfig w/ options => #{pp(options)}"
    log = false
    time = 60

    return false if @configs.empty?
    
    if(!options.nil? && options.kind_of?(Hash))
      log = options[:log] if options.has_key? :log
      time = options[:time] if options.has_key? :time
    end

    @con_conn.cmd("String" => "conf t",
                  "Timeout" => false)
    @con_conn.cmd("String" => "load rollback changes #{@configs.pop}",
                  "Timeout" => false)

    start_logger time if log

    @con_conn.cmd("String" => "commit",
                  "Timeout" => false)
    @con_conn.cmd("end")
    return true  
    
  end
  
  def aux_cmd(string="")
    @aux_conn.waitfor("Match" => /\#\s$/n,
                      "Timeout" => false)
    if(block_given?)
      yield @aux_conn
    else
      @aux_conn.cmd("String" => string,
                    "Timeout" => false)
    end
  end
end
