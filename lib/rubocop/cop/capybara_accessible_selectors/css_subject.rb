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

        attr_reader :tag, :attributes

        def self.parse(css)
          return if css.gsub(BRACKETED, "").include?(",")

          compound = css.scan(COMPOUND).last
          new(compound.gsub(PARENTHESIZED, "")) if compound
        end

        def initialize(compound)
          @tag = compound[TAG, 1]&.downcase
          @attributes = compound.scan(ATTRIBUTE).to_h do |name, operator, *values|
            [name.downcase, (values.compact.first if VALUE_OPERATORS.include?(operator))]
          end
        end

        def role
          attributes["role"]
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
