defmodule BoldTranscriptsExTest do
  use ExUnit.Case

  doctest BoldTranscriptsEx

  require Logger

  @deepgram_transcript_path "test/support/data/deepgram_bold-demo.json"
  @assemblyai_transcript_path "test/support/data/assemblyai_bold-demo_transcript.json"

  defp load_json_from_file(path), do: File.read!(path)

  describe "AssemblyAI Transcripts" do
    setup do
      transcript = load_json_from_file(@assemblyai_transcript_path)
      {:ok, transcript: transcript}
    end

    test "converts transcript to Bold format", %{transcript: transcript} do
      {:ok, result} = BoldTranscriptsEx.Convert.from(:assemblyai, transcript)

      assert is_map(result)
      assert Map.has_key?(result, "metadata")
      assert Map.has_key?(result, "utterances")

      # Check metadata structure
      assert is_map(result["metadata"])
      assert Map.has_key?(result["metadata"], "duration")
      assert Map.has_key?(result["metadata"], "language")
      assert Map.has_key?(result["metadata"], "source_url")
      assert Map.has_key?(result["metadata"], "speakers")

      # Check utterances structure
      assert is_list(result["utterances"])

      if length(result["utterances"]) > 0 do
        utterance = List.first(result["utterances"])
        assert Map.has_key?(utterance, "start")
        assert Map.has_key?(utterance, "end")
        assert Map.has_key?(utterance, "confidence")
        assert Map.has_key?(utterance, "text")
      end

      # Check paragraphs structure
    end

    test "converts transcript without paragraphs and sentences", %{transcript: transcript} do
      {:ok, result} = BoldTranscriptsEx.Convert.from(:assemblyai, transcript)

      assert is_map(result)
      assert Map.has_key?(result, "metadata")
      assert Map.has_key?(result, "utterances")

      # Check metadata structure
      assert is_map(result["metadata"])
      assert result["metadata"]["duration"] == 118
      assert result["metadata"]["language"] == "en"
      assert result["metadata"]["source_url"] =~ "bold-eu1-uploads"
      assert result["metadata"]["speakers"] == %{"A" => nil}

      # Check utterances structure
      assert is_list(result["utterances"])
      assert length(result["utterances"]) == 1
      [utterance] = result["utterances"]
      assert utterance["start"] == 0.8
      assert utterance["end"] == 114.16
      assert String.starts_with?(utterance["text"], "Hey, let me ask you something")
      assert utterance["speaker"] == "A"
      assert utterance["confidence"] == 0.96773636
    end
  end

  describe "Deepgram Transcripts" do
    # test "fails without language option" do
    #   transcript = load_json_from_file(@deepgram_transcript_path)
    #   assert {:error, _} = BoldTranscriptsEx.Convert.from(:deepgram, transcript)
    # end

    # test "fails with invalid language option" do
    #   transcript = load_json_from_file(@deepgram_transcript_path)
    #   assert {:error, _} = BoldTranscriptsEx.Convert.from(:deepgram, transcript, language: nil)
    # end

    test "verifies speaker diarization" do
      transcript = load_json_from_file(@deepgram_transcript_path)
      {:ok, result} = BoldTranscriptsEx.Convert.from(:deepgram, transcript, language: "en")

      assert result["metadata"]["speakers"] == %{"A" => nil}
      assert length(result["utterances"]) == 16
      [utterance | _] = result["utterances"]
      assert utterance["speaker"] == "A"
    end
  end
end
