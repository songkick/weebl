require 'rubygems'

module Weebl
  class NotAvailable < StandardError; end
  
  ROOT = File.expand_path(File.dirname(__FILE__))
  autoload :Mongo,    ROOT + '/weebl/mongo'
  autoload :Strategy, ROOT + '/weebl/strategy'
  
  def yield_with_retries(on_success, strategy_type, &setup)
    strategy = Strategy[strategy_type]
    strategy.attempt(setup, on_success)
  end
  
end

