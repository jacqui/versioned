require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
 
begin
  require 'jeweler'
  Jeweler::Tasks.new do |g|
    g.name = 'mrkut-versioned'
    g.summary = %(Versioning for MongoMapper)
    g.description = %(Versioning for MongoMapper)
    g.email = 'mrkurt@gmail.com'
    g.homepage = 'http://github.com/mrkurt/versioned'
    g.authors = %w(twoism toastyapps jacqui mrkurt)
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com'
end
 
Rake::TestTask.new do |t|
  t.libs = %w(test)
  t.pattern = 'test/**/*_test.rb'
end
 
task :default => :test
