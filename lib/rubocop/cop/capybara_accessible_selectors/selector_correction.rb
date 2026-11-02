# frozen_string_literal: true

module RuboCop
  module Cop
    module CapybaraAccessibleSelectors
      # Rewrites the CSS selector of a Capybara call to a semantic selector.
      #
      # Only CSS that the semantic selector fully covers is rewritten, so
      # nothing the CSS constrained is silently dropped:
      #
      #   find("h2")                    # => find(:heading, level: 2)
      #   find("[data-testid=submit]")  # => find_by_test_id("submit")
      #   find(".card h2")              # not corrected, the ancestor would be lost
      #   find("h2.title")              # not corrected, the class would be lost
      class SelectorCorrection
        # Selectors that match too differently from their CSS to be swapped in.
        UNCORRECTABLE = %i[rich_text item_type].freeze

        # Selectors whose locator is the value of an attribute (`:test_id` uses the configured attribute).
        LOCATOR_ATTRIBUTES = { role: "role", item: "itemprop" }.freeze

        def initialize(node, selector, subject, test_id_attribute:)
          @node = node
          @selector = selector
          @subject = subject
          @rule = PreferAccessibleSelector::RULES.find { |rule| rule[:selector] == selector } || {}
          @locator_attribute = selector == :test_id ? test_id_attribute : LOCATOR_ATTRIBUTES[selector]
          @selector_arguments = node.arguments.take(node.first_argument.sym_type? ? 2 : 1)
          @rest = node.arguments.drop(@selector_arguments.size)
        end

        # Rewrites the call to `method_name`; a shortcut method implies the selector type.
        def call(corrector, method_name, shortcut)
          return unless correctable?

          corrector.replace(node.loc.selector, method_name.to_s) unless method_name == node.method_name
          replace_arguments(corrector, arguments(shortcut))
        end

        private

        attr_reader :node, :selector, :subject, :rule, :locator_attribute, :selector_arguments, :rest

        def correctable?
          return false if UNCORRECTABLE.include?(selector) || !subject.simple?

          tag_covered? && attributes_covered? && arguments_inferable?
        end

        def arguments_inferable?
          (locator_attribute.nil? || !locator.nil?) && (level.nil? || accepts_level?)
        end

        def tag_covered?
          subject.tag.nil? || rule.fetch(:tags, []).include?(subject.tag)
        end

        def attributes_covered?
          (subject.attributes.keys - covered_attributes).empty?
        end

        def covered_attributes
          role = "role" if rule.fetch(:roles, []).include?(subject.role)
          [locator_attribute, role, *rule[:attributes], *rule.fetch(:with, {}).keys]
        end

        def locator
          value = subject.attributes[locator_attribute] if locator_attribute
          return if value.nil? || value.empty?
          return if selector != :test_id && value.match?(/\s/)

          value
        end

        def level
          subject.heading_level if selector == :heading
        end

        # `level:` can only be added before keyword arguments, and only when
        # the call doesn't set a level already.
        def accepts_level?
          options = rest.reject(&:block_pass_type?)
          options.empty? || (options.one? && keywords_without_level?(options.first))
        end

        def keywords_without_level?(options)
          options.hash_type? && !options.braces? && options.keys.none? { |key| key.sym_type? && key.value == :level }
        end

        def arguments(shortcut)
          [(":#{selector}" unless shortcut), locator&.inspect, ("level: #{level}" if level)].compact
        end

        def replace_arguments(corrector, arguments)
          if arguments.empty?
            corrector.remove(removal_range)
          else
            corrector.replace(selector_range, arguments.join(", "))
          end
        end

        def selector_range
          selector_arguments.first.source_range.join(selector_arguments.last.source_range)
        end

        # The selector and its separator, or the whole argument list when there's nothing else.
        def removal_range
          return node.loc.selector.end.join(node.source_range.end) if rest.empty?

          selector_range.join(rest.first.source_range.begin)
        end
      end
    end
  end
end
