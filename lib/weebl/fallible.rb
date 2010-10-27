module Weebl
  
  class Fallible
    def initialize(options)
      @options = options
    end
    
    def with_connection(&task)
      strategy = Strategy[@options[:retry]].new(self)
      strategy.run(&task)
    end
    
    def on_fail
    end
  end
  
end

