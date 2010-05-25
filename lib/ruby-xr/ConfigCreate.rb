class ConfigCreate
  def ConfigCreate.create_loopback_conf(num_int, sub_dir)
    file = File.new("/tftpboot/#{sub_dir}/running.config","w")
    (1..num_int).each do |x|
      file.puts("int l#{x}")
    end
    file.close
  end

  def ConfigCreate.delete_loopback_conf(num_int, sub_dir)
     file = File.new("/tftpboot/#{sub_dir}/running.config","w")
    (1..num_int).each do |x|
      file.puts("no int l#{x}")
    end
    file.close
  end

end
