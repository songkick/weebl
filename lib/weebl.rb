require 'rubygems'

module Weebl
  class NotAvailable < StandardError; end
  
  ROOT = File.expand_path(File.dirname(__FILE__))
  autoload :Mongo, ROOT + '/weebl/mongo'
  
end

