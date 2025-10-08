defmodule BoldTranscriptsEx.Convert.AssemblyAITest do
  use ExUnit.Case

  alias BoldTranscriptsEx.Convert.AssemblyAI

  @transcript_file "test/support/data/bold_demo_assembly_transcript.json"

  describe "transcript_to_bold/2" do
    test "converts v2 transcript with all data" do
      transcript = File.read!(@transcript_file)

      {:ok, result} = AssemblyAI.transcript_to_bold(transcript, version: 2)

      assert result["metadata"]["duration"] == 118.0
      assert result["metadata"]["language"] == "en_us"
      assert result["metadata"]["source_url"] == "https://example.com/audio.mp3"
      assert result["metadata"]["speakers"] == %{"A" => nil}

      assert length(result["utterances"]) == 1
      [utterance] = result["utterances"]
      assert utterance["start"] == 0.92
      assert utterance["end"] == 114.105
      assert String.starts_with?(utterance["text"], "Hey, let me ask you something")
      assert utterance["speaker"] == "A"
      assert utterance["confidence"] == 0.9498449
    end
  end
end
