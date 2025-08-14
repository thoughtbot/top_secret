## [Unreleased]

### Changed
- **BREAKING:** Refactored configuration system to use individual filter accessors instead of nested `default_filters`
- Updated `TopSecret::Text.filter` to accept keyword arguments for filter overrides and `custom_filters` array
- Each default filter now has its own configuration accessor (e.g., `TopSecret.email_filter`, `TopSecret.people_filter`)

### Migration Guide
- Replace `TopSecret.configure { |c| c.default_filters.email_filter = filter }` with `TopSecret.configure { |c| c.email_filter = filter }`
- Replace `TopSecret::Text.filter(text, filters: { email_filter: filter })` with `TopSecret::Text.filter(text, email_filter: filter)`
- For new filters, use `TopSecret::Text.filter(text, custom_filters: [filter])` instead of adding to `default_filters`

## [0.1.1] - 2025-08-08

-   Ensure `TopSecret.min_confidence_score` is respected

## [0.1.0] - 2025-08-08

-   Initial release
