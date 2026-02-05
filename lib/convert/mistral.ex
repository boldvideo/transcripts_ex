defmodule BoldTranscriptsEx.Convert.Mistral do
  @moduledoc """
  Handles conversion of Mistral Voxtral transcription files to Bold format.
  """

  require Logger

  alias BoldTranscriptsEx.Convert.Language
  alias BoldTranscriptsEx.Utils

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
    speaker_map = build_speaker_map(segments)
    utterances = build_utterances(segments, speaker_map)
    metadata = build_metadata(segments, speaker_map, opts)

    {:ok, %{"metadata" => metadata, "utterances" => utterances}}
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

  defp build_speaker_map(segments) do
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

  defp build_utterances(segments, speaker_map) do
    Enum.map(segments, fn segment ->
      words = build_words(segment["words"])

      %{
        "start" => ensure_float(segment["start"]),
        "end" => ensure_float(segment["end"]),
        "text" => segment["text"],
        "speaker" => Map.get(speaker_map, segment["speaker"]),
        "confidence" => 1.0,
        "words" => words
      }
    end)
  end

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
