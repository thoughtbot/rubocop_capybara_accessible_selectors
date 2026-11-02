# frozen_string_literal: true

RSpec.describe RuboCop::Cop::CapybaraAccessibleSelectors::PreferAccessibleSelector, :config do
  # Annotates each line's first string literal as an offense, abbreviating the message.
  def annotate(source)
    source.each_line.map do |line|
      literal = line.match(/"(?:[^"\\]|\\.)*"/)
      "#{line}#{" " * literal.begin(0)}#{"^" * literal[0].length} Prefer [...]\n"
    end.join
  end

  describe "selector mapping" do
    {
      "[role=dialog][aria-modal=true]" => :modal,
      "[role='alertdialog'][aria-modal='true']" => :modal,
      "dialog" => :dialog,
      "[role=dialog]" => :dialog,
      "[role=alertdialog]" => :dialog,
      "[role=heading]" => :heading,
      "[role=alert]" => :alert,
      "article" => :article,
      "[role=article]" => :article,
      "header" => :banner,
      "[role=banner]" => :banner,
      "footer" => :contentinfo,
      "[role=contentinfo]" => :contentinfo,
      "main" => :main,
      "[role=main]" => :main,
      "nav" => :navigation,
      "[role=navigation]" => :navigation,
      "[role=region]" => :region,
      "section" => :section,
      "aside" => :section,
      "details" => :disclosure,
      "summary" => :disclosure_button,
      "[role=grid]" => :grid,
      "th" => :columnheader,
      "[role=columnheader]" => :columnheader,
      "td" => :gridcell,
      "[role=gridcell]" => :gridcell,
      "tr" => :row,
      "[role=row]" => :row,
      "img" => :image,
      "svg" => :image,
      "[role=img]" => :image,
      "[role=image]" => :image,
      "[role=menu]" => :menu,
      "[role=menuitem]" => :menuitem,
      "[role=tabpanel]" => :tab_panel,
      "[role=tab]" => :tab_button,
      "[role=combobox]" => :combo_box,
      "[contenteditable]" => :rich_text,
      "[itemprop=name]" => :item,
      "[itemtype]" => :item_type,
      "[data-testid=submit]" => :test_id,
      "[role=switch]" => :role
    }.each do |css, selector|
      it "flags #{css.inspect} as :#{selector}" do
        literal = css.inspect

        expect_offense(<<~RUBY)
          all(#{literal})
              #{"^" * literal.length} Prefer `all(:#{selector}, …)` (capybara_accessible_selectors `:#{selector}`) over CSS selector `#{literal}`.
        RUBY
      end
    end

    it "mentions the level for h1-h6" do
      expect_offense(<<~RUBY)
        find("h3")
             ^^^^ Prefer `find(:heading, …)` (capybara_accessible_selectors `:heading`, `level: 3`) over CSS selector `"h3"`.
      RUBY
    end

    it "prefers :modal over :dialog when aria-modal is true" do
      expect_offense(<<~RUBY)
        find("[aria-modal=true][role=dialog]")
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `find(:modal, …)` (capybara_accessible_selectors `:modal`) over CSS selector `"[aria-modal=true][role=dialog]"`.
        find("[role=dialog][aria-modal=false]")
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `find(:dialog, …)` (capybara_accessible_selectors `:dialog`) over CSS selector `"[role=dialog][aria-modal=false]"`.
      RUBY
    end

    it "allows classes, ids and pseudo-classes on the subject" do
      expect_offense(<<~RUBY)
        find("h1.title#main:first-child")
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `find(:heading, …)` (capybara_accessible_selectors `:heading`, `level: 1`) over CSS selector `"h1.title#main:first-child"`.
      RUBY
    end

    it "uses the subject of a complex selector" do
      expect_offense(<<~RUBY)
        find(".card h2")
             ^^^^^^^^^^ Prefer `find(:heading, …)` (capybara_accessible_selectors `:heading`, `level: 2`) over CSS selector `".card h2"`.
        find("main > nav")
             ^^^^^^^^^^^^ Prefer `find(:navigation, …)` (capybara_accessible_selectors `:navigation`) over CSS selector `"main > nav"`.
      RUBY
    end

    it "flags an explicit :css selector type" do
      expect_offense(<<~RUBY)
        find(:css, "nav")
                   ^^^^^ Prefer `find(:navigation, …)` (capybara_accessible_selectors `:navigation`) over CSS selector `"nav"`.
      RUBY
    end

    it "flags calls with a receiver or safe navigation" do
      expect_offense(<<~RUBY)
        page.find("nav")
                  ^^^^^ Prefer `find(:navigation, …)` (capybara_accessible_selectors `:navigation`) over CSS selector `"nav"`.
        element&.find("nav")
                      ^^^^^ Prefer `find(:navigation, …)` (capybara_accessible_selectors `:navigation`) over CSS selector `"nav"`.
      RUBY
    end
  end

  describe "method-specific suggestions" do
    it "suggests have_ shortcuts" do
      expect_offense(<<~RUBY)
        expect(page).to have_css("h2", text: "Welcome")
                                 ^^^^ Prefer `have_heading` (capybara_accessible_selectors `:heading`, `level: 2`) over CSS selector `"h2"`.
        expect(page).to have_selector("[role=dialog][aria-modal=true]")
                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `have_modal` (capybara_accessible_selectors `:modal`) over CSS selector `"[role=dialog][aria-modal=true]"`.
      RUBY
    end

    it "suggests have_no_ shortcuts" do
      expect_offense(<<~RUBY)
        expect(page).to have_no_css("[role=alert]")
                                    ^^^^^^^^^^^^^^ Prefer `have_no_alert` (capybara_accessible_selectors `:alert`) over CSS selector `"[role=alert]"`.
        expect(page).to have_no_selector("nav")
                                         ^^^^^ Prefer `have_no_navigation` (capybara_accessible_selectors `:navigation`) over CSS selector `"nav"`.
      RUBY
    end

    it "falls back to have_selector when there is no shortcut" do
      expect_offense(<<~RUBY)
        expect(page).to have_css("img")
                                 ^^^^^ Prefer `have_selector(:image, …)` (capybara_accessible_selectors `:image`) over CSS selector `"img"`.
        expect(page).to have_no_css("dialog")
                                    ^^^^^^^^ Prefer `have_no_selector(:dialog, …)` (capybara_accessible_selectors `:dialog`) over CSS selector `"dialog"`.
      RUBY
    end

    it "suggests within_ shortcuts" do
      expect_offense(<<~RUBY)
        within("dialog") { click_button "OK" }
               ^^^^^^^^ Prefer `within_dialog` (capybara_accessible_selectors `:dialog`) over CSS selector `"dialog"`.
        within("section") { click_button "OK" }
               ^^^^^^^^^ Prefer `within_section` (capybara_accessible_selectors `:section`) over CSS selector `"section"`.
      RUBY
    end

    it "falls back to within(:name) when there is no shortcut" do
      expect_offense(<<~RUBY)
        within("nav") { click_link "Home" }
               ^^^^^ Prefer `within(:navigation, …)` (capybara_accessible_selectors `:navigation`) over CSS selector `"nav"`.
      RUBY
    end

    it "suggests find_by_test_id for find" do
      expect_offense(<<~RUBY)
        find("[data-testid='submit']")
             ^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `find_by_test_id` (capybara_accessible_selectors `:test_id`) over CSS selector `"[data-testid='submit']"`.
      RUBY
    end

    it "suggests the selector-type predicate for has_css?" do
      expect_offense(<<~RUBY)
        page.has_css?("nav")
                      ^^^^^ Prefer `has_selector?(:navigation, …)` (capybara_accessible_selectors `:navigation`) over CSS selector `"nav"`.
        page.has_no_css?("nav")
                         ^^^^^ Prefer `has_no_selector?(:navigation, …)` (capybara_accessible_selectors `:navigation`) over CSS selector `"nav"`.
      RUBY
    end

    it "keeps the method name for other methods" do
      expect_offense(<<~RUBY)
        assert_selector("footer")
                        ^^^^^^^^ Prefer `assert_selector(:contentinfo, …)` (capybara_accessible_selectors `:contentinfo`) over CSS selector `"footer"`.
        within_element("main") {}
                       ^^^^^^ Prefer `within_element(:main, …)` (capybara_accessible_selectors `:main`) over CSS selector `"main"`.
      RUBY
    end
  end

  describe "autocorrection" do
    {
      'find("h2")' => "find(:heading, level: 2)",
      'find("[role=heading]")' => "find(:heading)",
      'find("[role=dialog][aria-modal=true]")' => "find(:modal)",
      'find("nav[role=navigation]")' => "find(:navigation)",
      'find(:css, "nav")' => "find(:navigation)",
      'page.find("nav").click' => "page.find(:navigation).click",
      'element&.first("tr")' => "element&.first(:row)",
      'all("[role=switch]")' => 'all(:role, "switch")',
      "all(\"[itemprop='name']\")" => 'all(:item, "name")',
      'find("[data-testid=submit]")' => 'find_by_test_id("submit")',
      'find(:css, "[data-testid=submit]")' => 'find_by_test_id("submit")',
      'expect(page).to have_css("[data-testid=submit]")' => 'expect(page).to have_selector(:test_id, "submit")',
      'expect(page).to have_css("h2", text: "Welcome")' => 'expect(page).to have_heading(level: 2, text: "Welcome")',
      'expect(page).to have_selector("[role=alert]")' => "expect(page).to have_alert",
      'expect(page).to have_no_css "nav"' => "expect(page).to have_no_navigation",
      'expect(page).to have_css("nav", count: 2)' => "expect(page).to have_navigation(count: 2)",
      'expect(page).to have_css("img")' => "expect(page).to have_selector(:image)",
      'page.has_no_css?("h1", wait: 0)' => "page.has_no_selector?(:heading, level: 1, wait: 0)",
      'assert_selector("footer")' => "assert_selector(:contentinfo)",
      'within("dialog") { click_button "OK" }' => 'within_dialog { click_button "OK" }',
      'within("[role=tabpanel]", &block)' => "within_tab_panel(&block)",
      'within("nav") { click_link "Home" }' => 'within(:navigation) { click_link "Home" }'
    }.each do |source, corrected|
      it "corrects #{source}" do
        expect_offense(annotate("#{source}\n"))

        expect_correction("#{corrected}\n")
      end
    end

    it "does not correct selectors the semantic selector doesn't fully cover" do
      expect_offense(annotate(<<~RUBY))
        find(".card h2")
        find("h2.title")
        find("#main nav")
        find("nav:first-child")
        find("div[role=dialog]")
        find("h2[role=button]")
        find("h2[aria-level=3]")
        find("[role=dialog][aria-modal=false]")
        find("[role=region][aria-label=Comments]")
        find("[role='switch button']")
        find("button[data-testid=submit]")
        find("[data-testid=submit][role=switch]")
        find("[data-testid]")
        find("[itemprop]")
        find("[itemtype=Person]")
        find("[contenteditable]")
      RUBY

      expect_no_corrections
    end

    it "does not correct headings when level: can't be added" do
      expect_offense(annotate(<<~RUBY))
        find("h2", level: 3)
        find("h2", { text: "Welcome" })
        find("h2", *options)
      RUBY

      expect_no_corrections
    end
  end

  context "with a custom TestIdAttribute" do
    let(:cop_config) { { "TestIdAttribute" => "data-test" } }

    it "flags the configured attribute" do
      expect_offense(<<~RUBY)
        find("[data-test=submit]")
             ^^^^^^^^^^^^^^^^^^^^ Prefer `find_by_test_id` (capybara_accessible_selectors `:test_id`) over CSS selector `"[data-test=submit]"`.
      RUBY
    end

    it "does not flag the default attribute" do
      expect_no_offenses(<<~RUBY)
        find("[data-testid=submit]")
      RUBY
    end
  end

  describe "no offenses" do
    it "ignores semantic selectors" do
      expect_no_offenses(<<~RUBY)
        find(:heading, "Welcome")
        expect(page).to have_heading("Welcome", level: 2)
        within(:navigation, "Main") {}
      RUBY
    end

    it "ignores XPath" do
      expect_no_offenses(<<~RUBY)
        find(:xpath, "//h2")
        find(:xpath, "nav")
      RUBY
    end

    it "ignores CSS without a semantic equivalent" do
      expect_no_offenses(<<~RUBY)
        find(".btn")
        find("#sidebar")
        find("a")
        find("div")
        find("[role]")
        find("[role^=dia]")
        find("div:not([role=dialog])")
        find("h2 .subtitle")
      RUBY
    end

    it "ignores selector lists" do
      expect_no_offenses(<<~RUBY)
        find("h1, h2")
      RUBY
    end

    it "ignores interpolated strings and variables" do
      expect_no_offenses(<<~'RUBY')
        find("h#{level}")
        find(selector)
        find(:css, selector)
      RUBY
    end

    it "ignores methods it does not inspect" do
      expect_no_offenses(<<~RUBY)
        click_on("nav")
        User.where("main")
      RUBY
    end
  end
end
