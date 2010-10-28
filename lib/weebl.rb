require 'rubygems'

module Weebl
  VERSION = '0.1.0'
  
  class NotAvailable < StandardError; end
  
  ROOT = File.expand_path(File.dirname(__FILE__))
  autoload :Fallible, ROOT + '/weebl/fallible'
  autoload :Mongo,    ROOT + '/weebl/mongo'
  autoload :Strategy, ROOT + '/weebl/strategy'
  
end

