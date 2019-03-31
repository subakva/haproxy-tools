#!/usr/bin/env rake

require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "yard"
YARD::Rake::YardocTask.new

require "standard/rake"

begin
  require "cane/rake_task"

  desc "Run cane to check quality metrics"
  Cane::RakeTask.new(:cane) do |cane|
    cane.no_abc = true
    cane.no_style = true
    cane.gte = {"coverage/.last_run.json" => 95}
  end
rescue LoadError
  warn "cane not available, quality task not provided."
end

task default: [:spec, :standard, :cane]
