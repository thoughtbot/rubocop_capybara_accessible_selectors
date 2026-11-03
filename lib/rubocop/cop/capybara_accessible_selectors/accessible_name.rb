# frozen_string_literal: true

module RuboCop
  module Cop
    module CapybaraAccessibleSelectors
      # The accessible name a semantic selector can be located by, worked out
      # from an `aria-label` in the CSS or a literal `text:` option.
      #
      #   find("[role=region][aria-label=Comments]")  # => source: "\"Comments\"", exact: true
      #   find("h2", text: "Welcome")                 # => source: "\"Welcome\"", exact: false
      class AccessibleName
        # Selectors whose locator is the accessible name, so an `aria-label` can become the locator.
        NAMED = %i[
          modal dialog heading article banner contentinfo main navigation region grid
          columnheader gridcell row image menu menuitem
        ].freeze

        # Selectors whose accessible name comes from their content, so a `text:` filter can become the locator.
        NAMED_FROM_CONTENT = %i[heading columnheader gridcell row menuitem tab_button disclosure_button].freeze

        # Literal `text:` values that can be used as a locator.
        TEXT_TYPES = %i[str dstr regexp].freeze

        STRING_TYPES = %i[str dstr].freeze

        # The locator's source, whether it must match exactly, and the option pairs it replaces.
        attr_reader :source, :exact, :pairs

        # The `aria-label` value, when the selector's locator is the accessible name.
        def self.label(selector, subject)
          value = subject.attributes["aria-label"] if NAMED.include?(selector)
          value unless value.nil? || value.strip.empty?
        end

        def self.from_label(label)
          new(label.inspect, exact: true)
        end

        # The name from a literal `text:` or `exact_text:` in a keyword options hash.
        def self.from_text(selector, options)
          return unless NAMED_FROM_CONTENT.include?(selector) && options

          text, exact_text = %i[text exact_text].map { |key| option(options, key) }
          if text
            from_text_option(text, exact_text)
          elsif exact_text && STRING_TYPES.include?(exact_text.value.type)
            new(exact_text.value.source, exact: true, pairs: [exact_text])
          end
        end

        def self.from_text_option(text, exact_text)
          return unless TEXT_TYPES.include?(text.value.type)
          # A string `exact_text:` filters on its own, and a boolean one can't be combined with a Regexp.
          return if exact_text && (!exact_text.value.boolean_type? || text.value.regexp_type?)

          new(text.value.source, exact: exact_text&.value&.true_type?, pairs: [text, exact_text].compact)
        end

        # The pair for an option in a keyword options hash.
        def self.option(options, key)
          options.pairs.find { |pair| pair.key.sym_type? && pair.key.value == key }
        end

        private_class_method :new, :from_text_option

        def initialize(source, exact:, pairs: [])
          @source = source
          @exact = exact
          @pairs = pairs
        end

        def replaces?(pair)
          pairs.any? { |replaced| replaced.equal?(pair) }
        end
      end
    end
  end
end
