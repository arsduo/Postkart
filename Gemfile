source 'http://rubygems.org'

gem 'rails', '~> 3.0'
gem 'rack', '1.2.1'
gem 'slim'
gem 'typhoeus'
gem 'json'
gem 'jquery-rails', '>= 0.2.6'
gem 'jammit'

# offline
gem 'rack-offline'

unless RUBY_VERSION =~ /^1\.9/
  gem 'SystemTimer', '>= 1.2.3'
end

# Authentication
gem "devise", "~> 1.2"

# CoffeeScript
gem "therubyracer"
gem "coffee-script"
gem "barista"

# mongo
gem "mongo", ">= 1.3.0"
gem "mongoid", ">= 2.0.0"
gem "mongo_session_store", :git => "git://github.com/brianhempel/mongo_session_store.git"
gem "bson_ext", ">= 1.2.0"

# error notification
gem 'exception_notification', :require => 'exception_notifier'

# performance!
gem 'rack-perftools_profiler', :require => 'rack/perftools_profiler'
gem 'ruby-prof'

group :test do
  # test content
  gem "rspec", "~> 2.5.0"
  gem "rspec-rails"
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
  
  # javascript
  gem "jasmine"
end