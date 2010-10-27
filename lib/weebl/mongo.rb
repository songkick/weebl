require 'mongo'
module Weebl
  
  class Mongo < Fallible
    def get_connection
      @options[:hosts].each do |host|
        @connection ||= make_connection(host)
      end
      @connection
    end
    
    def exception_type
      ::Mongo::ConnectionFailure
    end
    
    def on_fail(exception)
      @connection = nil
    end
    
  private
    
    def make_connection(host)
      ::Mongo::Connection.new(host[0].to_s, host[1].to_i)
    rescue exception_type
      nil
    end
  end
  
end

