# frozen_string_literal: true

require "rubocop_capybara_accessible_selectors"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
