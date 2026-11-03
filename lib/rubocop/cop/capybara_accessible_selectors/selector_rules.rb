# frozen_string_literal: true

module RuboCop
  module Cop
    module CapybaraAccessibleSelectors
      # Maps a parsed CSS subject to the capybara_accessible_selectors selector
      # that replaces it.
      #
      #   SelectorRules.for(CssSubject.parse("h2"), "data-testid")[:selector]  # => :heading
      module SelectorRules
        HEADING_TAGS = %w[h1 h2 h3 h4 h5 h6].freeze

        # Ordered most-specific first; the first matching rule wins. A rule with
        # `correctable: false` is reported but never autocorrected, and its
        # `hint` is added to the message.
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
          { selector: :columnheader, roles: %w[columnheader] },
          # A `th` is a row header when its row also has `td`s.
          { selector: :columnheader, tags: %w[th], correctable: false,
            hint: '; `:role, "rowheader"` for row headers' },
          { selector: :gridcell, roles: %w[gridcell] },
          # A `td` only has the gridcell role inside `role=grid`; in a plain table it's a cell.
          { selector: :role, tags: %w[td], correctable: false,
            hint: ', `"cell"`; `:gridcell` inside `role=grid`' },
          { selector: :row, tags: %w[tr], roles: %w[row] },
          { selector: :image, tags: %w[img], roles: %w[img image] },
          # Icons hidden with `aria-hidden` have no image role.
          { selector: :image, tags: %w[svg], correctable: false },
          { selector: :menu, roles: %w[menu] },
          { selector: :menuitem, roles: %w[menuitem] },
          { selector: :tab_panel, roles: %w[tabpanel] },
          { selector: :tab_button, roles: %w[tab] },
          { selector: :combo_box, roles: %w[combobox] },
          { selector: :rich_text, attributes: %w[contenteditable] },
          { selector: :item, attributes: %w[itemprop] },
          { selector: :item_type, attributes: %w[itemtype] }
        ].freeze

        TEST_ID_RULE = { selector: :test_id }.freeze
        ROLE_RULE = { selector: :role }.freeze

        # The rule for a parsed CSS subject's semantic selector, or nil when there is none.
        def self.for(subject, test_id_attribute)
          rule = RULES.find { |candidate| subject.match?(**candidate.slice(:tags, :roles, :attributes, :with)) }
          return rule if rule
          return TEST_ID_RULE if subject.attribute?(test_id_attribute)

          ROLE_RULE unless subject.role.to_s.empty?
        end
      end
    end
  end
end
