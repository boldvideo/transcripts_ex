defmodule BoldTranscriptsEx.Convert.MistralTest do
  use ExUnit.Case

  alias BoldTranscriptsEx.Convert.Mistral

  @transcript_file "test/support/data/mistral_bold-demo.json"

  describe "transcript_to_bold/2" do
    test "converts multi-speaker transcript" do
      transcript = File.read!(@transcript_file)

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      # Assert metadata
      assert result["metadata"]["version"] == "2.0"
      assert result["metadata"]["duration"] == 42.24
      assert result["metadata"]["language"] == "en_us"
      assert result["metadata"]["source_vendor"] == "mistral"
      assert result["metadata"]["source_model"] == ""
      assert result["metadata"]["source_version"] == ""
      assert result["metadata"]["transcription_date"] == nil
      assert result["metadata"]["speakers"] == %{"A" => nil, "B" => nil}

      # Assert utterances
      assert length(result["utterances"]) == 10

      # First utterance (speaker_0 -> A)
      [utterance | _] = result["utterances"]
      assert utterance["start"] == 0.0
      assert utterance["end"] == 3.84
      assert utterance["speaker"] == "A"
      assert utterance["text"] == "Welcome to the Bold Video demo."
      assert utterance["confidence"] == 1.0

      # Check words
      assert length(utterance["words"]) == 6
      [first_word | _] = utterance["words"]
      assert first_word["word"] == "Welcome"
      assert first_word["start"] == 0.0
      assert first_word["end"] == 0.48
      assert first_word["confidence"] == 1.0

      # Third utterance (speaker_1 -> B)
      third = Enum.at(result["utterances"], 2)
      assert third["speaker"] == "B"
      assert third["text"] == "That sounds great."
    end

    test "handles single-speaker transcript" do
      transcript = %{
        "text" => "Hello world.",
        "segments" => [
          %{
            "id" => 0,
            "start" => 0.0,
            "end" => 2.0,
            "text" => "Hello world.",
            "speaker" => "speaker_0",
            "words" => [
              %{"word" => "Hello", "start" => 0.0, "end" => 0.8},
              %{"word" => "world.", "start" => 1.0, "end" => 2.0}
            ]
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert result["metadata"]["speakers"] == %{"A" => nil}
      assert length(result["utterances"]) == 1
      assert hd(result["utterances"])["speaker"] == "A"
    end

    test "handles missing words array" do
      transcript = %{
        "text" => "Hello.",
        "segments" => [
          %{
            "id" => 0,
            "start" => 0.0,
            "end" => 1.0,
            "text" => "Hello.",
            "speaker" => "speaker_0"
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert length(result["utterances"]) == 1
      utterance = hd(result["utterances"])
      assert utterance["words"] == []
      assert utterance["text"] == "Hello."
    end

    test "handles null words array" do
      transcript = %{
        "text" => "Hello.",
        "segments" => [
          %{
            "id" => 0,
            "start" => 0.0,
            "end" => 1.0,
            "text" => "Hello.",
            "speaker" => "speaker_0",
            "words" => nil
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      utterance = hd(result["utterances"])
      assert utterance["words"] == []
    end

    test "coerces integer timestamps to floats" do
      transcript = %{
        "text" => "Hello world.",
        "segments" => [
          %{
            "id" => 0,
            "start" => 0,
            "end" => 4,
            "text" => "Hello world.",
            "speaker" => "speaker_0",
            "words" => [
              %{"word" => "Hello", "start" => 0, "end" => 2},
              %{"word" => "world.", "start" => 2, "end" => 4}
            ]
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      utterance = hd(result["utterances"])
      assert is_float(utterance["start"])
      assert is_float(utterance["end"])
      assert utterance["start"] == 0.0
      assert utterance["end"] == 4.0

      # Check duration is also float
      assert is_float(result["metadata"]["duration"])
      assert result["metadata"]["duration"] == 4.0

      # Check word timestamps
      first_word = hd(utterance["words"])
      assert is_float(first_word["start"])
      assert is_float(first_word["end"])
    end

    test "defaults confidence to 1.0 when absent" do
      transcript = %{
        "text" => "Hello.",
        "segments" => [
          %{
            "id" => 0,
            "start" => 0.0,
            "end" => 1.0,
            "text" => "Hello.",
            "speaker" => "speaker_0",
            "words" => [
              %{"word" => "Hello.", "start" => 0.0, "end" => 1.0}
            ]
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      utterance = hd(result["utterances"])
      assert utterance["confidence"] == 1.0

      word = hd(utterance["words"])
      assert word["confidence"] == 1.0
    end

    test "handles no speaker key (diarize=false)" do
      transcript = %{
        "text" => "Hello.",
        "segments" => [
          %{
            "id" => 0,
            "start" => 0.0,
            "end" => 1.0,
            "text" => "Hello.",
            "words" => [
              %{"word" => "Hello.", "start" => 0.0, "end" => 1.0}
            ]
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert result["metadata"]["speakers"] == %{}
      utterance = hd(result["utterances"])
      assert utterance["speaker"] == nil
    end

    test "handles empty segments" do
      transcript = %{"text" => "", "segments" => []}

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert result["metadata"]["duration"] == 0.0
      assert result["metadata"]["speakers"] == %{}
      assert result["utterances"] == []
    end

    test "accepts language option" do
      transcript = %{
        "text" => "Hallo.",
        "segments" => [
          %{
            "id" => 0,
            "start" => 0.0,
            "end" => 1.0,
            "text" => "Hallo.",
            "speaker" => "speaker_0",
            "words" => [%{"word" => "Hallo.", "start" => 0.0, "end" => 1.0}]
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript, language: "de")

      assert result["metadata"]["language"] == "de_de"
    end
  end

  describe "integration" do
    test "works through public API dispatch" do
      transcript = File.read!(@transcript_file)

      {:ok, result} = BoldTranscriptsEx.convert(:mistral, transcript)

      assert result["metadata"]["source_vendor"] == "mistral"
      assert length(result["utterances"]) == 10
    end

    test "output produces valid WebVTT" do
      transcript = File.read!(@transcript_file)

      {:ok, bold} = BoldTranscriptsEx.convert(:mistral, transcript)
      webvtt = BoldTranscriptsEx.generate_subtitles(bold)

      assert String.starts_with?(webvtt, "WEBVTT")
      assert String.contains?(webvtt, "-->")
    end
  end
end
