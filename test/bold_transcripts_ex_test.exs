defmodule BoldTranscriptsExTest do
  alias BoldTranscriptsEx.WebVTT
  use ExUnit.Case
  doctest BoldTranscriptsEx

  require Logger

  defp load_json_from_file(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  describe "Bold Transcripts to WebVTT" do
    test "greets the world" do
      input = load_json_from_file("test/support/data/bold_transcript_howard.json") |> IO.inspect()

      vtt = BoldTranscriptsEx.WebVTT2.create(input)

      Logger.info(inspect(vtt))

      assert match?({:ok, _}, vtt)
    end
  end
end
