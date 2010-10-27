require 'spec_helper'
require 'mongo'

describe Weebl::Mongo do
  HOSTS = [['localhost', 7000], ['localhost', 7001]]
  
  let(:mongo_pair) { Helper::MongoPair.new(:left => 7000, :right => 7001) }
  
  context "read-only, no retries" do
    let(:client) { Weebl::Mongo.new(:hosts => HOSTS, :retry => :none) }
    
    context "when Mongo is down" do
      it "throws errors when you try to read" do
        lambda {
          client.with_connection { |conn| conn.db('test') }
        }.should raise_error(Weebl::NotAvailable)
      end
    end
    
    context "when there's Mongo pair up" do
      before { mongo_pair.startup  }
      after  { mongo_pair.shutdown }
      
      context "and there is data in it" do
        before do
          conn = mongo_pair.master_connection
          conn.db('test')['test_set'].insert('hello' => 'world')
        end
        
        it "yields a connection that you can read from" do
          document = client.with_connection { |conn| conn.db('test')['test_set'].find_one }
          document['hello'].should == 'world'
        end
      end
    end
  end
end

