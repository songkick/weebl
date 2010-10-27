require 'mongo'
module Weebl
  
  class Mongo
    include Weebl
    
    def initialize(options = {})
      @options = options
    end
    
    def with_connection(&block)
      yield_with_retries(block, @options[:retry]) do
        hosts.each do |host|
          next if connection_ok?
          @connection = make_connection(host)
        end
        @connection
      end
    end
    
  private
    
    def make_connection(host)
      ::Mongo::Connection.new(host[0].to_s, host[1].to_i)
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

