# These two lines must be first.
require 'coveralls'
Coveralls.wear!('rails')
# Uncomment the following line if you'd like to get an HTML-formatted
# coverage report (`coverage/index.html`) when you run tests on localhost.
# SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.command_name "RSpec/Cucumber:#{Process.pid.to_s}#{ENV['TEST_ENV_NUMBER']}"

ENV['RAILS_ENV'] ||= 'test'

# Prevent things in config/environment from being reloaded if they have
# already been loaded in a previous test. HTTP_ERRORS is chosen at
# random from things initialized in that directory.
unless defined? HTTP_ERRORS
  require File.expand_path('../config/environment', __dir__)
end

require 'rubygems'
require 'rspec/rails'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'

  config.before :each, cache: true do
    allow(Rails).to receive(:cache).and_return(
      ActiveSupport::Cache::MemoryStore.new
    )
  end

  config.after :each, cache: true do
    allow(Rails).to receive(:cache).and_call_original
  end

  config.before :each, file_cache: true do
    allow(Rails).to receive(:cache).and_return(
      ActiveSupport::Cache::FileStore.new 'tmp/test_cache'
    )
  end

  config.after :each, file_cache: true do
    allow(Rails).to receive(:cache).and_call_original
    system('rm -rf tmp/test_cache')
  end
end
