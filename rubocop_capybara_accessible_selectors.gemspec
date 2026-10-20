# frozen_string_literal: true

require_relative "lib/rubocop_capybara_accessible_selectors/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop_capybara_accessible_selectors"
  spec.version = RubocopCapybaraAccessibleSelectors::VERSION
  spec.authors = ["Fernando Perales"]
  spec.email = ["fer@thoughtbot.com"]

  spec.summary = "RuboCop cops that prefer capybara_accessible_selectors over raw CSS selectors."
  spec.description = "A RuboCop plugin that flags Capybara tests locating elements by raw CSS " \
                     '(e.g. `find("h2")`, `within("nav")`) when a semantic selector from ' \
                     "capybara_accessible_selectors (`:heading`, `:navigation`, ...) could be used instead."
  spec.homepage = "https://github.com/thoughtbot/rubocop_capybara_accessible_selectors"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["default_lint_roller_plugin"] = "RubocopCapybaraAccessibleSelectors::Plugin"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore spec/ .github/ .rubocop.yml .rspec])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller", "~> 1.1"
  spec.add_dependency "rubocop", ">= 1.72"
end
