# rubocop_capybara_accessible_selectors

A [RuboCop](https://rubocop.org) plugin that nudges Capybara tests away from raw CSS selectors and towards the semantic selectors provided by [capybara_accessible_selectors](https://github.com/citizensadvice/capybara_accessible_selectors).

Semantic selectors find elements the way assistive technology does (by role, accessible name, level and state). Your tests then check accessibility as a side effect, and they break less often when markup changes.

## Installation

Add the gem to your application's Gemfile:

```ruby
group :development, :test do
  gem "rubocop_capybara_accessible_selectors", require: false
end
```

Then enable the plugin in `.rubocop.yml`:

```yaml
plugins:
  - rubocop_capybara_accessible_selectors
```

This requires RuboCop 1.72 or later.

## Usage

The plugin ships two cops. `CapybaraAccessibleSelectors/PreferAccessibleSelector` is enabled by default. `CapybaraAccessibleSelectors/NonAccessibleSelector` is a stricter, opt-in cop (see [Strict mode](#strict-mode)).

`PreferAccessibleSelector` inspects `find`, `find_all`, `all`, `first`, `within`, `within_element`, `has_css?`, `has_no_css?`, `has_selector?`, `has_no_selector?`, `have_css`, `have_no_css`, `have_selector`, `have_no_selector`, `assert_selector`, `assert_no_selector` and `refute_selector`. When a call's CSS selector has a semantic equivalent, the cop reports it:

```ruby
# bad
find("h2")
expect(page).to have_css("[role=dialog][aria-modal=true]")
within("nav") { click_link "Home" }
find("[data-testid=submit]")

# good
find(:heading, "Welcome", level: 2)
expect(page).to have_modal("Confirm")
within(:navigation, "Main") { click_link "Home" }
find_by_test_id("submit")
```

```
Prefer `have_heading` (capybara_accessible_selectors `:heading`, `level: 2`) over CSS selector `"h2"`.
```

When the gem has a shortcut for the calling method, the message suggests it (`have_heading`, `have_no_alert`, `within_dialog`, `find_by_test_id`). Otherwise it suggests passing the selector type, as in `within(:navigation, …)`.

The cop only looks at the subject of the selector, so `".card h2"` is treated like `"h2"`. Classes, ids and pseudo-classes on the subject are allowed. Selector lists (`"h1, h2"`), interpolated strings, variables, XPath and selectors that are already semantic are ignored.

### Autocorrection

The cop autocorrects selectors that are only a tag name and attributes the semantic selector covers in full. It fills in the selector type, a `level:` for `h1`–`h6`, and a locator when the CSS has one: the test id, the `role` for `:role`, and the `itemprop` for `:item`. It uses the shortcut method when there is one:

```ruby
find("h2", text: "Welcome")              # => find(:heading, level: 2, text: "Welcome")
expect(page).to have_css("[role=alert]") # => expect(page).to have_alert
within("dialog") { click_button "OK" }   # => within_dialog { click_button "OK" }
within("nav") { click_link "Home" }      # => within(:navigation) { click_link "Home" }
find("[data-testid=submit]")             # => find_by_test_id("submit")
all("[role=switch]")                     # => all(:role, "switch")
```

The accessible name can't be worked out from the CSS, so add it yourself after correcting.

The cop leaves a selector alone when correcting it would drop part of it. That covers:

- ancestors (`".card h2"`)
- classes, ids and pseudo-classes (`"h2.title"`)
- a tag or attribute the semantic selector doesn't check (`"div[role=dialog]"`, `"[role=region][aria-label=Comments]"`)
- attributes with no value to use as a locator (`"[data-testid]"`)

It also skips:

- `:rich_text` and `:item_type`
- headings where `level:` can't be added (`find("h2", level: 3)`)
- elements whose role depends on where they are: `td` is a `cell` in a plain table and only a `gridcell` inside `role=grid`, `th` can be a row header, and an `svg` icon hidden with `aria-hidden` isn't an image

The correction is unsafe, so it only runs with `rubocop -A`. Semantic selectors can match elements the CSS didn't: `:navigation` matches `[role=navigation]` as well as `nav`, and `:heading` without a level matches every heading. That can turn a passing `find` into an ambiguous match. Run your tests after correcting.

### Supported mappings

| CSS subject | Selector |
|---|---|
| `[role=dialog]` / `[role=alertdialog]` with `[aria-modal=true]` | `:modal` |
| `dialog`, `[role=dialog]`, `[role=alertdialog]` | `:dialog` |
| `h1`–`h6`, `[role=heading]` | `:heading` |
| `[role=alert]` | `:alert` |
| `article`, `[role=article]` | `:article` |
| `header`, `[role=banner]` | `:banner` |
| `footer`, `[role=contentinfo]` | `:contentinfo` |
| `main`, `[role=main]` | `:main` |
| `nav`, `[role=navigation]` | `:navigation` |
| `[role=region]` | `:region` |
| `section`, `aside` | `:section` |
| `details` | `:disclosure` |
| `summary` | `:disclosure_button` |
| `[role=grid]` | `:grid` |
| `th`, `[role=columnheader]` | `:columnheader` (`th` isn't autocorrected) |
| `[role=gridcell]` | `:gridcell` |
| `td` | `:role, "cell"` (not autocorrected) |
| `tr`, `[role=row]` | `:row` |
| `img`, `svg`, `[role=img]`, `[role=image]` | `:image` (`svg` isn't autocorrected) |
| `[role=menu]` | `:menu` |
| `[role=menuitem]` | `:menuitem` |
| `[role=tabpanel]` | `:tab_panel` |
| `[role=tab]` | `:tab_button` |
| `[role=combobox]` | `:combo_box` |
| `[contenteditable]` | `:rich_text` |
| `[itemprop]` | `:item` |
| `[itemtype]` | `:item_type` |
| `[data-testid]` (configurable) | `:test_id` |
| any other `[role=…]` | `:role` |

### Configuration

```yaml
CapybaraAccessibleSelectors/PreferAccessibleSelector:
  # Files to inspect (defaults shown).
  Include:
    - "**/spec/**/*_spec.rb"
    - "**/test/**/*_test.rb"
    - "**/spec/support/**/*.rb"
  # The attribute your app uses for test ids. Match it to
  # `Capybara.test_id` / capybara_accessible_selectors' configuration.
  TestIdAttribute: data-testid
```

### Strict mode

`CapybaraAccessibleSelectors/NonAccessibleSelector` flags any locator that skips the accessibility tree, whether or not a semantic equivalent can be worked out from it. It's disabled by default. Enable it in `.rubocop.yml`:

```yaml
CapybaraAccessibleSelectors/NonAccessibleSelector:
  Enabled: true
```

It reports:

- CSS strings passed to `find`, `within`, `have_selector` and the other methods `PreferAccessibleSelector` inspects, including interpolated strings: `within("#comment-field")`, `find("#comment-#{id}")`
- locators typed as `:css`, `:id`, `:xpath` or `:class`, even when they're variables: `find(:css, selector)`, `find(:id, "x")`, `all(:xpath, xpath)`
- anything passed to CSS-only and XPath-only methods: `have_css(selector)`, `has_xpath?("//li")`, `assert_css`, `assert_no_css`, `refute_css`, `assert_xpath`, `assert_no_xpath`, `refute_xpath`
- `find_by_id`

```ruby
# bad
within("#comment-field") { fill_in "Comment", with: "Hi" }
find(:xpath, "//nav[@id='main']")
find_by_id("submit")

# good
within(:section, "Comments") { fill_in "Comment", with: "Hi" }
find(:navigation, "Main")
find_button("Submit")
```

```
Avoid CSS locator `"#comment-field"`; locate elements by role and accessible name with capybara_accessible_selectors instead.
```

Variables passed to methods that accept any selector type (`find(selector)`) are ignored, because their type can't be known. The cop doesn't autocorrect.

When `PreferAccessibleSelector` is enabled and would already report a CSS selector (`find("nav")`), `NonAccessibleSelector` stays quiet, so each selector gets one offense with the most specific message. It follows `PreferAccessibleSelector`'s `TestIdAttribute` when deciding this. If you disable `PreferAccessibleSelector`, `NonAccessibleSelector` reports those selectors too.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `bundle exec rake` to run the specs and RuboCop. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thoughtbot/rubocop_capybara_accessible_selectors. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/thoughtbot/rubocop_capybara_accessible_selectors/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rubocop_capybara_accessible_selectors project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/thoughtbot/rubocop_capybara_accessible_selectors/blob/main/CODE_OF_CONDUCT.md).
