defmodule BoldTranscriptsEx.Convert.DeepgramTest do
  use ExUnit.Case

  alias BoldTranscriptsEx.Convert.Deepgram

  @transcript_file "test/support/data/deepgram_bold-demo.json"

  describe "transcript_to_bold/2" do
    test "converts v2 transcript with all data" do
      transcript = File.read!(@transcript_file)

      {:ok, result} = Deepgram.transcript_to_bold(transcript, language: "en", version: 2)

      assert result["metadata"]["duration"] == 117.85469
      assert result["metadata"]["language"] == "en_us"
      assert result["metadata"]["source_vendor"] == "deepgram"
      assert result["metadata"]["speakers"] == %{"A" => nil}

      assert length(result["utterances"]) == 16
      [utterance | _] = result["utterances"]
      assert utterance["start"] == 0.64
      assert utterance["end"] == 7.46
      assert utterance["speaker"] == "A"
      assert utterance["confidence"] == 0.97229946
    end
  end
end
