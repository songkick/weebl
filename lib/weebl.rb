require 'rubygems'

module Weebl
  class NotAvailable < StandardError; end
  
  ROOT = File.expand_path(File.dirname(__FILE__))
  autoload :Mongo,    ROOT + '/weebl/mongo'
  autoload :Strategy, ROOT + '/weebl/strategy'
  
  def with_retries(strategy_type, &block)
    strategy = Strategy[strategy_type]
    strategy.attempt(block)
  end
  
end

