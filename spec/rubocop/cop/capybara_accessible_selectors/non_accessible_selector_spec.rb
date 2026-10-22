# frozen_string_literal: true

RSpec.describe RuboCop::Cop::CapybaraAccessibleSelectors::NonAccessibleSelector, :config do
  def message(kind, source)
    "Avoid #{kind} locator `#{source}`; locate elements by role and accessible name " \
      "with capybara_accessible_selectors instead."
  end

  {
    'within("#comment-field") {}' => ["CSS", '"#comment-field"'],
    'find(".btn")' => ["CSS", '".btn"'],
    'find("a")' => ["CSS", '"a"'],
    'find("#c-#{id}")' => ["CSS", '"#c-#{id}"'], # rubocop:disable Lint/InterpolationCheck
    "find(:css, sel)" => %w[CSS sel],
    'find(:id, "x")' => ["id", '"x"'],
    'find(:class, "btn")' => ["class", '"btn"'],
    'find(:xpath, "//div")' => ["XPath", '"//div"'],
    'have_xpath("//li")' => ["XPath", '"//li"'],
    "have_css(sel)" => %w[CSS sel],
    'find_by_id("x")' => ["id", '"x"'],
    'assert_css(".x")' => ["CSS", '".x"'],
    'refute_xpath("//li")' => ["XPath", '"//li"'],
    'page.find(".btn")' => ["CSS", '".btn"'],
    'element&.find(".btn")' => ["CSS", '".btn"'],
    'expect(page).to have_no_css(".spinner")' => ["CSS", '".spinner"']
  }.each do |source, (kind, locator)|
    it "flags #{source}" do
      column = source.index(locator)

      expect_offense(<<~RUBY)
        #{source}
        #{" " * column}#{"^" * locator.length} #{message(kind, locator)}
      RUBY
    end
  end

  it "does not flag semantic selectors" do
    expect_no_offenses(<<~RUBY)
      find(:heading, "Hi")
      within(:navigation, "Main") {}
      expect(page).to have_selector(:link, "Home")
    RUBY
  end

  it "does not flag variables passed to methods that accept any selector type" do
    expect_no_offenses(<<~RUBY)
      find(sel)
      within(element) {}
    RUBY
  end

  it "does not flag non-Capybara methods" do
    expect_no_offenses(<<~RUBY)
      click_on("#x")
      items.first(2)
    RUBY
  end

  context "when PreferAccessibleSelector is disabled" do
    let(:other_cops) { { "CapybaraAccessibleSelectors/PreferAccessibleSelector" => { "Enabled" => false } } }

    it "flags selectors with a semantic equivalent" do
      expect_offense(<<~RUBY)
        find("nav")
             ^^^^^ #{message("CSS", '"nav"')}
      RUBY
    end
  end

  context "when PreferAccessibleSelector is enabled" do
    let(:prefer_config) { { "Enabled" => true } }
    let(:other_cops) { { "CapybaraAccessibleSelectors/PreferAccessibleSelector" => prefer_config } }

    it "defers selectors with a semantic equivalent" do
      expect_no_offenses(<<~RUBY)
        find("nav")
        find(:css, "h2")
        find("[data-testid=x]")
        expect(page).to have_css("[role=alert]")
      RUBY
    end

    it "still flags selectors without a semantic equivalent" do
      expect_offense(<<~RUBY)
        find("#comment-field")
             ^^^^^^^^^^^^^^^^ #{message("CSS", '"#comment-field"')}
      RUBY
    end

    it "still flags methods PreferAccessibleSelector does not inspect" do
      expect_offense(<<~RUBY)
        assert_css("nav")
                   ^^^^^ #{message("CSS", '"nav"')}
      RUBY
    end

    it "still flags interpolated selectors" do
      expect_offense(<<~'RUBY')
        find("nav#{suffix}")
             ^^^^^^^^^^^^^^ Avoid CSS locator `"nav#{suffix}"`; locate elements by role and accessible name with capybara_accessible_selectors instead.
      RUBY
    end

    context "with a custom TestIdAttribute" do
      let(:prefer_config) { { "Enabled" => true, "TestIdAttribute" => "data-test" } }

      it "follows PreferAccessibleSelector's attribute" do
        expect_offense(<<~RUBY)
          find("[data-test=x]")
          find("[data-testid=x]")
               ^^^^^^^^^^^^^^^^^ #{message("CSS", '"[data-testid=x]"')}
        RUBY
      end
    end
  end
end
