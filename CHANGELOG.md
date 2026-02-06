# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.0] - 2026-02-06

### Added
- Mistral Voxtral transcript converter (`BoldTranscriptsEx.Convert.Mistral`)
- Support for `:mistral` vendor in `BoldTranscriptsEx.convert/3`
- Mistral-specific language normalization in `Convert.Language`
- GitHub Actions CI (test + format check on push/PR)
- GitHub Actions release automation (auto-publish to hex.pm)
- MIT LICENSE file
- llms.txt for LLM discoverability

### Changed
- Updated package description to include all supported vendors
- Added `source_url` and `homepage_url` to hex.pm package metadata

### Removed
- `lib/test.ex` — development scratch file
- `lib/webvtt2.ex` — unused experimental module

### Fixed
- WebVTT `format_subtitle_time/1` now accepts integer timestamps (required for Mistral)
- Code formatting in `lib/convert/speechmatics.ex`

## [0.7.0] - 2025-10-08

### Added
- Language code normalization during transcript conversion
- New `BoldTranscriptsEx.Convert.Language` module with vendor-specific normalization functions
- Support for BCP-47 format (Deepgram), underscore format (AssemblyAI), and base language codes (Speechmatics)
- Comprehensive test coverage for language normalization

### Changed
- **BREAKING**: Language codes in Bold format metadata are now normalized to internal format (`en_us`, `en_uk`, `de_de`, etc.)
- Deepgram: BCP-47 codes (e.g., `en-US`) are converted to underscore format (`en_us`), with special handling for `en-GB` → `en_uk`
- AssemblyAI: Language codes are normalized and base languages get default regions (e.g., `de` → `de_de`)
- Speechmatics: Base language codes are mapped to default regional variants (e.g., `en` → `en_us`)
- All converters now return normalized language codes in `metadata.language` field

### Fixed
- Language normalization now happens at the library level instead of requiring application-side normalization
- Consistent language code format across all vendor conversions

## [0.6.0] - 2024-12-29

### Added
- Speechmatics integration
- Bold Transcript Format v2.0 support

For releases before 0.6.0, see the [git history](https://github.com/boldvideo/transcripts_ex/commits/main).

[0.8.0]: https://github.com/boldvideo/transcripts_ex/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/boldvideo/transcripts_ex/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/boldvideo/transcripts_ex/compare/v0.5.1...v0.6.0
