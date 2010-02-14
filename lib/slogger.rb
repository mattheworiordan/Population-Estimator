##
# Simultaneous logger, writes to STDOUT as well as standard Rails Logger
# useful for debugging by looking at the console output whereas as standard Rails Logger logs to one or the other
#
# Can be used with a block to Benchmark

class SLogger 
  
  class << self
    def debug(message, timestamp = nil, &block)
      log_message :debug, message, timestamp, &block
    end
    def info(message, timestamp = nil, &block)
      log_message :info, message, timestamp, &block
    end
    def warn(message, timestamp = nil, &block)
      log_message :warn, message, timestamp, &block
    end
    def error(message, timestamp = nil, &block)
      log_message :error, message, timestamp, &block
    end
    def fatal(message, timestamp = nil, &block)
      log_message :fatal, message, timestamp, &block
    end
  
  private
    def log_message(severity, msg, starttime, &block)
      # simple message to be written
      if (!block) 
        timediff = (starttime ? " > took %0.4fs" % (Time.now - starttime).to_s : "")
        RAILS_DEFAULT_LOGGER.send severity, "#{Time.now.to_formatted_s(:db)} #{severity} #{msg}#{timediff}\n"
        puts "> #{severity}: #{msg}#{timediff}\n" unless AppConfig.verbose_logging = false
        Time.now
      else
        RAILS_DEFAULT_LOGGER.send severity, "#{msg}...\n"
        puts "#{msg}..." unless AppConfig.verbose_logging = false
        
        timediff = "%0.4fs" % Benchmark.measure { yield }.real
        
        RAILS_DEFAULT_LOGGER.send severity, "  ... finished #{msg.downcase} in #{timediff}\n"
        puts "  ... finished #{msg.downcase} in #{timediff}\n" unless AppConfig.verbose_logging = false
      end
    end
  end
end 