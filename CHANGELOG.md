## [Unreleased]

## [0.1.0] - 2026-10-20

- Initial release
- Add `CapybaraAccessibleSelectors/PreferAccessibleSelector` cop, which flags raw CSS selectors in Capybara calls (`find`, `within`, `have_css`, `assert_selector`, …) that have a [capybara_accessible_selectors](https://github.com/citizensadvice/capybara_accessible_selectors) equivalent.
- Add opt-in `CapybaraAccessibleSelectors/NonAccessibleSelector` cop (disabled by default), which flags any CSS, XPath, id or class locator in Capybara calls. It defers to `PreferAccessibleSelector` for selectors that cop already reports.
