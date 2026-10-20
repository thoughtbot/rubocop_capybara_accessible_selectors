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

The plugin ships one cop, `CapybaraAccessibleSelectors/PreferAccessibleSelector`. It inspects `find`, `find_all`, `all`, `first`, `within`, `within_element`, `has_css?`, `has_no_css?`, `has_selector?`, `has_no_selector?`, `have_css`, `have_no_css`, `have_selector`, `have_no_selector`, `assert_selector`, `assert_no_selector` and `refute_selector`. When a call's CSS selector has a semantic equivalent, the cop reports it:

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

The cop doesn't autocorrect, because the accessible name to locate by can't be worked out from the CSS selector.

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
| `th`, `[role=columnheader]` | `:columnheader` |
| `td`, `[role=gridcell]` | `:gridcell` |
| `tr`, `[role=row]` | `:row` |
| `img`, `svg`, `[role=img]`, `[role=image]` | `:image` |
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `bundle exec rake` to run the specs and RuboCop. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thoughtbot/rubocop_capybara_accessible_selectors. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/thoughtbot/rubocop_capybara_accessible_selectors/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rubocop_capybara_accessible_selectors project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/thoughtbot/rubocop_capybara_accessible_selectors/blob/main/CODE_OF_CONDUCT.md).
