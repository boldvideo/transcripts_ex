# BoldTranscriptsEx

A library for converting transcripts from various speech-to-text providers into Bold's unified transcript format. Currently supports:

- AssemblyAI transcripts (including paragraphs, sentences, and chapters)
- Deepgram transcripts (with speaker diarization support)

## Installation

Add `bold_transcripts_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bold_transcripts_ex, "~> 0.4.1"}
  ]
end
```

## Usage

### Converting AssemblyAI Transcripts

```elixir
# Basic conversion
{:ok, bold_transcript} = BoldTranscriptsEx.Convert.from(:assemblyai, transcript_json)

# With paragraphs and sentences data
{:ok, bold_transcript} = BoldTranscriptsEx.Convert.from(:assemblyai, transcript_json,
  paragraphs: paragraphs_json,
  sentences: sentences_json
)

# Converting chapters to WebVTT
{:ok, webvtt} = BoldTranscriptsEx.Convert.chapters_to_webvtt(:assemblyai, transcript_json)
```

### Converting Deepgram Transcripts

```elixir
# Language parameter is required for Deepgram
{:ok, bold_transcript} = BoldTranscriptsEx.Convert.from(:deepgram, transcript_json,
  language: "en"
)
```

## Output Format

The converted transcript follows Bold's unified format:

```elixir
%{
  "metadata" => %{
    "duration" => float(),      # Duration in seconds
    "language" => string(),     # Language code
    "source_url" => string(),   # Original audio URL
    "speakers" => [string()]    # List of speaker identifiers
  },
  "utterances" => [            # List of speech segments
    %{
      "start" => float(),      # Start time in seconds
      "end" => float(),        # End time in seconds
      "text" => string(),      # Transcribed text
      "confidence" => float(), # Confidence score
      "speaker" => string()    # Speaker identifier
    }
  ],
  "paragraphs" => [           # List of paragraphs (AssemblyAI only)
    %{
      "start" => float(),     # Start time in seconds
      "end" => float(),       # End time in seconds
      "sentences" => [        # List of sentences in paragraph
        %{
          "start" => float(),
          "end" => float(),
          "text" => string()
        }
      ]
    }
  ]
}
```

## License

This project is licensed under the MIT License.
