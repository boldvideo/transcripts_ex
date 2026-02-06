defmodule BoldTranscriptsEx.Convert.Speechmatics do
  @moduledoc """
  Handles conversion of Speechmatics transcription files to Bold format.
  """

  require Logger

  alias BoldTranscriptsEx.Convert.Language
  alias BoldTranscriptsEx.Utils

  def transcript_to_bold(transcript) do
    transcript = Utils.maybe_decode(transcript)
    # paragraphs_data = Keyword.get(opts, :paragraphs, []) |> Utils.maybe_decode()

    # Try utterances first, fall back to paragraphs
    speech_data = transcript["results"] || []
    speakers = extract_speakers(speech_data)

    merged_data = %{
      "metadata" => build_metadata(transcript, speakers),
      "utterances" => extract_speech(speech_data)
    }

    {:ok, merged_data}
  end

  defp build_metadata(data, speakers) do
    %{
      "version" => "2.0",
      "duration" => data["job"]["duration"],
      "language" =>
        Language.normalize_speechmatics(data["metadata"]["transcription_config"]["language"]),
      "source_url" => "",
      "source_vendor" => "speechmatics",
      "source_model" => data["metadata"]["transcription_config"]["operating_point"] || "",
      "source_version" => data["format"] || "",
      "transcription_date" => data["metadata"]["created_at"],
      "speakers" => speakers
    }
  end

  defp extract_speech(elements) do
    # First, let's separate words and punctuation
    {words, punctuation} =
      elements
      |> Enum.reduce({[], %{}}, fn element, {words, punct_map} ->
        case element do
          %{"type" => "word"} ->
            {[element | words], punct_map}

          %{"type" => "punctuation", "attaches_to" => "previous"} ->
            {words,
             Map.put(
               punct_map,
               element["start_time"],
               element["alternatives"] |> Enum.at(0) |> Map.get("content")
             )}

          _ ->
            {words, punct_map}
        end
      end)

    # Reverse words since we prepended
    words = Enum.reverse(words)

    # Convert speaker IDs (S1, S2) to letters (A, B)
    speaker_map =
      words
      |> Enum.map(fn word ->
        word["alternatives"] |> Enum.at(0) |> Map.get("speaker")
      end)
      |> Enum.uniq()
      |> Enum.with_index()
      |> Enum.into(%{}, fn {id, index} -> {id, <<65 + index>>} end)

    # Group words into utterances based on time gaps
    words
    |> Enum.chunk_while(
      [],
      fn word, chunk ->
        start_time = word["start_time"]
        prev_end = if Enum.empty?(chunk), do: start_time, else: List.first(chunk)["end_time"]

        if start_time - prev_end > 0.8 and not Enum.empty?(chunk) do
          {:cont, Enum.reverse(chunk), [word]}
        else
          {:cont, [word | chunk]}
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, Enum.reverse(acc), []}
      end
    )
    |> Enum.map(fn utterance_words ->
      # Convert words, attaching punctuation where needed
      words =
        utterance_words
        |> Enum.map(fn word ->
          alt = Enum.at(word["alternatives"], 0)
          punct = Map.get(punctuation, word["end_time"], "")

          %{
            "word" => alt["content"] <> punct,
            "start" => word["start_time"],
            "end" => word["end_time"],
            "confidence" => alt["confidence"],
            "speaker" => Map.get(speaker_map, alt["speaker"])
          }
        end)

      # Get the first and last word for utterance timing
      first_word = List.first(utterance_words)
      last_word = List.last(utterance_words)
      speaker = first_word["alternatives"] |> Enum.at(0) |> Map.get("speaker")

      # Build the complete utterance text
      text =
        utterance_words
        |> Enum.map(fn word ->
          alt = Enum.at(word["alternatives"], 0)
          content = alt["content"]
          punct = Map.get(punctuation, word["end_time"], "")
          content <> punct
        end)
        |> Enum.join(" ")

      # Calculate average confidence for the utterance
      avg_confidence =
        utterance_words
        |> Enum.map(fn word -> word["alternatives"] |> Enum.at(0) |> Map.get("confidence") end)
        |> Enum.sum()
        |> Kernel./(length(utterance_words))

      %{
        "start" => first_word["start_time"],
        "end" => last_word["end_time"],
        "text" => text,
        "speaker" => Map.get(speaker_map, speaker),
        "confidence" => avg_confidence,
        "words" => words
      }
    end)
  end

  # # defp convert_word(element) do
  # #   %{
  # #     "word" => word["text"],
  # #     "start" => word["start"] / 1000.0,
  # #     "end" => word["end"] / 1000.0,
  # #     "confidence" => word["confidence"]
  # #   }
  # end

  defp extract_speakers(results) when is_list(results) do
    results
    |> Enum.filter(fn element -> element["type"] == "word" end)
    |> Enum.map(fn word ->
      word["alternatives"]
      |> Enum.at(0)
      |> Map.get("speaker")
    end)
    |> Enum.uniq()
    |> Enum.with_index()
    |> Enum.into(%{}, fn {_id, index} ->
      {<<65 + index>>, nil}
    end)
  end

  defp extract_speakers(_), do: %{}
end
