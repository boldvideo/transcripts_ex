defmodule BoldTranscriptsEx.Convert do
  require Logger

  alias BoldTranscriptsEx.Convert.Common
  alias BoldTranscriptsEx.Convert.AssemblyAI
  alias BoldTranscriptsEx.Convert.Deepgram
  alias BoldTranscriptsEx.Utils

  @doc """
  Converts a transcript from a specific service to Bold format.

  ## Parameters

  - `service`: The service that generated the transcript (e.g., `:assemblyai`, `:deepgram`)
  - `transcript_data`: The JSON string or decoded map of the transcript data
  - `opts`: Options for the conversion:
    - `:language`: (required for Deepgram) The language code of the transcript (e.g., "en", "lt")
    - Other service-specific options

  ## Returns

  - `{:ok, data}`: A tuple with `:ok` atom and the data in Bold Transcript format
  - `{:error, reason}`: If the conversion fails or required options are missing
  """
  def from(service, transcript_data, opts \\ [])

  def from(:assemblyai, transcript_json, opts) do
    transcript_json
    |> Utils.maybe_decode()
    |> AssemblyAI.transcript_to_bold(opts)
  end

  def from(:deepgram, transcript_json, opts) do
    transcript_json
    |> Utils.maybe_decode()
    |> Deepgram.transcript_to_bold(opts)
  end

  def from(service, _transcript_data, _opts) do
    Logger.error("Conversion from #{service} is not implemented yet.")
  end

  def chapters_to_webvtt(service, _transcript_json, _opts \\ [])

  def chapters_to_webvtt(:assemblyai, transcript_json, opts) do
    transcript_json
    |> Utils.maybe_decode()
    |> AssemblyAI.chapters_to_webvtt(opts)
  end

  def chapters_to_webvtt(service, _transcript_json, _opts) do
    Logger.error("Conversion from #{service} is not implemented yet.")
  end

  @doc """
  Converts a text with one chapter per row into a WebVTT file.

  ## Example

      iex> Convert.text_to_chapters_webvtt(\"""
      ...> 00:00 Hello World
      ...> 01:59 The End
      ...> \""", 155)
      "WEBVTT\\n\\n1\\n00:00:00.000 --> 00:01:59.000\\nHello World\\n\\n2\\n00:01:59.000 --> 00:02:35.000\\nThe End\\n\\n"

  """
  def text_to_chapters_webvtt(input, total_duration) do
    Common.text_to_chapters_webvtt(input, total_duration)
  end

  @doc """
  Converts a chapters WebVTT file to a text with one chapter per line and a short timestamp.

  ## Example

      iex> Convert.chapters_webvtt_to_text(\"""
      ...> WEBVTT
      ...>
      ...> 1
      ...> 00:00:00.000 --> 00:00:37.000
      ...> Hello World
      ...>
      ...> 2
      ...> 00:00:37.000 --> 00:01:59.000
      ...> Introduction
      ...> \""")
      "00:00 Hello World\\n00:37 Introduction"

  """
  def chapters_webvtt_to_text(input) do
    Common.chapters_webvtt_to_text(input)
  end
end
