# frozen_string_literal: true

require_relative 'lib/homebus-network-activity/version'

Gem::Specification.new do |spec|
  spec.name = 'homebus-network-activity'
  spec.version = HomebusNetworkActivity::VERSION
  spec.authors = ['John Romkey']
  spec.email = ['58883+romkey@users.noreply.github.com']

  spec.summary = 'Homebus command line interface'
  spec.description = 'Command line (shell) interface for Homebus'
  spec.homepage = 'https://github.com/HomeBusProjects/homebus-network-activity'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= #{File.read('.ruby-version')}"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/HomeBusProjects/homebus-network-activity'
#  spec.metadata['changelog_uri'] = 'TODO: Put your gem's CHANGELOG.md URL here.'

  all_files  = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.files = all_files.grep(%r!^(exe|lib|rubocop)/|^.rubocop.yml$!)
  spec.executables   = all_files.grep(%r!^exe/!) { |f| File.basename(f) }
  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency 'example-gem', '~> 1.0'
end
