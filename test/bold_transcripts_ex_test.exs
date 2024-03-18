defmodule BoldTranscriptsExTest do
  alias BoldTranscriptsEx.WebVTT
  use ExUnit.Case
  doctest BoldTranscriptsEx

  require Logger

  defp load_json_from_file(path) do
    path
    |> File.read!()

    # |> Jason.decode!()
  end

  # describe "Bold Transcripts to WebVTT" do
  #   test "greets the world" do
  #     input = load_json_from_file("test/support/data/bold_transcript_howard.json") |> IO.inspect()
  #
  #     vtt = BoldTranscriptsEx.WebVTT2.create(input)
  #
  #     Logger.info(inspect(vtt))
  #
  #     assert match?({:ok, _}, vtt)
  #   end
  # end

  describe "AssemblyAI Transcripts" do
    test "chapters to WebVTT" do
      input = load_json_from_file("test/support/data/assembly_transcript_hackathon.json")

      {:ok, vtt} = BoldTranscriptsEx.Convert.chapters_to_webvtt(:assemblyai, input)

      Logger.info(inspect(vtt))

      assert String.starts_with?(vtt, "WEBVTT\n\n1\n00:00:00.000 --> ")
    end
  end
end
