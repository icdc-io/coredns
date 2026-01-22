# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "coredns"
  spec.version       = CoreDns::VERSION
  spec.authors       = ["Aliaksei Hrechushkin"]
  spec.email         = ["ahrechushkin@ibagoup.eu"]

  spec.summary       = "Wrapper for coredns-etcd application"
  spec.description   = "Gem which provide simple way to control DNS records."
  spec.homepage      = "https://icdc.io"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7")
  spec.licenses = ["Apache-2.0"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/icdc-io/coredns"
  spec.metadata["changelog_uri"] = "https://github.com/icdc-io/coredns"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "simpleidn", "~> 0.2.3"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
