require 'spec_helper'

describe Weebl::Strategy do
  describe ".[]" do
    before do
      class Weebl::Strategy::FooBar; end
    end
    
    it "returns an instance of the named strategy" do
      Weebl::Strategy[:foo_bar].should be_kind_of(Weebl::Strategy::FooBar)
    end
  end
  
  describe :None do
    let(:strategy) { Weebl::Strategy::None.new }
    
    it "throws an error if the block returns nil" do
      block = lambda { nil }
      lambda { strategy.attempt(block) }.should raise_error(Weebl::NotAvailable)
    end
    
    it "returns the result of the setup block" do
      strategy.attempt(lambda { :hello }).should == :hello
    end
  end
  
  describe :Periodic do
    let(:strategy) { Weebl::Strategy::Periodic.new }
    let(:success)  { lambda { |conn| @result = conn } }
    
    it "retries until the block returns something" do
      attempts = 0
      
      block = lambda do
        if attempts == 2
          :done
        else
          attempts += 1
          nil
        end
      end
      
      strategy.attempt(block)
      attempts.should == 2
    end
    
    it "returns the result of the setup block" do
      strategy.attempt(lambda { :hello }).should == :hello
    end
  end
end

