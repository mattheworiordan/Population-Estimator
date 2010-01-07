# Simultaneous logger, writes to STDOUT as well as standard Rails Logger
# useful for debugging by looking at the console output
class SLogger 
  
  class << self
    def debug(message, timestamp = nil)
      log_message :debug, message, timestamp
    end
    def info(message, timestamp = nil)
      log_message :info, message, timestamp
    end
    def warn(message, timestamp = nil)
      log_message :warn, message, timestamp
    end
    def error(message, timestamp = nil)
      log_message :error, message, timestamp
    end
    def fatal(message, timestamp = nil)
      log_message :fatal, message, timestamp
    end
  
  private
    def log_message(severity, msg, starttime)
      timestamp = Time.now
      timediff = (starttime ? " > took %0.4fs" % (timestamp - starttime).to_s : "")
      RAILS_DEFAULT_LOGGER.send severity, "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}#{timediff}\n"
      puts "> #{severity}: #{msg}#{timediff}\n" unless AppConfig.verbose_logging = false
      timestamp
    end
  end
end 