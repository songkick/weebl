require 'fileutils'
require 'eventmachine'

SPEC_DIR = File.dirname(File.expand_path(__FILE__))
TMP_DIR  = File.join(SPEC_DIR, '..', 'tmp')

require File.join(SPEC_DIR, '..', 'lib', 'weebl')

RSpec.configure do |config|
  config.before { FileUtils.mkdir_p(TMP_DIR) }
  config.after { FileUtils.rm_rf(TMP_DIR) }
end

module Helper
  def self.ensure_reactor_running
    Thread.new { EM.run unless EM.reactor_running? }
    sleep 0.1 until EM.reactor_running?
  end
  
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
    
    def master_connection
      ports = @config.values
      connection, index = nil, 0
      while connection.nil?
        begin
          port = ports[index]
          connection = ::Mongo::Connection.new('localhost', port.to_i)
        rescue => e
          index = (index + 1) % ports.size
          sleep 2
        end
      end
      connection
    end
    
    def shutdown_master
      master_side = @config.index(master_connection.port)
      @procs[master_side].kill 'INT'
      sleep 5
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

