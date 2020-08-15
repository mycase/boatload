# frozen_string_literal: true

require_relative 'lib/boatload/version'

Gem::Specification.new do |spec|
  spec.name          = 'boatload'
  spec.version       = Boatload::VERSION
  spec.authors       = ['Collin Styles']
  spec.email         = ['collingstyles@gmail.com']

  spec.summary       = 'A library for processing batches of work asynchronously'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/appfolio/boatload'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  # spec.metadata["allowed_push_host"] = "TODO: AppFolio gem server?"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/appfolio/boatload'
  # spec.metadata["changelog_uri"] = 'https://github.com/appfolio/boatload/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'mocha', '~> 1.11'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.88.0'
  spec.add_development_dependency 'shoulda-context', '~> 2.0'
  spec.add_development_dependency 'yard'
end
