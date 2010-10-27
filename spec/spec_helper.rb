require 'fileutils'

SPEC_DIR = File.dirname(File.expand_path(__FILE__))
TMP_DIR  = File.join(SPEC_DIR, '..', 'tmp')

trap('INT') { FileUtils.rm_rf(TMP_DIR) }

require File.join(SPEC_DIR, '..', 'lib', 'weebl')

RSpec.configure do |config|
  config.before { FileUtils.mkdir_p(TMP_DIR) }
  config.after { FileUtils.rm_rf(TMP_DIR) }
end

module Helper
  class MongoPair
    def initialize(config)
      @config = config
      %w[left right].each { |side| FileUtils.mkdir_p(File.join(TMP_DIR, side)) }
    end
    
    def startup
      @procs = {
        :left  => Daemon.new("mongod --dbpath #{TMP_DIR}/left --port #{@config[:left]} --pairwith localhost:#{@config[:right]}"),
        :right => Daemon.new("mongod --dbpath #{TMP_DIR}/right --port #{@config[:right]} --pairwith localhost:#{@config[:left]}")
      }
    end
    
    def shutdown
      return unless @procs
      @procs.each { |side, proc| proc.kill 'INT' }
      %w[left right].each { |side| FileUtils.rm_rf(File.join(TMP_DIR, side)) }
      @procs = nil
    end
  end
  
  class Daemon
    def initialize(shell)
      @shell   = shell
      @pipe    = IO.popen(shell)
      @running = true
    end
    
    def kill(signal)
      return unless @running
      @running = false
      Process.kill(signal, @pipe.pid)
      @pipe.close
    end
  end
end
