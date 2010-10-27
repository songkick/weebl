require 'spec_helper'
require 'mongo'

describe Weebl::Mongo do
  HOSTS = [['localhost', 7000], ['localhost', 7001]]
  
  let(:mongo_pair) { Helper::MongoPair.new(:left => 7000, :right => 7001) }
  
  context "no retries" do
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
          @master_connection_port = conn.port
          conn.db('test')['test_set'].insert('hello' => 'world')
        end

        it "yields a connection that you can read from" do
          client.with_connection do |conn|
            collection = conn.db('test')['test_set']
            collection.find_one['hello'].should == 'world'
          end
        end
        
        context "and the master goes down when the client has a connection to it" do
          before do
            client.with_connection { }
            sleep 5 # replication lag much?
            mongo_pair.shutdown_master
          end
          
          it "continues reading fine from the other host" do
            client.with_connection do |conn|
              collection = conn.db('test')['test_set']
              collection.find_one['hello'].should == 'world'
              @master_connection_port.should_not == conn.port
            end
          end
        end
      end
    end
  end
  
  context "with periodic retries" do
    let(:client) { Weebl::Mongo.new(:hosts => HOSTS, :retry => :periodic) }
    
    context "when Mongo is down" do
      before do
        @start_time = Time.now
        Helper.ensure_reactor_running
        EM.add_timer(20) { mongo_pair.startup }
      end
      
      after { mongo_pair.shutdown }
      
      it "blocks until Mongo comes up" do
        client.with_connection do |conn|
          conn.db('test').should_not be_nil
          @elapsed = Time.now - @start_time
        end
        @elapsed.should > 20
      end
    end
  end
end

