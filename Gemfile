source 'http://rubygems.org'

gem 'rails', '~> 3.0'
gem 'rack', '1.2.1'
gem 'haml'
gem 'typhoeus'
gem 'json'
gem 'jquery-rails', '>= 0.2.6'
gem 'jammit'

unless RUBY_VERSION =~ /^1\.9/
  gem 'SystemTimer', '>= 1.2.3'
end

# Google
gem "devise", "~> 1.2"

# mongo
gem "mongo", ">= 1.3.0"
gem "mongoid", ">= 2.0.0"
gem "mongo_session_store", :git => "git://github.com/brianhempel/mongo_session_store.git"
gem "bson_ext", ">= 1.2.0"

group :test, :development do
  # test content
  gem "rspec-rails"
end

group :test do
  gem "rspec"
  gem 'machinist', '>= 2.0.0.beta2'
  gem 'machinist_mongo', :git => 'https://github.com/nmerouze/machinist_mongo.git', :require => 'machinist/mongoid', :branch => 'machinist2'
  gem "mocha"
  gem "autotest"
  gem "autotest-rails"
  gem "ZenTest"
  gem "faker"
  gem "remarkable", '>=4.0.0.alpha2' 
  gem 'remarkable_mongoid'
  gem 'remarkable_activemodel', '>=4.0.0.alpha2'  
end