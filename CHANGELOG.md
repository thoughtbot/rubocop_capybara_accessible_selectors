## [Unreleased]

## [0.1.0] - 2026-10-20

- Initial release
- Add `CapybaraAccessibleSelectors/PreferAccessibleSelector` cop, which flags raw CSS selectors in Capybara calls (`find`, `within`, `have_css`, `assert_selector`, …) that have a [capybara_accessible_selectors](https://github.com/citizensadvice/capybara_accessible_selectors) equivalent.
- Add unsafe autocorrection to `CapybaraAccessibleSelectors/PreferAccessibleSelector` for CSS selectors its semantic selector fully covers (`find("h2")` → `find(:heading, level: 2)`, `find("[data-testid=submit]")` → `find_by_test_id("submit")`).
- Add opt-in `CapybaraAccessibleSelectors/NonAccessibleSelector` cop (disabled by default), which flags any CSS, XPath, id or class locator in Capybara calls. It defers to `PreferAccessibleSelector` for selectors that cop already reports.
- `CapybaraAccessibleSelectors/PreferAccessibleSelector` suggests `:role, "cell"` for `td` and no longer autocorrects `td`, `th` or `svg`, whose roles depend on their context.
- `CapybaraAccessibleSelectors/PreferAccessibleSelector` no longer autocorrects negated assertions (`have_no_css`, `assert_no_selector`, `expect(…).not_to`, …).
- `CapybaraAccessibleSelectors/PreferAccessibleSelector` autocorrects an `aria-label` into the accessible name locator (`find("[role=region][aria-label=Comments]")` → `find(:region, "Comments", exact: true)`), and a literal `text:` into the locator for selectors named by their content (`assert_selector "h1", text: "Acme"` → `assert_selector :heading, "Acme", level: 1`).
- Add `CheckElementAttributes` to `CapybaraAccessibleSelectors/NonAccessibleSelector` (off by default), which flags the `:element` selector located by `id:`, `class:` or a `data-*` attribute.
