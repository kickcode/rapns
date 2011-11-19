ENV['RAILS_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'bundler'
Bundler.require(:default)

require 'shoulda'

require 'rapns'
require 'rapns/daemon'

Spec::Runner.configure do |config|
  config.before(:all) do
    Mongoid.configure do |config|
      config.master = Mongo::Connection.new.db("rapns-test")
    end
  end
end
