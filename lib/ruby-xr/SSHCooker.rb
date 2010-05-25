require 'net/ssh'
class SSHCooker
  def initialize(user, pass)
    @user = user
    @pass = pass
  end
  
  def open(server)
  @conn = Net::SSH.start(server, @user, :password => @pass)
  end
  
  def traceprinter(at, name)
    path = at+'/'+name
    @conn.exec!("/users/dbarach/bin.linux/traceprinter -f #{path}.kev > #{path}.txt")
  end
  
  def x2cpel(at, name)
    path = at+'/'+name
    @conn.exec!("/users/dbarach/bin.linux/x2cpel --i #{path}.txt --o #{path}.out")
  end
  
  def cpeldump(at, name)
    path = at+'/'+name
    @conn.exec!("/users/dbarach/bin.linux/cpeldump --input_file #{path}.out > #{path}.cpeldump")
  end
  
  def cook(at, list)
    files = Array.new
    list.each do |file|
      name = file.sub(/.kev$/, '')
      traceprinter(at, name)
      x2cpel(at, name)
      cpeldump(at, name)
      files.push(name+".cpeldump")
    end
  end
  
  def close
    @conn.close{|str| print str}
  end
  
  def copy(list, from, to)
    list.each do |file|
      f_path = from+'/'+file
      t_path = to+'/'+file
      @conn.exec!("cp #{f_path} #{t_path}")
    end
  end  

end