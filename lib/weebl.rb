require 'rubygems'
require 'mongo'

module Weebl
  
  class Mongo
    def self.stable_connection(hosts)
      connection, index = nil, 0
      while connection.nil?
        begin
          host = hosts[index]
          connection = ::Mongo::Connection.new(host[:host].to_s, host[:port].to_i)
        rescue => e
          index = (index + 1) % hosts.size
          sleep 2
        end
      end
      connection
    end
  end
  
end

