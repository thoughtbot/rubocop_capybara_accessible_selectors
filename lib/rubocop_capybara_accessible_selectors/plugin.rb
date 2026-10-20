# frozen_string_literal: true

require "lint_roller"

module RubocopCapybaraAccessibleSelectors
  # Registers the cops and their default configuration with RuboCop.
  class Plugin < LintRoller::Plugin
    def about
      LintRoller::About.new(
        name: "rubocop_capybara_accessible_selectors",
        version: VERSION,
        homepage: "https://github.com/thoughtbot/rubocop_capybara_accessible_selectors",
        description: "Prefer capybara_accessible_selectors semantic selectors over raw CSS in Capybara tests."
      )
    end

    def supported?(context)
      context.engine == :rubocop
    end

    def rules(_context)
      LintRoller::Rules.new(
        type: :path,
        config_format: :rubocop,
        value: Pathname.new(__dir__).join("../../config/default.yml")
      )
    end
  end
end
