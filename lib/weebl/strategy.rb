module Weebl
  
  class Strategy
    class << self
      def [](name)
        class_name = name.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
        const_get(class_name)
      end
    end
    
    def initialize(fallible)
      @fallible = fallible
    end
  end
  
  class Strategy::None < Strategy
    def run(&task)
      connection = @fallible.get_connection
      raise NotAvailable.new unless connection
      task.call(connection)
    rescue @fallible.exception_type => e
      @fallible.on_fail(e)
      raise NotAvailable.new
    end
  end
  
  class Strategy::Periodic < Strategy
    INTERVAL = 10
    
    def run(&task)
      repeat_until(:complete) do
        connection = repeat_until(:result) { @fallible.get_connection }
        task.call(connection)
      end
    end
    
    def repeat_until(expectation, &block)
      result, complete = nil, false
      
      done = (expectation == :result) ?
             lambda { not result.nil? } :
             lambda { complete }
      
      until done[]
        begin
          result = block.call
          complete = true
        rescue @fallible.exception_type => e
          @fallible.on_fail(e)
        end
        sleep(INTERVAL) unless done[]
      end
      result
    end
  end
  
end

