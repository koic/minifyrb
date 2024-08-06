# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'
require_relative 'minifier'

# Provides a custom rake task.
#
# require 'minifyrb/rake_task'
# Minifyrb::RakeTask.new
#
module Minifyrb
  class RakeTask < ::Rake::TaskLib
    def initialize(name = :minifyrb, *, &)
      super()

      desc 'Minify Ruby files in the current directory and subdirectories' unless ::Rake.application.last_description
      task(name) do
        RakeFileUtils.verbose(verbose) do
          run_minify_ruby(verbose)
        end
      end
    end

    private

    def run_minify_ruby(verbose)
      require_relative '../minifyrb'

      puts 'Running Minify Ruby...' if verbose
      Dir['**/*.rb'].each { |ruby_filepath|
        code = File.read(ruby_filepath)
        minified_code = Minifyrb::Minifier.new(code, filepath: ruby_filepath).minify

        File.write(ruby_filepath, minified_code)
      }
    end
  end
end
