## [Unreleased]

### Added

-   Added automatic caching of MITIE NER model to improve performance by avoiding expensive reinitialization
-   Added `TopSecret::Text.clear_model_cache!` method to clear the cached model when needed

## [0.3.0] - 2025-09-19

### Added

-   Added `TopSecret::Text.scan` method for detecting sensitive information without redacting text
-   Added `TopSecret::Text::ScanResult` class to hold scan operation results with `mapping` and `sensitive?` methods
-   Added `TopSecret::Text::GlobalMapping` class to manage consistent labeling across multiple filtering operations
-   Added factory methods to domain objects: `BatchResult.from_messages`, `Result.from_messages`, and `Result.with_global_labels`
-   Added support for disabling NER filtering by setting `model_path` to `nil` for improved performance and deployment flexibility
-   Added support for Rails 7.0 and newer
-   Added `#safe?` predicate method as the logical opposite of `#sensitive?` for `BatchResult`, `Result` and `ScanResult` classes

### Changed

-   **BREAKING:** `TopSecret::Text.filter_all` now returns `TopSecret::Text::Result` objects instead of `TopSecret::Text::BatchResult::Item` objects for individual items
-   Each item in `BatchResult#items` now includes an individual `mapping` attribute containing only the sensitive information found in that specific message
-   `TopSecret::Text.filter_all` now only processes sensitive results when building global mappings, improving efficiency
-   Refactored `TopSecret::Text.filter_all` to use domain objects with better separation of concerns and testability
-   Improved performance by implementing lazy loading of MITIE model and document processing
-   NER filtering now gracefully falls back when MITIE model is unavailable, continuing with regex-based filters only

## [0.2.0] - 2025-08-18

### Added

-   Added `TopSecret::Text.filter_all` for batch processing multiple messages with globally consistent redaction labels
-   Added `TopSecret::Text::BatchResult` class to hold results from batch operations
-   Added `TopSecret::FilteredText` class for restoring filtered text by substituting placeholders with original values
-   Added `TopSecret::FilteredText::Result` class to track restoration success and failures

### Changed

-   **BREAKING:** Moved `TopSecret::Result` to `TopSecret::Text::Result` and `TopSecret::BatchResult` to `TopSecret::Text::BatchResult` for better namespace organization
-   **BREAKING:** Refactored configuration system to use individual filter accessors instead of nested `default_filters`
-   Updated `TopSecret::Text.filter` to accept keyword arguments for filter overrides and `custom_filters` array
-   Each default filter now has its own configuration accessor (e.g., `TopSecret.email_filter`, `TopSecret.people_filter`)

### Migration Guide

-   Replace `TopSecret::Result` with `TopSecret::Text::Result` and `TopSecret::BatchResult` with `TopSecret::Text::BatchResult`
-   Replace `TopSecret.configure { |c| c.default_filters.email_filter = filter }` with `TopSecret.configure { |c| c.email_filter = filter }`
-   Replace `TopSecret::Text.filter(text, filters: { email_filter: filter })` with `TopSecret::Text.filter(text, email_filter: filter)`
-   For new filters, use `TopSecret::Text.filter(text, custom_filters: [filter])` instead of adding to `default_filters`

## [0.1.1] - 2025-08-08

-   Ensure `TopSecret.min_confidence_score` is respected

## [0.1.0] - 2025-08-08

-   Initial release
