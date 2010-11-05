module Weebl
  
  class Fallible
    def initialize(options)
      @options   = options
      @strategy  = Strategy[@options[:retry]].new(self)
      @listeners = Hash.new { |h,k| h[k] = [] }
    end
    
    def with_connection(&task)
      @strategy.run(&task)
    end
    
    def on_fail
    end
    
    def on(event_type, &block)
      @listeners[event_type] << block
    end
    
    def trigger(event_type, data)
      return unless @listeners.has_key?(event_type)
      @listeners[event_type].each do |listener|
        listener.call(data)
      end
    end
    
  private
    
    def method_missing(key)
      key = [key.to_s, key.to_sym].find(&@options.method(:has_key?))
      key && @options[key]
    end
  end
  
end

