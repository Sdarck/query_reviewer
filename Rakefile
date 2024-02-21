require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

desc 'Default: run tests.'
task default: :test

desc 'Test the query_reviewer plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the query_reviewer plugin.'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'QueryReviewer'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
