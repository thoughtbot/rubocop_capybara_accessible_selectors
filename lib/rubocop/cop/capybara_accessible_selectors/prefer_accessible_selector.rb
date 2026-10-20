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
      # This cop does not autocorrect: the accessible name to locate by can't
      # be inferred from the CSS selector.
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
      # @example TestIdAttribute: data-testid (default)
      #   # bad
      #   find("[data-testid=submit]")
      #
      #   # good
      #   find_by_test_id("submit")
      class PreferAccessibleSelector < Base
        MSG = "Prefer `%<suggestion>s` (capybara_accessible_selectors `:%<selector>s`%<hint>s) " \
              "over CSS selector `%<css>s`."

        RESTRICT_ON_SEND = %i[
          find find_all all first within within_element
          has_css? has_no_css? has_selector? has_no_selector?
          have_css have_no_css have_selector have_no_selector
          assert_selector assert_no_selector refute_selector
        ].freeze

        HEADING_TAGS = %w[h1 h2 h3 h4 h5 h6].freeze

        # Ordered most-specific first; the first matching rule wins.
        RULES = [
          { selector: :modal, roles: %w[dialog alertdialog], with: { "aria-modal" => "true" } },
          { selector: :dialog, tags: %w[dialog], roles: %w[dialog alertdialog] },
          { selector: :heading, tags: HEADING_TAGS, roles: %w[heading] },
          { selector: :alert, roles: %w[alert] },
          { selector: :article, tags: %w[article], roles: %w[article] },
          { selector: :banner, tags: %w[header], roles: %w[banner] },
          { selector: :contentinfo, tags: %w[footer], roles: %w[contentinfo] },
          { selector: :main, tags: %w[main], roles: %w[main] },
          { selector: :navigation, tags: %w[nav], roles: %w[navigation] },
          { selector: :region, roles: %w[region] },
          { selector: :section, tags: %w[section aside] },
          { selector: :disclosure, tags: %w[details] },
          { selector: :disclosure_button, tags: %w[summary] },
          { selector: :grid, roles: %w[grid] },
          { selector: :columnheader, tags: %w[th], roles: %w[columnheader] },
          { selector: :gridcell, tags: %w[td], roles: %w[gridcell] },
          { selector: :row, tags: %w[tr], roles: %w[row] },
          { selector: :image, tags: %w[img svg], roles: %w[img image] },
          { selector: :menu, roles: %w[menu] },
          { selector: :menuitem, roles: %w[menuitem] },
          { selector: :tab_panel, roles: %w[tabpanel] },
          { selector: :tab_button, roles: %w[tab] },
          { selector: :combo_box, roles: %w[combobox] },
          { selector: :rich_text, attributes: %w[contenteditable] },
          { selector: :item, attributes: %w[itemprop] },
          { selector: :item_type, attributes: %w[itemtype] }
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

            selector = accessible_selector(subject)
            next unless selector

            add_offense(css_node, message: message(node.method_name, selector, subject, css_node))
          end
        end
        alias on_csend on_send

        private

        def accessible_selector(subject)
          rule = RULES.find { |candidate| subject.match?(**candidate.except(:selector)) }
          return rule[:selector] if rule
          return :test_id if subject.attribute?(test_id_attribute)

          :role unless subject.role.to_s.empty?
        end

        def message(method_name, selector, subject, css_node)
          format(MSG, suggestion: suggestion(method_name, selector), selector: selector,
                      hint: hint(selector, subject), css: css_node.source)
        end

        def suggestion(method_name, selector)
          return "find_by_test_id" if method_name == :find && selector == :test_id

          prefix, shortcuts = SHORTCUTS[method_name]
          return "#{prefix}_#{selector}" if shortcuts&.include?(selector)

          "#{SELECTOR_METHODS.fetch(method_name, method_name)}(:#{selector}, …)"
        end

        def hint(selector, subject)
          return "" unless selector == :heading && HEADING_TAGS.include?(subject.tag)

          ", `level: #{subject.tag.delete_prefix("h")}`"
        end

        def test_id_attribute
          cop_config.fetch("TestIdAttribute", "data-testid").downcase
        end
      end
    end
  end
end
