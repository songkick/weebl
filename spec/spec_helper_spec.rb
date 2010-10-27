require 'spec_helper'

describe 'spec_helper' do
  before do
    @mongo = Helper::MongoPair.new(:left => 7000, :right => 7001)
    @mongo.startup
  end
  
  after do
    @mongo.shutdown
  end
  
  describe "Mongo.stable_connection" do
    it "returns a Mongo::Connection" do
      Weebl::Mongo.stable_connection(HOSTS).should be_kind_of(::Mongo::Connection)
    end
    
    it "lets you save documents" do
      connection = Weebl::Mongo.stable_connection(HOSTS)
      connection.db('test')['test_set'].insert(:hello => 'world')
    end
    
    context "with a document in the database" do
      before do
        connection = Weebl::Mongo.stable_connection(HOSTS)
        connection.db('test')['test_set'].insert(:hello => 'world')
      end
      
      it "lets you retrieve a document from the database" do
        connection = Weebl::Mongo.stable_connection(HOSTS)
        connection.db('test')['test_set'].find_one['hello'].should == 'world'
      end
    end
  end
end

