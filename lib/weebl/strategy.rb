module Weebl
  
  class Strategy
    class << self
      def [](name)
        class_name = name.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
        const_get(class_name).new
      end
    end
  end
  
  class Strategy::None < Strategy
    def attempt(setup)
      setup.call or raise NotAvailable.new
    end
  end
  
  class Strategy::Periodic < Strategy
    INTERVAL = 10
    
    def attempt(setup)
      connection = nil
      until connection
        connection = setup.call
        sleep(INTERVAL) unless connection
      end
      connection
    end
  end
  
end

