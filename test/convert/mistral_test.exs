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

  describe "diarized format (speaker_id, no words array)" do
    @diarized_file "test/support/data/mistral_voxtral-diarized.json"

    test "converts diarized transcript with speaker_id" do
      transcript = File.read!(@diarized_file)

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert result["metadata"]["version"] == "2.0"
      assert result["metadata"]["source_vendor"] == "mistral"
      assert result["metadata"]["speakers"] == %{"A" => nil}

      # Should have many utterances (one per segment)
      assert length(result["utterances"]) > 0

      # First utterance
      first = hd(result["utterances"])
      assert first["speaker"] == "A"
      assert first["start"] == 10.2
      assert first["end"] == 11.9
      assert first["text"] == "I bet you thought we were done, right?"
      assert first["confidence"] == 1.0

      # Should have synthetic words for WebVTT generation
      assert length(first["words"]) == 1
      word = hd(first["words"])
      assert word["word"] == "I bet you thought we were done, right?"
      assert word["start"] == 10.2
      assert word["end"] == 11.9
    end

    test "diarized format produces valid WebVTT" do
      transcript = File.read!(@diarized_file)

      {:ok, bold} = Mistral.transcript_to_bold(transcript)
      webvtt = BoldTranscriptsEx.generate_subtitles(bold)

      assert String.starts_with?(webvtt, "WEBVTT")
      assert String.contains?(webvtt, "-->")
      # Should have actual cues, not just the header
      assert length(String.split(webvtt, "-->")) > 2
    end

    test "handles speaker_id mapping" do
      transcript = %{
        "text" => "Hello. Hi there.",
        "segments" => [
          %{
            "text" => " Hello.",
            "start" => 0.0,
            "end" => 1.0,
            "type" => "transcription_segment",
            "speaker_id" => "speaker_1"
          },
          %{
            "text" => " Hi there.",
            "start" => 1.5,
            "end" => 2.5,
            "type" => "transcription_segment",
            "speaker_id" => "speaker_2"
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert result["metadata"]["speakers"] == %{"A" => nil, "B" => nil}
      assert Enum.at(result["utterances"], 0)["speaker"] == "A"
      assert Enum.at(result["utterances"], 1)["speaker"] == "B"
    end

    test "trims leading whitespace from text" do
      transcript = %{
        "text" => "Hello.",
        "segments" => [
          %{
            "text" => " Hello.",
            "start" => 0.0,
            "end" => 1.0,
            "type" => "transcription_segment",
            "speaker_id" => "speaker_1"
          }
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      utterance = hd(result["utterances"])
      assert utterance["text"] == "Hello."
      assert hd(utterance["words"])["word"] == "Hello."
    end
  end

  describe "word-level format (no speaker_id, no words array)" do
    @word_level_file "test/support/data/mistral_voxtral-word-level.json"

    test "converts word-level transcript" do
      transcript = File.read!(@word_level_file)

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert result["metadata"]["version"] == "2.0"
      assert result["metadata"]["source_vendor"] == "mistral"
      assert result["metadata"]["speakers"] == %{}

      # Should have grouped words into utterances
      assert length(result["utterances"]) > 0

      # All utterances should have nil speaker
      Enum.each(result["utterances"], fn u ->
        assert u["speaker"] == nil
      end)

      # All utterances should have non-empty words
      Enum.each(result["utterances"], fn u ->
        assert length(u["words"]) > 0
      end)
    end

    test "groups words by sentence punctuation" do
      transcript = %{
        "text" => "Hello world. How are you?",
        "segments" => [
          %{"text" => " Hello", "start" => 0.0, "end" => 0.3, "type" => "transcription_segment"},
          %{"text" => " world.", "start" => 0.3, "end" => 0.6, "type" => "transcription_segment"},
          %{"text" => " How", "start" => 0.7, "end" => 0.9, "type" => "transcription_segment"},
          %{"text" => " are", "start" => 0.9, "end" => 1.0, "type" => "transcription_segment"},
          %{"text" => " you?", "start" => 1.0, "end" => 1.3, "type" => "transcription_segment"}
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert length(result["utterances"]) == 2

      first = Enum.at(result["utterances"], 0)
      assert first["text"] == "Hello world."
      assert first["start"] == 0.0
      assert first["end"] == 0.6
      assert length(first["words"]) == 2

      second = Enum.at(result["utterances"], 1)
      assert second["text"] == "How are you?"
      assert second["start"] == 0.7
      assert second["end"] == 1.3
      assert length(second["words"]) == 3
    end

    test "groups words by pause gap" do
      transcript = %{
        "text" => "Hello world How are you",
        "segments" => [
          %{"text" => " Hello", "start" => 0.0, "end" => 0.3, "type" => "transcription_segment"},
          %{"text" => " world", "start" => 0.3, "end" => 0.6, "type" => "transcription_segment"},
          # 2 second gap
          %{"text" => " How", "start" => 2.6, "end" => 2.9, "type" => "transcription_segment"},
          %{"text" => " are", "start" => 2.9, "end" => 3.0, "type" => "transcription_segment"},
          %{"text" => " you", "start" => 3.0, "end" => 3.3, "type" => "transcription_segment"}
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      assert length(result["utterances"]) == 2

      first = Enum.at(result["utterances"], 0)
      assert first["text"] == "Hello world"

      second = Enum.at(result["utterances"], 1)
      assert second["text"] == "How are you"
    end

    test "word-level format produces valid WebVTT" do
      transcript = File.read!(@word_level_file)

      {:ok, bold} = Mistral.transcript_to_bold(transcript)
      webvtt = BoldTranscriptsEx.generate_subtitles(bold)

      assert String.starts_with?(webvtt, "WEBVTT")
      assert String.contains?(webvtt, "-->")
      # Should have actual cues, not just the header
      assert length(String.split(webvtt, "-->")) > 2
    end

    test "trims leading whitespace from words" do
      transcript = %{
        "text" => "Hi.",
        "segments" => [
          %{"text" => " Hi.", "start" => 0.0, "end" => 0.5, "type" => "transcription_segment"}
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      utterance = hd(result["utterances"])
      assert utterance["text"] == "Hi."
      assert hd(utterance["words"])["word"] == "Hi."
    end

    test "coerces integer timestamps in word-level format" do
      transcript = %{
        "text" => "Hi.",
        "segments" => [
          %{"text" => " Hi.", "start" => 0, "end" => 1, "type" => "transcription_segment"}
        ]
      }

      {:ok, result} = Mistral.transcript_to_bold(transcript)

      utterance = hd(result["utterances"])
      assert is_float(utterance["start"])
      assert is_float(utterance["end"])
      assert is_float(hd(utterance["words"])["start"])
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
