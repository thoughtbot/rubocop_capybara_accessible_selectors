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
      #   find("[role=region][aria-label=Comments]")
      #                                 # => find(:region, "Comments", exact: true)
      #   find("h2", text: "Welcome")   # => find(:heading, "Welcome", level: 2)
      #   find(".card h2")              # not corrected, the ancestor would be lost
      #   find("h2.title")              # not corrected, the class would be lost
      class SelectorCorrection
        # Selectors that match too differently from their CSS to be swapped in.
        UNCORRECTABLE = %i[rich_text item_type].freeze

        # Selectors whose locator is the value of an attribute (`:test_id` uses the configured attribute).
        LOCATOR_ATTRIBUTES = { role: "role", item: "itemprop" }.freeze

        def initialize(node, rule, subject, test_id_attribute:)
          @node = node
          @rule = rule
          @selector = rule[:selector]
          @subject = subject
          @locator_attribute = selector == :test_id ? test_id_attribute : LOCATOR_ATTRIBUTES[selector]
          @selector_arguments = node.arguments.take(node.first_argument.sym_type? ? 2 : 1)
          @after_selector = node.arguments.drop(@selector_arguments.size)
          @rest = @after_selector.reject(&:block_pass_type?)
        end

        # Rewrites the call to `method_name`; a shortcut method implies the selector type.
        def call(corrector, method_name, shortcut)
          return unless correctable?

          corrector.replace(node.loc.selector, method_name.to_s) unless method_name == node.method_name
          replace_arguments(corrector, arguments(shortcut))
        end

        private

        attr_reader :node, :rule, :selector, :subject, :locator_attribute, :selector_arguments, :after_selector, :rest

        def correctable?
          return false if UNCORRECTABLE.include?(selector) || !rule.fetch(:correctable, true) || !subject.simple?

          tag_covered? && attributes_covered? && arguments_inferable?
        end

        def arguments_inferable?
          (locator_attribute.nil? || !locator.nil?) &&
            (level.nil? || editable_options?(:level)) &&
            (label.nil? || editable_options?(:exact))
        end

        def tag_covered?
          subject.tag.nil? || rule.fetch(:tags, []).include?(subject.tag)
        end

        def attributes_covered?
          (subject.attributes.keys - covered_attributes).empty?
        end

        def covered_attributes
          role = "role" if rule.fetch(:roles, []).include?(subject.role)
          label_attribute = "aria-label" if label
          [locator_attribute, role, label_attribute, *rule[:attributes], *rule.fetch(:with, {}).keys]
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

        def label
          AccessibleName.label(selector, subject)
        end

        def name
          return @name if defined?(@name)

          @name =
            if label
              AccessibleName.from_label(label)
            elsif editable_options?(:exact)
              AccessibleName.from_text(selector, options)
            end
        end

        # The keyword options hash after the selector, when it's the only other argument.
        def options
          options = rest.first
          options if rest.one? && options.hash_type? && !options.braces?
        end

        # Options can be added before keyword arguments, but not before other arguments,
        # a double splat that might set them already, or the options themselves.
        def editable_options?(*keys)
          return true if rest.empty?

          return false if options.nil? || !options.children.all?(&:pair_type?)

          keys.none? { |key| AccessibleName.option(options, key) }
        end

        def arguments(shortcut)
          [
            (":#{selector}" unless shortcut), locator&.inspect, name&.source, ("level: #{level}" if level),
            *kept_options, ("exact: true" if name&.exact)
          ].compact
        end

        # The option pairs that stay when the options are rewritten along with the selector.
        def kept_options
          return [] unless rewrite_options?

          options.pairs.reject { |pair| name.replaces?(pair) }.map(&:source)
        end

        def rewrite_options?
          !name.nil? && !options.nil?
        end

        def replace_arguments(corrector, arguments)
          if arguments.empty?
            corrector.remove(removal_range)
          else
            corrector.replace(arguments_range, arguments.join(", "))
          end
        end

        def arguments_range
          rewrite_options? ? selector_range.join(options.source_range) : selector_range
        end

        def selector_range
          selector_arguments.first.source_range.join(selector_arguments.last.source_range)
        end

        # The selector and its separator, or the whole argument list when there's nothing else.
        def removal_range
          return node.loc.selector.end.join(node.source_range.end) if after_selector.empty?

          selector_range.join(after_selector.first.source_range.begin)
        end
      end
    end
  end
end
