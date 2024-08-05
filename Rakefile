# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'minifyrb/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Minifyrb::RakeTask.new

task default: %i(rubocop spec)
