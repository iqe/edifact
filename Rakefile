require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
end

task default: :test

task :build do
  sh "gem build edifact.gemspec"
end

task :clean do
  rm_rf 'edifact-*.gem'
  rm_rf 'pkg'
end