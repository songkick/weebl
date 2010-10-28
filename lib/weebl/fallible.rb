module Weebl
  
  class Fallible
    def initialize(options)
      @options  = options
      @strategy = Strategy[@options[:retry]].new(self)
    end
    
    def with_connection(&task)
      @strategy.run(&task)
    end
    
    def on_fail
    end
    
  private
    
    def method_missing(key)
      key = [key.to_s, key.to_sym].find(&@options.method(:has_key?))
      key && @options[key]
    end
  end
  
end

