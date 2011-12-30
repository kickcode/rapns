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
    MongoMapper.config = {"test" => {"uri" => "mongodb://localhost/rapns-test"}}
    MongoMapper.connect("test")
    Rapns::Notification.destroy_all
  end
end
