defmodule BoldTranscriptsEx.Convert do
  require Logger

  def from(service, transcript_data, opts \\ [])

  def from(:assemblyai, transcript_data, opts) do
    BoldTranscriptsEx.Convert.AssemblyAI.convert(transcript_data, opts)
  end

  def from(service, _transcript_data, _opts) do
    IO.puts("Conversion from #{service} is not supported yet.")
  end
end
