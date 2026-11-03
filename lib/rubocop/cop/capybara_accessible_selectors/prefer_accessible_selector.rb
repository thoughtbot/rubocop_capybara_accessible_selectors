# frozen_string_literal: true

module RuboCop
  module Cop
    module CapybaraAccessibleSelectors
      # Checks for Capybara calls that locate elements with a raw CSS selector
      # when a semantic selector from capybara_accessible_selectors exists.
      #
      # Semantic selectors match elements the way assistive technology sees
      # them (role, accessible name, level, state), so tests double as
      # accessibility checks and break less often when markup changes.
      #
      # Only the subject of the selector is inspected, so `".card h2"` is
      # treated like `"h2"`. Selector lists, interpolated strings, variables
      # and XPath are ignored.
      #
      # Autocorrection is unsafe and only happens when the whole CSS selector
      # is a tag name and attributes that the semantic selector fully covers,
      # like `"h2"`, `"[role=dialog][aria-modal=true]"` or
      # `"[data-testid=submit]"`. The accessible name can't be inferred, so it
      # is left for you to add. Semantic selectors also match elements the CSS
      # didn't (`:navigation` matches `[role=navigation]` as well as `nav`),
      # which can make a `find` ambiguous.
      #
      # Elements whose role depends on their context (`td`, `th`, `svg`) are
      # reported but never corrected.
      #
      # @example
      #   # bad
      #   find("h2")
      #   expect(page).to have_css("[role=dialog][aria-modal=true]")
      #   within("nav") { click_link "Home" }
      #
      #   # good
      #   find(:heading, "Welcome", level: 2)
      #   expect(page).to have_modal("Confirm")
      #   within(:navigation, "Main") { click_link "Home" }
      #
      #   # autocorrected
      #   find(:heading, level: 2)
      #   expect(page).to have_modal
      #   within(:navigation) { click_link "Home" }
      #
      # @example TestIdAttribute: data-testid (default)
      #   # bad
      #   find("[data-testid=submit]")
      #
      #   # good
      #   find_by_test_id("submit")
      class PreferAccessibleSelector < Base
        extend AutoCorrector

        MSG = "Prefer `%<suggestion>s` (capybara_accessible_selectors `:%<selector>s`%<hint>s) " \
              "over CSS selector `%<css>s`."

        RESTRICT_ON_SEND = %i[
          find find_all all first within within_element
          has_css? has_no_css? has_selector? has_no_selector?
          have_css have_no_css have_selector have_no_selector
          assert_selector assert_no_selector refute_selector
        ].freeze

        # Selectors with a `have_<name>` / `have_no_<name>` matcher shortcut.
        HAVE_SHORTCUTS = %i[
          alert article banner columnheader combo_box contentinfo disclosure
          disclosure_button grid gridcell heading item main modal navigation
          region row section tab_panel tab_button
        ].freeze

        # Selectors with a `within_<name>` shortcut.
        WITHIN_SHORTCUTS = %i[dialog modal section disclosure tab_panel rich_text].freeze

        # Calling method => [shortcut prefix, selectors that have the shortcut].
        SHORTCUTS = {
          have_css: ["have", HAVE_SHORTCUTS],
          have_selector: ["have", HAVE_SHORTCUTS],
          have_no_css: ["have_no", HAVE_SHORTCUTS],
          have_no_selector: ["have_no", HAVE_SHORTCUTS],
          within: ["within", WITHIN_SHORTCUTS]
        }.freeze

        # CSS-only methods and their selector-type equivalents.
        SELECTOR_METHODS = {
          has_css?: :has_selector?,
          has_no_css?: :has_no_selector?,
          have_css: :have_selector,
          have_no_css: :have_no_selector
        }.freeze

        # @!method css_selector(node)
        def_node_matcher :css_selector, <<~PATTERN
          {(call _ _ (sym :css) $str ...) (call _ _ $str ...)}
        PATTERN

        def on_send(node)
          css_selector(node) do |css_node|
            subject = CssSubject.parse(css_node.value)
            next unless subject

            rule = SelectorRules.for(subject, test_id_attribute)
            next unless rule

            add_offense(css_node, message: message(node.method_name, rule, subject, css_node)) do |corrector|
              autocorrect(corrector, node, rule, subject)
            end
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, node, rule, subject)
          SelectorCorrection.new(node, rule, subject, test_id_attribute:)
                            .call(corrector, *replacement_method(node.method_name, rule[:selector]))
        end

        def message(method_name, rule, subject, css_node)
          selector = rule[:selector]
          format(MSG, suggestion: suggestion(method_name, selector), selector: selector,
                      hint: hint(rule, subject), css: css_node.source)
        end

        def suggestion(method_name, selector)
          replacement, shortcut = replacement_method(method_name, selector)
          shortcut ? replacement.to_s : "#{replacement}(:#{selector}, …)"
        end

        # The method to call instead, and whether it already implies the selector.
        def replacement_method(method_name, selector)
          return [:find_by_test_id, true] if method_name == :find && selector == :test_id

          prefix, shortcuts = SHORTCUTS[method_name]
          return [:"#{prefix}_#{selector}", true] if shortcuts&.include?(selector)

          [SELECTOR_METHODS.fetch(method_name, method_name), false]
        end

        def hint(rule, subject)
          level = ", `level: #{subject.heading_level}`" if rule[:selector] == :heading && subject.heading_level
          "#{level}#{rule[:hint]}"
        end

        def test_id_attribute
          cop_config.fetch("TestIdAttribute", "data-testid").downcase
        end
      end
    end
  end
end
