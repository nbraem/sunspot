require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'debug query' do
  it "should send query to solr with debugQuery on" do
    session.search Post do
      debug true
    end
    connection.should have_last_search_with(:debugQuery => true)
  end

  it "should send debugQuery on if debug is specified" do
    session.search Post do
      debug
    end
    connection.should have_last_search_with(:debugQuery => true)
  end

  it "should not send debugQuery if not specified" do
    session.search Post
    connection.should_not have_last_search_with(:debugQuery => true)
  end

  it "should not send debugQuery if debug is false" do
    session.search Post do
      debug false
    end
    connection.should_not have_last_search_with(:debugQuery => false)
  end
end
