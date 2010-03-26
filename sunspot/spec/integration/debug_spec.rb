require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'debug' do
  describe 'on search' do
    before :all do
      Sunspot.remove_all
      @posts = []
      @posts << Post.new(:title => 'The toast elects the insufficient spirit',
                         :body => 'Does the wind write?')
      @posts << Post.new(:title => 'A nail abbreviates the recovering insight outside the moron',
                         :body => 'The interpreted strain scans the buffer around the upper temper')
      @posts << Post.new(:title => 'The toast abbreviates the recovering spirit',
                         :body => 'Does the wind interpret the buffer, moron?')
      Sunspot.index!(*@posts)
      @comment = Namespaced::Comment.new(:body => 'Hey there where ya goin, not exactly knowin, who says you have to call just one place toast.')
      Sunspot.index!(@comment)
    end

    it 'should return explain' do
      Sunspot.search(Post) do 
	keywords 'toast' 
	debug
      end.hits.first.explain.should_not be_nil
    end
  end

  describe 'on more_like_this' do
    before :all do
      Sunspot.remove_all
      @posts = [
	Post.new(:title => 'Post123', :body => "one two three", :tags => %w(ruby sunspot rsolr)),
	Post.new(:title => 'Post456', :body => "four five six", :tags => %w(ruby solr lucene)),
	Post.new(:title => 'Post234', :body => "two three four", :tags => %w(python sqlalchemy)),
	Post.new(:title => 'Post345', :body => "three four five", :tags => %w(ruby sunspot mat)),
      ]
      Sunspot.index!(@posts)
    end

    it 'should return explain' do
      Sunspot.more_like_this(@posts.first) do
	debug
      end.hits.first.explain.should_not be_nil
    end
  end
end
