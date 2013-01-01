class Log
  def write_log(text)
    begin
      log_file = File.open("jrirc.log", 'a')
      log_file.puts("#{Time.now.asctime} -- #{text}")
      log_file.close
    rescue
      puts("Unable to write log file!")
    end
  end
end
