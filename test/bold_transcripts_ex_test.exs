defmodule BoldTranscriptsExTest do
  use ExUnit.Case

  doctest BoldTranscriptsEx

  require Logger

  defp load_json_from_file(path), do: File.read!(path)

  describe "AssemblyAI Transcripts" do
    test "chapters to WebVTT" do
      input = load_json_from_file("test/support/data/assembly_transcript_ig.json")

      {:ok, vtt} = BoldTranscriptsEx.Convert.chapters_to_webvtt(:assemblyai, input)

      assert String.starts_with?(vtt, "WEBVTT\n\n1\n00")
    end

    test "chapters to WebVTT without chapters" do
      input = load_json_from_file("test/support/data/assembly_transcript_ig_nil_chapters.json")

      assert {:error, _reason} = BoldTranscriptsEx.Convert.chapters_to_webvtt(:assemblyai, input)
    end
  end
end
