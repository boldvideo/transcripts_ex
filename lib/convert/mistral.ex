defmodule BoldTranscriptsEx.Convert.Mistral do
  @moduledoc """
  Handles conversion of Mistral Voxtral transcription files to Bold format.

  Supports three segment formats from the Voxtral API:

  - **Legacy**: Segments have a nested `"words"` array and a `"speaker"` key.
  - **Diarized**: Segments are sentence-level with `"speaker_id"` but no `"words"`.
  - **Word-level**: Segments are individual words with no speaker info and no `"words"`.
  """

  require Logger

  alias BoldTranscriptsEx.Convert.Language
  alias BoldTranscriptsEx.Utils

  # Maximum words per utterance when grouping word-level segments
  @max_words_per_utterance 30
  # Pause threshold (seconds) for splitting word-level segments into utterances
  @pause_threshold 1.0

  @doc """
  Converts a Mistral Voxtral transcript to the Bold Transcript format v2.

  ## Parameters

  - `transcript`: The JSON string or decoded map of the transcript data from Voxtral.
  - `opts`: Options for the conversion:
    - `:language`: The language code of the transcript (e.g., "en", "de"). Defaults to "en".

  ## Returns

  - `{:ok, merged_data}`: A tuple with `:ok` atom and the data in Bold Transcript format.

  ## Examples

      iex> transcript = ~s({"text": "Hello", "segments": [{"id": 0, "start": 0.0, "end": 1.0, "text": "Hello", "speaker": "speaker_0", "words": [{"word": "Hello", "start": 0.0, "end": 1.0}]}]})
      iex> BoldTranscriptsEx.Convert.Mistral.transcript_to_bold(transcript)
      {:ok, %{"metadata" => %{"version" => "2.0", "duration" => 1.0, "language" => "en_us", "source_url" => "", "source_vendor" => "mistral", "source_model" => "", "source_version" => "", "transcription_date" => nil, "speakers" => %{"A" => nil}}, "utterances" => [%{"start" => 0.0, "end" => 1.0, "text" => "Hello", "speaker" => "A", "confidence" => 1.0, "words" => [%{"word" => "Hello", "start" => 0.0, "end" => 1.0, "confidence" => 1.0}]}]}}

  """
  def transcript_to_bold(transcript, opts \\ []) do
    transcript = Utils.maybe_decode(transcript)
    segments = transcript["segments"] || []
    format = detect_format(segments)
    speaker_map = build_speaker_map(segments, format)
    utterances = build_utterances(segments, speaker_map, format)
    metadata = build_metadata(segments, speaker_map, opts)

    {:ok, %{"metadata" => metadata, "utterances" => utterances}}
  end

  defp detect_format([]), do: :legacy

  defp detect_format([first | _]) do
    cond do
      Map.has_key?(first, "words") -> :legacy
      Map.has_key?(first, "speaker") -> :legacy
      Map.has_key?(first, "speaker_id") -> :diarized
      true -> :word_level
    end
  end

  defp build_metadata(segments, speaker_map, opts) do
    language = Keyword.get(opts, :language)
    last_segment = List.last(segments)
    duration = if last_segment, do: ensure_float(last_segment["end"]), else: 0.0

    speakers =
      speaker_map
      |> Map.values()
      |> Enum.sort()
      |> Enum.into(%{}, fn letter -> {letter, nil} end)

    %{
      "version" => "2.0",
      "duration" => duration,
      "language" => Language.normalize_mistral(language),
      "source_url" => "",
      "source_vendor" => "mistral",
      "source_model" => "",
      "source_version" => "",
      "transcription_date" => nil,
      "speakers" => speakers
    }
  end

  defp build_speaker_map(segments, :diarized) do
    segments
    |> Enum.map(&Map.get(&1, "speaker_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.with_index()
    |> Enum.into(%{}, fn {speaker_label, index} ->
      {speaker_label, <<65 + index>>}
    end)
  end

  defp build_speaker_map(segments, _format) do
    segments
    |> Enum.map(&Map.get(&1, "speaker"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.with_index()
    |> Enum.into(%{}, fn {speaker_label, index} ->
      {speaker_label, <<65 + index>>}
    end)
  end

  defp build_utterances(segments, speaker_map, :legacy) do
    Enum.map(segments, fn segment ->
      words = build_words(segment["words"])

      %{
        "start" => ensure_float(segment["start"]),
        "end" => ensure_float(segment["end"]),
        "text" => trim_text(segment["text"]),
        "speaker" => Map.get(speaker_map, segment["speaker"]),
        "confidence" => 1.0,
        "words" => words
      }
    end)
  end

  defp build_utterances(segments, speaker_map, :diarized) do
    Enum.map(segments, fn segment ->
      text = trim_text(segment["text"])

      %{
        "start" => ensure_float(segment["start"]),
        "end" => ensure_float(segment["end"]),
        "text" => text,
        "speaker" => Map.get(speaker_map, segment["speaker_id"]),
        "confidence" => 1.0,
        "words" => [
          %{
            "word" => text,
            "start" => ensure_float(segment["start"]),
            "end" => ensure_float(segment["end"]),
            "confidence" => 1.0
          }
        ]
      }
    end)
  end

  defp build_utterances(segments, _speaker_map, :word_level) do
    segments
    |> group_word_segments()
    |> Enum.map(fn group ->
      first = List.first(group)
      last = List.last(group)
      text = group |> Enum.map_join(" ", &trim_text(&1["text"])) |> String.trim()

      words =
        Enum.map(group, fn seg ->
          %{
            "word" => trim_text(seg["text"]),
            "start" => ensure_float(seg["start"]),
            "end" => ensure_float(seg["end"]),
            "confidence" => 1.0
          }
        end)

      %{
        "start" => ensure_float(first["start"]),
        "end" => ensure_float(last["end"]),
        "text" => text,
        "speaker" => nil,
        "confidence" => 1.0,
        "words" => words
      }
    end)
  end

  defp group_word_segments(segments) do
    {groups, current} =
      segments
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {segment, index}, {groups, current} ->
        current = current ++ [segment]
        next_segment = Enum.at(segments, index + 1)

        should_split =
          ends_with_sentence_punctuation?(segment["text"]) ||
            (next_segment != nil &&
               ensure_float(next_segment["start"]) - ensure_float(segment["end"]) >
                 @pause_threshold) ||
            length(current) >= @max_words_per_utterance

        if should_split do
          {groups ++ [current], []}
        else
          {groups, current}
        end
      end)

    if current == [], do: groups, else: groups ++ [current]
  end

  defp ends_with_sentence_punctuation?(text) when is_binary(text) do
    text = String.trim(text)
    String.ends_with?(text, ".") || String.ends_with?(text, "?") || String.ends_with?(text, "!")
  end

  defp ends_with_sentence_punctuation?(_), do: false

  defp trim_text(text) when is_binary(text), do: String.trim(text)
  defp trim_text(text), do: text

  defp build_words(nil), do: []

  defp build_words(words) when is_list(words) do
    Enum.map(words, fn word ->
      %{
        "word" => word["word"],
        "start" => ensure_float(word["start"]),
        "end" => ensure_float(word["end"]),
        "confidence" => word["confidence"] || 1.0
      }
    end)
  end

  defp build_words(_), do: []

  defp ensure_float(value) when is_float(value), do: value
  defp ensure_float(value) when is_integer(value), do: value * 1.0
  defp ensure_float(_), do: 0.0
end
