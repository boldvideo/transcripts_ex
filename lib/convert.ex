defmodule BoldTranscriptsEx.Convert do
  require Logger

  def from(service, transcript_data, opts \\ [])

  def from(:assemblyai, transcript_json, opts) do
    BoldTranscriptsEx.Convert.AssemblyAI.transcript_to_bold(transcript_json, opts)
  end

  def from(service, _transcript_data, _opts) do
    Logger.error("Conversion from #{service} is not implemented yet.")
  end

  def chapters_to_webvtt(service, _transcript_json, _opts \\ [])

  def chapters_to_webvtt(:assemblyai, transcript_json, opts) do
    BoldTranscriptsEx.Convert.AssemblyAI.chapters_to_webvtt(transcript_json, opts)
  end

  def chapters_to_webvtt(service, _transcript_json, _opts) do
    Logger.error("Conversion from #{service} is not implemented yet.")
  end
end
