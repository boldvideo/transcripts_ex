defmodule BoldTranscriptsExTest do
  use ExUnit.Case

  doctest BoldTranscriptsEx

  require Logger

  defp load_json_from_file(path), do: File.read!(path)

  describe "AssemblyAI Transcripts" do
    setup do
      transcript = load_json_from_file("test/support/data/assembly_transcript_ig.json")
      {:ok, transcript: transcript}
    end

    test "converts transcript to Bold format", %{transcript: transcript} do
      {:ok, result} = BoldTranscriptsEx.Convert.from(:assemblyai, transcript)

      assert is_map(result)
      assert Map.has_key?(result, "metadata")
      assert Map.has_key?(result, "utterances")
      assert Map.has_key?(result, "paragraphs")

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
      assert is_list(result["paragraphs"])

      if length(result["paragraphs"]) > 0 do
        paragraph = List.first(result["paragraphs"])
        assert Map.has_key?(paragraph, "start")
        assert Map.has_key?(paragraph, "end")
        assert Map.has_key?(paragraph, "sentences")
      end
    end

    test "chapters to WebVTT", %{transcript: transcript} do
      {:ok, vtt} = BoldTranscriptsEx.Convert.chapters_to_webvtt(:assemblyai, transcript)

      assert String.starts_with?(vtt, "WEBVTT\n\n1\n00")
      assert String.contains?(vtt, " --> ")
    end

    test "chapters to WebVTT without chapters" do
      input = load_json_from_file("test/support/data/assembly_transcript_ig_nil_chapters.json")

      assert {:error, _reason} = BoldTranscriptsEx.Convert.chapters_to_webvtt(:assemblyai, input)
    end
  end

  describe "Deepgram Transcripts" do
    setup do
      transcript =
        load_json_from_file("test/support/data/rolandas_transcript_deepgram_utt_smart_diar.json")

      {:ok, transcript: transcript}
    end

    test "converts transcript to Bold format with language option", %{transcript: transcript} do
      {:ok, result} = BoldTranscriptsEx.Convert.from(:deepgram, transcript, language: "lt")

      assert is_map(result)
      assert Map.has_key?(result, "metadata")
      assert Map.has_key?(result, "utterances")
      assert Map.has_key?(result, "paragraphs")

      # Check metadata structure
      assert is_map(result["metadata"])
      assert Map.has_key?(result["metadata"], "duration")
      assert result["metadata"]["language"] == "lt"
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
        assert Map.has_key?(utterance, "speaker")
      end

      # Check paragraphs structure (should be empty for Deepgram)
      assert result["paragraphs"] == []
    end

    test "fails without language option", %{transcript: transcript} do
      assert {:error, "Language option is required for Deepgram transcripts"} =
               BoldTranscriptsEx.Convert.from(:deepgram, transcript)
    end

    test "fails with invalid language option", %{transcript: transcript} do
      assert {:error, "Language must be a string"} =
               BoldTranscriptsEx.Convert.from(:deepgram, transcript, language: :lt)
    end

    test "verifies speaker diarization", %{transcript: transcript} do
      {:ok, result} = BoldTranscriptsEx.Convert.from(:deepgram, transcript, language: "lt")

      # Check that we have speakers identified
      assert length(result["metadata"]["speakers"]) > 0

      # Check that utterances have speaker labels
      utterance = List.first(result["utterances"])
      assert Map.has_key?(utterance, "speaker")
      assert is_number(utterance["speaker"])
    end
  end
end
