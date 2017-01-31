# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rspec'
end

RSpec::Core::RakeTask.new(:spec_local) do |t|
  t.rspec_opts = '--tag ~live'
end

RSpec::Core::RakeTask.new(:spec_live) do |t|
  t.rspec_opts = '--tag live'
end

task default: :spec
