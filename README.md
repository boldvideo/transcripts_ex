# Bold Transcripts

[![Hex.pm](https://img.shields.io/hexpm/v/bold_transcripts_ex.svg)](https://hex.pm/packages/bold_transcripts_ex)
[![Hex.pm](https://img.shields.io/hexpm/dt/bold_transcripts_ex.svg)](https://hex.pm/packages/bold_transcripts_ex)

A simple Elixir library for working with [Bold Video](https://bold.video) transcripts. Convert transcripts from various providers (AssemblyAI, Deepgram, Speechmatics, Mistral) to Bold's unified transcript format, and generate WebVTT subtitles.

## Installation

Add `bold_transcripts_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bold_transcripts_ex, "~> 0.8.0"}
  ]
end
```

## Usage

### Converting Transcripts

Convert transcripts from supported providers to Bold format:

```elixir
# Convert from AssemblyAI
{:ok, bold_transcript} = BoldTranscriptsEx.convert(:assemblyai, assemblyai_json)

# Convert from Deepgram
{:ok, bold_transcript} = BoldTranscriptsEx.convert(:deepgram, deepgram_json, language: "en")

# Convert from Speechmatics
{:ok, bold_transcript} = BoldTranscriptsEx.convert(:speechmatics, speechmatics_json)

# Convert from Mistral (Voxtral)
{:ok, bold_transcript} = BoldTranscriptsEx.convert(:mistral, mistral_json)
```

### Generating Subtitles

Create WebVTT subtitles from a Bold transcript:

```elixir
webvtt = BoldTranscriptsEx.generate_subtitles(bold_transcript)
```

### Working with Chapters

Convert chapters to WebVTT format:

```elixir
# From AssemblyAI transcript
{:ok, chapters_vtt} = BoldTranscriptsEx.chapters_to_webvtt(:assemblyai, transcript)

# From a list of chapters
chapters_vtt = BoldTranscriptsEx.chapters_to_webvtt([
  %{start: "0:00", end: "1:30", title: "Introduction"},
  %{start: "1:30", end: "5:45", title: "Main Content"}
])
```

## Bold Transcript Format

The Bold transcript format is a unified JSON structure that combines metadata and utterances as segments of speech:

```json
{
  "metadata": {
    "version": "2.0",
    "duration": 34.789,
    "language": "en",
    "source_url": "",
    "source_vendor": "assemblyai",
    "source_version": "1.2.3",
    "transcription_date": "2024-12-19T12:00:00Z",
    "speakers": {
      "A": null,
      "B": null
    }
  },
  "utterances": [
    {
      "text": "Hey, how are you?",
      "start": 0.64,
      "end": 1.84,
      "speaker": "A",
      "confidence": 0.98789,
      "words": [
        {
          "word": "Hey,",
          "start": 0.64,
          "end": 0.84,
          "confidence": 0.951
        },
        {
          "word": "how",
          "start": 0.85,
          "end": 1.04,
          "confidence": 0.962
        },
        {
          "word": "are",
          "start": 1.05,
          "end": 1.24,
          "confidence": 0.981
        },
        {
          "word": "you?",
          "start": 1.25,
          "end": 1.84,
          "confidence": 0.99
        }
      ]
    }
  ]
}
```

## Releasing

1. Bump version in `mix.exs`
2. Add entry to `CHANGELOG.md`
3. Commit and push to `main`
4. Create a GitHub Release with tag `vX.Y.Z`
5. GitHub Actions automatically publishes to hex.pm

**Prerequisites:** A `HEX_API_KEY` secret must be configured in the GitHub repository settings. Generate one at [hex.pm/dashboard/keys](https://hex.pm/dashboard/keys) with `api:write` permission.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Links

- [Bold Video](https://bold.video)
- [Documentation](https://hexdocs.pm/bold_transcripts_ex)
- [GitHub](https://github.com/boldvideo/transcripts_ex)
