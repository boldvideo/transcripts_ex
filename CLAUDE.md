# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BoldTranscriptsEx is an Elixir library for working with transcripts in the Bold Video platform. It converts transcripts from various speech-to-text vendors (AssemblyAI, Deepgram, Speechmatics, Mistral) to a unified Bold format and generates WebVTT subtitles.

## Development Commands

### Testing
```bash
mix test                    # Run all tests
mix test path/to/test.exs  # Run a specific test file
mix test --trace           # Run tests with detailed tracing
```

### Code Quality
```bash
mix format                 # Format all code
mix format --check-formatted  # Check if code is formatted
mix compile                # Compile the project
mix clean                  # Clean compiled files
```

### Documentation
```bash
mix docs                   # Generate documentation (opens in doc/index.html)
```

### Dependencies
```bash
mix deps.get              # Install dependencies
mix deps.update --all     # Update all dependencies
```

## Core Architecture

### Conversion Pipeline

The library follows a conversion pipeline pattern:

1. **Input**: JSON from various vendors → `Utils.maybe_decode/1` (handles both JSON strings and maps)
2. **Conversion**: Vendor format → Bold format via `Convert.from/3`
3. **Output**: Bold format → WebVTT subtitles via `WebVTT.generate_subtitles/1`

### Module Structure

- **`BoldTranscriptsEx`** - Main API module that delegates to specialized modules
- **`Convert`** - Orchestrates conversions from different vendors
  - `Convert.AssemblyAI` - Handles AssemblyAI transcript conversion
  - `Convert.Deepgram` - Handles Deepgram transcript conversion
  - `Convert.Speechmatics` - Handles Speechmatics transcript conversion
  - `Convert.Mistral` - Handles Mistral (Voxtral) transcript conversion
  - `Convert.Language` - Language code normalization across vendors
  - `Convert.Common` - Shared conversion utilities
- **`WebVTT`** - Generates WebVTT subtitles with smart line breaking and speaker labels
- **`Utils.Chapters`** - Parses and generates WebVTT chapter markers

### Bold Transcript Format

The library converts all vendor formats to a unified Bold format v2.0:

```elixir
%{
  "metadata" => %{
    "version" => "2.0",
    "duration" => float,           # Audio duration in seconds
    "language" => string,          # Language code (e.g., "en")
    "source_url" => string,        # Original audio URL
    "source_vendor" => string,     # e.g., "assemblyai", "deepgram"
    "source_version" => string,
    "transcription_date" => string,
    "speakers" => %{               # Speaker ID to name mapping
      "A" => "John Doe"
    }
  },
  "utterances" => [
    %{
      "text" => string,
      "start" => float,            # Start time in seconds
      "end" => float,              # End time in seconds
      "speaker" => string,         # Speaker ID
      "confidence" => float,
      "words" => [                 # Word-level timing
        %{
          "word" => string,
          "start" => float,
          "end" => float,
          "confidence" => float
        }
      ]
    }
  ]
}
```

### WebVTT Generation

The WebVTT module implements smart subtitle generation:
- Max 42 characters per line
- Max 2 lines per subtitle
- Splits at natural pauses (150ms threshold)
- Shows speaker names (not single-letter IDs) using `<v Speaker Name>` tags

### Version Support

Conversions support both Bold format v1 and v2. Version 2 is the default and should be used for all new code. Version is specified via `opts: [version: 2]`.

## Releasing

This package is published on [hex.pm](https://hex.pm/packages/bold_transcripts_ex). Releases are automated via GitHub Actions.

### How to release a new version

1. Bump version in `mix.exs`
2. Add entry to `CHANGELOG.md` (follow Keep a Changelog format)
3. Commit and push to `main`
4. Create a GitHub Release with tag `vX.Y.Z` (e.g., `v0.9.0`)
5. The release workflow automatically runs tests and publishes to hex.pm

### Versioning convention

- New vendor adapter = minor version bump (e.g., 0.8.0 → 0.9.0)
- Bug fixes / small changes = patch bump (e.g., 0.8.0 → 0.8.1)
- Breaking changes = minor bump with BREAKING note in changelog (pre-1.0)

### GitHub secret

The `HEX_API_KEY` repository secret must exist for automated publishing. Generate at https://hex.pm/dashboard/keys with `api:write` and `PKG:bold_transcripts_ex` permissions.

## Adding a New Vendor

To add a new speech-to-text vendor:

1. Create `lib/convert/<vendor>.ex` implementing `transcript_to_bold/1`
2. Add the vendor atom to the `from/3` function in `lib/convert.ex`
3. Add language normalization in `lib/convert/language.ex` if the vendor uses non-standard language codes
4. Add the vendor to `lib/bold_transcripts_ex.ex` moduledoc and `convert/3` doc
5. Create test file `test/convert/<vendor>_test.exs` with fixture data in `test/support/data/`
6. Update README.md, CHANGELOG.md, llms.txt, and mix.exs description

## Testing Conventions

- Test files are in `test/` directory mirroring `lib/` structure
- Test data is in `test/support/data/` with real vendor transcript examples
- Use `doctest` for inline documentation examples
- Use `ExUnit.Case` for integration tests with setup blocks
