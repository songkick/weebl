require 'rubygems'
require 'mongo'

module Weebl
  class NotAvailable < StandardError; end
  
  class Mongo
    def self.stable_connection(hosts)
      connection, index = nil, 0
      while connection.nil?
        begin
          host = hosts[index]
          connection = ::Mongo::Connection.new(host[0].to_s, host[1].to_i)
        rescue => e
          index = (index + 1) % hosts.size
          sleep 2
        end
      end
      connection
    end
    
    def initialize(options = {})
      @options = options
    end
    
    def with_connection
      yield make_connection!
    rescue ::Mongo::ConnectionFailure
      @connection = nil
      raise NotAvailable.new("Could not connect to Mongo -- #{ hosts.inspect }")
    end
    
  private
    
    def make_connection!
      return @connection if @connection
      host = hosts.first
      @connection = ::Mongo::Connection.new(host[0].to_s, host[1].to_i, :slave_ok => @options[:read_only])
      verify_connection
      @connection
    end
    
    # simplest read we can do to find out if Mongo is up
    def verify_connection
      @connection && @connection.database_names
    end
    
    def hosts
      @options[:hosts]
    end
    
  end
  
end

