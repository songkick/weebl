module Weebl
  
  class Strategy
    class << self
      def [](name)
        @registry[name].new
      end
      
      def register(name, klass)
        @registry ||= {}
        @registry[name] = klass
      end
    end
  end
  
  class None < Strategy
    def attempt(setup, on_success)
      connection = setup.call
      if connection
        on_success.call(connection)
      else
        raise NotAvailable.new
      end
    end
  end
  
  class Periodic < Strategy
    INTERVAL = 10
    def attempt(setup, on_success)
      connection = nil
      until connection
        connection = setup.call
        sleep(INTERVAL) unless connection
      end
      on_success.call(connection)
    end
  end
  
  Strategy.register :none,     None
  Strategy.register :periodic, Periodic
  
end

