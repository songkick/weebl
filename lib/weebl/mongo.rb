require 'mongo'
module Weebl
  
  class Mongo
    def initialize(options = {})
      @options = options
    end
    
    def with_connection
      hosts.each do |host|
        next if @connection
        @connection = make_and_verify_connection(host)
      end
      if @connection
        yield @connection
      else
        raise NotAvailable.new("Could not connect to MongoDB -- #{ hosts.inspect }")
      end
    end
    
  private
    
    def make_and_verify_connection(host)
      connection = ::Mongo::Connection.new(host[0].to_s, host[1].to_i)
      connection.database_names
      connection
    rescue ::Mongo::ConnectionFailure
      nil
    end
    
    # simplest read we can do to find out if Mongo is up
    def connection_ok?
      return false if @connection.nil?
      @connection.database_names
      true
    rescue ::Mongo::ConnectionFailure
      false
    end
    
    def hosts
      @options[:hosts]
    end
  end
  
end

