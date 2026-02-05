defmodule BoldTranscriptsEx do
  @moduledoc """
  BoldTranscriptsEx is a library for working with transcripts in the Bold Video platform.

  It provides functionality for:
  - Converting transcripts from various vendors (AssemblyAI, Deepgram, Speechmatics, Mistral) to Bold format
  - Generating WebVTT subtitles from Bold transcripts
  - Working with chapter markers in WebVTT format
  """

  alias BoldTranscriptsEx.{Convert, Utils.Chapters, WebVTT}

  @doc """
  Converts a transcript from a specific service to Bold format.

  ## Parameters

  - `service`: The service that generated the transcript (e.g., `:assemblyai`, `:deepgram`, `:speechmatics`, `:mistral`)
  - `transcript_data`: The JSON string or decoded map of the transcript data
  - `opts`: Options for the conversion:
    - `:language`: (required for Deepgram) The language code of the transcript (e.g., "en", "lt")
    - Other service-specific options

  ## Returns

  - `{:ok, data}`: A tuple with `:ok` atom and the data in Bold Transcript format
  - `{:error, reason}`: If the conversion fails or required options are missing

  ## Examples

      iex> transcript = ~s({"audio_duration": 10.5, "language_code": "en", "audio_url": "https://example.com/audio.mp3", "utterances": []})
      iex> BoldTranscriptsEx.convert(:assemblyai, transcript)
      {:ok, %{
        "metadata" => %{
          "duration" => 10.5,
          "language" => "en_us",
          "source_url" => "https://example.com/audio.mp3",
          "speakers" => %{},
          "source_model" => "",
          "source_vendor" => "assemblyai",
          "source_version" => "",
          "transcription_date" => nil,
          "version" => "2.0"
        },
        "utterances" => []
      }}

  """
  defdelegate convert(service, transcript_data, opts \\ []), to: Convert, as: :from

  @doc """
  Generates WebVTT subtitles from a Bold transcript.

  ## Parameters

  - `transcript`: A Bold transcript in v2 format.

  ## Returns

  A string containing the WebVTT subtitles with speaker labels.
  Speaker labels are only shown for named speakers using the WebVTT <v> tag.
  Single-letter speaker IDs (A, B, C) are not shown.

  ## Examples

      iex> transcript = %{
      ...>   "metadata" => %{"speakers" => %{"A" => "Jack Smith"}},
      ...>   "utterances" => [%{"words" => [%{"start" => 0.8, "end" => 1.2, "word" => "Hello", "speaker" => "A"}], "speaker" => "A"}]
      ...> }
      iex> BoldTranscriptsEx.generate_subtitles(transcript)
      "WEBVTT\\n\\n1\\n00:00:00.800 --> 00:00:01.200\\n<v Jack Smith>Hello</v>"

  """
  defdelegate generate_subtitles(transcript), to: WebVTT

  @doc """
  Parses WebVTT content to extract chapters.

  ## Parameters

  - `webvtt`: The WebVTT content as a string.

  ## Returns

  A list of maps, each containing `:start` and `:title` keys for a chapter.

  ## Examples

      iex> webvtt = "WEBVTT\\n\\n1\\n00:00:03.000 --> 00:00:16.000\\nComing soon: Back to Stanford"
      iex> BoldTranscriptsEx.parse_chapters(webvtt)
      [%{start: "0:03", end: "0:16", title: "Coming soon: Back to Stanford"}]

  """
  defdelegate parse_chapters(webvtt), to: Chapters

  @doc """
  Converts a list of chapters into WebVTT format.

  ## Parameters

  - `chapters`: A list of maps, each containing `:start`, `:end`, and `:title` keys,
    or `:assemblyai` and a transcript map for AssemblyAI format.

  ## Returns

  - When given a list of chapters: A string in WebVTT format
  - When given `:assemblyai` format: `{:ok, string}` or `{:error, reason}`

  ## Examples

      iex> chapters = [%{start: "0:03", end: "0:16", title: "Chapter 1"}]
      iex> BoldTranscriptsEx.chapters_to_webvtt(chapters)
      "WEBVTT\\n\\n1\\n00:00:03.000 --> 00:00:16.000\\nChapter 1"

      iex> transcript = %{"chapters" => [%{"start" => 3000, "end" => 16000, "gist" => "Chapter 1"}]}
      iex> BoldTranscriptsEx.chapters_to_webvtt(:assemblyai, transcript)
      {:ok, "WEBVTT\\n\\n1\\n00:00:03.000 --> 00:00:16.000\\nChapter 1"}

  """
  defdelegate chapters_to_webvtt(chapters), to: Chapters
  defdelegate chapters_to_webvtt(format, transcript), to: Chapters
end
