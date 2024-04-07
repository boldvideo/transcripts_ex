defmodule BoldTranscriptsEx.Convert do
  require Logger

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
end
