require 'spec_helper'
require 'mongo'

describe 'spec_helper' do
  before do
    @mongo = Helper::MongoPair.new(:left => 7000, :right => 7001)
    @mongo.startup
  end
  
  after do
    @mongo.shutdown
  end
  
  describe "MongoPair#master_connection" do
    it "returns a Mongo::Connection" do
      @mongo.master_connection.should be_kind_of(::Mongo::Connection)
    end
    
    it "lets you save documents" do
      connection = @mongo.master_connection
      connection.db('test')['test_set'].insert(:hello => 'world')
    end
    
    context "with a document in the database" do
      before do
        connection = @mongo.master_connection
        connection.db('test')['test_set'].insert(:hello => 'world')
      end
      
      it "lets you retrieve a document from the database" do
        connection = @mongo.master_connection
        connection.db('test')['test_set'].find_one['hello'].should == 'world'
      end
    end
  end
end

