require File.expand_path('../config/application', __FILE__)

Timetracker::Application.load_tasks

if defined?(RSpec)
  task(:spec).clear

  desc 'Run specs excluding elasticsearch'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '--tag "~search"'
  end

  desc 'Run all specs'
  RSpec::Core::RakeTask.new(:all)
end

task(:default).clear
task default: :all
