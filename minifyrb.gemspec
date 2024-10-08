# frozen_string_literal: true

require_relative 'lib/minifyrb/version'

Gem::Specification.new do |spec|
  spec.name = 'minifyrb'
  spec.version = Minifyrb::VERSION
  spec.authors = ['Koichi ITO']
  spec.email = ['koic.ito@gmail.com']

  spec.summary = 'A minifier of Ruby files.'
  spec.description = 'A minifier of Ruby files.'
  spec.homepage = 'http://github.com/koic/minifyrb'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'http://github.com/koic/minifyrb'
  spec.metadata['changelog_uri'] = 'http://github.com/koic/minifyrb/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) {
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r|\Aexe/|) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'prism', '>= 1.0.0'
end
