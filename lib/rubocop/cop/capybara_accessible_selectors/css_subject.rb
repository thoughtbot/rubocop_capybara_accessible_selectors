# frozen_string_literal: true

module RuboCop
  module Cop
    module CapybaraAccessibleSelectors
      # The subject (rightmost compound) of a CSS selector, reduced to its tag
      # name and attributes. Classes, ids and pseudo-classes are ignored.
      #
      #   CssSubject.parse(".card h2.title")      # tag: "h2"
      #   CssSubject.parse("div[role='dialog']")  # tag: "div", role: "dialog"
      #   CssSubject.parse("h1, h2")              # nil (selector lists are skipped)
      class CssSubject
        BRACKETED = /\[[^\]]*\]|\([^)]*\)/
        COMPOUND = /(?:\[[^\]]*\]|\([^)]*\)|[^\s>+~\[(])+/
        PARENTHESIZED = /\([^)]*\)/
        TAG = /\A(?:[\w-]*\|)?([a-zA-Z][\w-]*)/
        ATTRIBUTE = /
          \[\s*([\w:-]+)\s*
          (?:([~|^$*]?=)\s*(?:"([^"]*)"|'([^']*)'|([^\s\]]+)))?
          \s*(?:[iIsS]\s*)?\]
        /x
        VALUE_OPERATORS = %w[= ~=].freeze
        SIMPLE = /\A(?:[a-zA-Z][\w-]*)?(?:\[[^\]]*\])*\z/

        attr_reader :tag, :attributes

        def self.parse(css)
          return if css.gsub(BRACKETED, "").include?(",")

          compound = css.scan(COMPOUND).last
          new(compound.gsub(PARENTHESIZED, ""), whole: compound == css.strip) if compound
        end

        def initialize(compound, whole: false)
          @tag = compound[TAG, 1]&.downcase
          @attributes = compound.scan(ATTRIBUTE).to_h do |name, operator, *values|
            [name.downcase, (values.compact.first if VALUE_OPERATORS.include?(operator))]
          end
          @simple = whole && compound.match?(SIMPLE) && compound.scan(BRACKETED).size == @attributes.size
        end

        # Whether the whole selector is just a tag name and distinct attributes,
        # with no ancestors, classes, ids or pseudo-classes.
        def simple?
          @simple
        end

        def role
          attributes["role"]
        end

        def heading_level
          tag[1] if tag&.match?(/\Ah[1-6]\z/)
        end

        def attribute?(name)
          attributes.key?(name)
        end

        def match?(tags: [], roles: [], attributes: [], with: {})
          with.all? { |name, value| self.attributes[name] == value } &&
            (tags.include?(tag) || roles.include?(role) || attributes.any? { |name| attribute?(name) })
        end
      end
    end
  end
end
