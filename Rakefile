
require "rake/testtask"

task :test => ["test:units"]

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.libs << "test"
    t.test_files = FileList["test/unit/*"]
  end
end
