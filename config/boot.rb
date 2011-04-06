# make Dreamhost play nicely with gems
# see http://blog.joeygeiger.com/2010/05/17/i-beat-dreamhost-how-to-really-get-rails-3-bundler-and-dreamhost-working/
if ENV["RAILS_ENV"] == "production"
  # needed for Passenger on Dreamhost
  # but fails for rails console, hence the rescue
  Gem.clear_paths rescue nil
end

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
