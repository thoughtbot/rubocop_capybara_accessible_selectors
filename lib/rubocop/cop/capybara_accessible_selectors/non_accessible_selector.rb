# frozen_string_literal: true

module RuboCop
  module Cop
    module CapybaraAccessibleSelectors
      # Checks for Capybara calls that locate elements by CSS, XPath, id or
      # class instead of by role and accessible name.
      #
      # This is a stricter companion to `PreferAccessibleSelector`, and is
      # disabled by default. It flags any non-accessible locator, whether or
      # not a semantic equivalent can be inferred from it.
      #
      # When `PreferAccessibleSelector` is enabled and would already flag a
      # CSS selector, this cop stays quiet so each selector gets one offense.
      #
      # Variables passed to methods that accept any selector type
      # (`find(selector)`) are ignored, since their type can't be known.
      #
      # This cop does not autocorrect.
      #
      # @example
      #   # bad
      #   within("#comment-field") { fill_in "Comment", with: "Hi" }
      #   find(".btn").click
      #   find(:xpath, "//nav[@id='main']")
      #   find_by_id("submit")
      #   expect(page).to have_xpath("//a[text()='Home']")
      #
      #   # good
      #   within(:section, "Comments") { fill_in "Comment", with: "Hi" }
      #   click_button "Save"
      #   find(:navigation, "Main")
      #   find_button("Submit")
      #   expect(page).to have_link("Home")
      class NonAccessibleSelector < Base
        MSG = "Avoid %<kind>s locator `%<source>s`; locate elements by role and accessible name " \
              "with capybara_accessible_selectors instead."

        KINDS = { css: "CSS", xpath: "XPath", id: "id", class: "class" }.freeze

        CSS_METHODS = %i[
          has_css? has_no_css? have_css have_no_css
          assert_css assert_no_css refute_css
        ].freeze

        XPATH_METHODS = %i[
          has_xpath? has_no_xpath? have_xpath have_no_xpath
          assert_xpath assert_no_xpath refute_xpath
        ].freeze

        RESTRICT_ON_SEND = (
          PreferAccessibleSelector::RESTRICT_ON_SEND + CSS_METHODS + XPATH_METHODS + %i[find_by_id]
        ).uniq.freeze

        # @!method typed_locator(node)
        def_node_matcher :typed_locator, <<~PATTERN
          (call _ _ (sym ${:css :id :xpath :class}) $_ ...)
        PATTERN

        # @!method string_locator(node)
        def_node_matcher :string_locator, <<~PATTERN
          (call _ _ ${str dstr} ...)
        PATTERN

        def on_send(node)
          kind, locator = locator(node)
          return unless locator
          return if deferred?(node, kind, locator)

          add_offense(locator, message: format(MSG, kind: KINDS.fetch(kind), source: locator.source))
        end
        alias on_csend on_send

        private

        def locator(node)
          typed_locator(node) { |kind, locator| return [kind, locator] }
          return unless node.arguments?
          return [:css, node.first_argument] if CSS_METHODS.include?(node.method_name)
          return [:xpath, node.first_argument] if XPATH_METHODS.include?(node.method_name)
          return [:id, node.first_argument] if node.method?(:find_by_id)

          string_locator(node) { |locator| [:css, locator] }
        end

        # Leaves CSS selectors with a semantic equivalent to PreferAccessibleSelector.
        def deferred?(node, kind, locator)
          return false unless kind == :css && locator.str_type?
          return false unless PreferAccessibleSelector::RESTRICT_ON_SEND.include?(node.method_name)
          return false unless config.cop_enabled?(PreferAccessibleSelector.cop_name)

          subject = CssSubject.parse(locator.value)
          !subject.nil? && !PreferAccessibleSelector.accessible_selector(subject, prefer_test_id_attribute).nil?
        end

        def prefer_test_id_attribute
          config.for_cop(PreferAccessibleSelector.cop_name).fetch("TestIdAttribute", "data-testid").downcase
        end
      end
    end
  end
end
