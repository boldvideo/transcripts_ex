defmodule BoldTranscriptsEx.Convert do
  require Logger

  alias BoldTranscriptsEx.Convert.Common
  alias BoldTranscriptsEx.Utils

  def from(service, transcript_data, opts \\ [])

  def from(:assemblyai, transcript_json, opts) do
    transcript_json
    |> Utils.maybe_decode()
    |> BoldTranscriptsEx.Convert.AssemblyAI.transcript_to_bold(opts)
  end

  def from(service, _transcript_data, _opts) do
    Logger.error("Conversion from #{service} is not implemented yet.")
  end

  def chapters_to_webvtt(service, _transcript_json, _opts \\ [])

  def chapters_to_webvtt(:assemblyai, transcript_json, opts) do
    transcript_json
    |> Utils.maybe_decode()
    |> BoldTranscriptsEx.Convert.AssemblyAI.chapters_to_webvtt(opts)
  end

  def chapters_to_webvtt(service, _transcript_json, _opts) do
    Logger.error("Conversion from #{service} is not implemented yet.")
  end

  @doc """
  Converts a text with one chapter per row into a WebVTT file.

  # Example

      iex> text_to_chapters_webvtt("00:00 Hello World\n00:37 Introduction\n01:59 The second part\n")
      "WEBVTT\n\n1\n00:00:00.000 -> 00:00:37.000\nHello World\n\n2\n00:00:37.000 -> 00:01:59.000\nIntroduction\n3\n00:01:59.000 -> 00:"

  """
  defdelegate text_to_chapters_webvtt(input, total_duration), to: Common
end
