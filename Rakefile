require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

desc "Run specs (default)"
task :default => :spec

Dir["lib/tasks/**/*.rake"].each { |ext| load ext } if defined?(Rake)
