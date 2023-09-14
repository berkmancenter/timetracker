require File.expand_path('../config/application', __FILE__)

Timetracker::Application.load_tasks

if defined?(RSpec)
  task(:spec).clear

  desc 'Run all specs'
  RSpec::Core::RakeTask.new(:all)
end

task(:default).clear
task default: :all
