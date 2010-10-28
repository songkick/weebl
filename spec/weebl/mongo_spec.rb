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
      before do
        mongo_pair.startup
        conn = mongo_pair.master_connection
        @master_connection_port = conn.port
        conn.db('test')['test_set'].insert('hello' => 'world')
      end
      
      after do
        mongo_pair.shutdown
        mongo_pair.clean
      end
      
      it "yields a connection that you can read from" do
        document = client.with_connection do |conn|
          collection = conn.db('test')['test_set']
          collection.find_one
        end
        document['hello'].should == 'world'
      end
      
      context "and the master goes down when the client has a connection to it" do
        before do
          client.with_connection { }
          sleep 5 # replication lag much?
          mongo_pair.shutdown_master
        end
        
        it "fails on the next read, then continues reading from the other host" do
          lambda {
            client.with_connection { |conn| conn.db('test')['test_set'].find_one }
          }.should raise_error(Weebl::NotAvailable)
          
          client.with_connection do |conn|
            collection = conn.db('test')['test_set']
            collection.find_one['hello'].should == 'world'
            @master_connection_port.should_not == conn.port
          end
        end
      end
      
      context "and both hosts go down once we have a collection object" do
        before do
          client.with_connection do |conn|
            @collection = conn.db('test')['test_set']
            @collection.find_one['hello'].should == 'world'
          end
          mongo_pair.shutdown
          sleep 2
        end
        
        it "does not throw an error when getting the cached connection" do
          client.with_connection {}
        end
        
        it "throws an error when trying to read" do
          lambda {
            client.with_connection { |conn| @collection.find_one }
          }.should raise_error(Weebl::NotAvailable)
        end
      end
      
      context "and Mongo goes down during a block" do
        before do
          @already_shut_down = false
        end
        
        it "throws an error and does not write to the database" do
          lambda {
            client.with_connection do |conn|
              unless @already_shut_down
                mongo_pair.shutdown
                @already_shut_down = true
              end
              conn.db('test')['test_set'].insert('new' => 'doc')
            end
          }.should raise_error(Weebl::NotAvailable)
          
          mongo_pair.startup
          collection = mongo_pair.master_connection.db('test')['test_set']
          collection.find_one.should be_nil
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
      
      after do
        mongo_pair.shutdown
        mongo_pair.clean
      end
      
      it "blocks until Mongo comes up" do
        client.with_connection do |conn|
          conn.db('test').should_not be_nil
          @elapsed = Time.now - @start_time
        end
        @elapsed.should > 20
      end
    end
    
    context "when there's Mongo pair up" do
      before do
        mongo_pair.startup
        conn = mongo_pair.master_connection
        @master_connection_port = conn.port
        conn.db('test')['test_set'].insert('hello' => 'world')
      end
      
      after do
        mongo_pair.shutdown
        mongo_pair.clean
      end
      
      it "yields a connection that you can read from" do
        document = client.with_connection do |conn|
          collection = conn.db('test')['test_set']
          collection.find_one
        end
        document['hello'].should == 'world'
      end
      
      context "and Mongo goes down during a block" do
        before do
          @already_shut_down = false
          Helper.ensure_reactor_running
          EM.add_timer(20) { mongo_pair.startup }
        end
        
        it "completes the block once Mongo is back up" do
          client.with_connection do |conn|
            unless @already_shut_down
              mongo_pair.shutdown
              @already_shut_down = true
            end
            conn.db('test')['test_set'].insert('new' => 'doc')
          end
          collection = mongo_pair.master_connection.db('test')['test_set']
          collection.find_one['new'].should == 'doc'
        end
      end
    end
  end
end

