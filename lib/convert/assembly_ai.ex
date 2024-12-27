defmodule BoldTranscriptsEx.Convert.AssemblyAI do
  @moduledoc """
  Handles conversion of AssemblyAI transcription files to Bold format.

  This module provides functionality to:
  - Convert AssemblyAI transcripts to Bold format
  - Convert chapter data to WebVTT format
  - Handle both v1 and v2 of the Bold format
  """

  require Logger

  alias BoldTranscriptsEx.Utils

  @supported_versions [1, 2]

  @doc """
  Converts an AssemblyAI transcript to the Bold Transcript format.

  ## Parameters

  - `transcript`: The JSON string or decoded map of the transcript data from AssemblyAI.
  - `opts`: Options for the conversion:
    - `:version`: The Bold format version to use (1 or 2). Defaults to 2.
    - `:paragraphs`: Optional paragraphs data as JSON string.

  ## Returns

  - `{:ok, bold_transcript}` - Successfully converted transcript where:
    - `bold_transcript` is a map containing:
      - `"metadata"` - Information about the transcript
      - `"utterances"` - List of speech segments with timing
      - `"paragraphs"` - (Optional) List of paragraph segments
  - `{:error, reason}` - If conversion fails

  ## Examples

      # Basic conversion
      iex> json = ~s({"audio_duration": 10.5, "language_code": "en"})
      iex> BoldTranscriptsEx.Convert.AssemblyAI.transcript_to_bold(json)
      {:ok, %{
        "metadata" => %{
          "duration" => 10.5,
          "language" => "en",
          "source_vendor" => "assemblyai"
        },
        "utterances" => []
      }}

      # With version specified
      iex> BoldTranscriptsEx.Convert.AssemblyAI.transcript_to_bold(json, version: 1)
      {:ok, %{...}}
  """
  def transcript_to_bold(transcript, opts \\ []) do
    version = Keyword.get(opts, :version, 2)

    case version do
      v when v in @supported_versions ->
        apply_version(transcript, opts, version)

      _ ->
        {:error,
         "Unsupported version. Supported versions are: #{Enum.join(@supported_versions, ", ")}"}
    end
  end

  @doc """
  Converts chapter data from an AssemblyAI transcript to WebVTT format.

  ## Parameters

  - `transcript`: The decoded transcript map containing chapter data.
  - `opts`: Optional parameters (unused for now, but included for future flexibility).

  ## Returns

  - `{:ok, webvtt_string}` - Successfully converted chapters to WebVTT format
  - `{:error, reason}` - If no chapters are found or conversion fails

  ## Examples

      iex> transcript = %{
      ...>   "chapters" => [
      ...>     %{
      ...>       "start" => 1000,
      ...>       "end" => 5000,
      ...>       "gist" => "Introduction"
      ...>     }
      ...>   ]
      ...> }
      iex> BoldTranscriptsEx.Convert.AssemblyAI.chapters_to_webvtt(transcript)
      {:ok, "WEBVTT\\n\\n1\\n00:00:01.000 --> 00:00:05.000\\nIntroduction\\n"}
  """
  def chapters_to_webvtt(transcript, _opts \\ []) when is_map(transcript) do
    case Map.get(transcript, "chapters") do
      nil ->
        {:error, "No chapters found in the transcript"}

      chapters ->
        chapters_vtt =
          Enum.with_index(chapters, 1)
          |> Enum.map(fn {chapter, index} ->
            start_time = Utils.format_chapter_timestamp(chapter["start"], :millisecond)
            end_time = Utils.format_chapter_timestamp(chapter["end"], :millisecond)
            # title = chapter["headline"]
            # summary = chapter["summary"]
            # using gist instead of summary because it's more concise
            # and turned out to be more useful during testing
            gist = chapter["gist"]

            "#{index}\n#{start_time} --> #{end_time}\n#{gist}\n"
          end)

        header = "WEBVTT\n\n"

        {:ok, header <> Enum.join(chapters_vtt, "\n")}
    end
  end

  defp apply_version(transcript, opts, 2), do: convert_v2(transcript, opts)
  defp apply_version(transcript, opts, 1), do: convert_v1(transcript, opts)

  # Rename existing implementation to v1
  defp convert_v1(transcript, opts) do
    paragraphs_data = Keyword.get(opts, :paragraphs, []) |> Utils.maybe_decode()
    speakers = extract_speakers_v1(transcript["utterances"] || [])

    paragraphs =
      case paragraphs_data do
        %{"paragraphs" => p} when is_list(p) ->
          Enum.map(p, &convert_timestamps/1)

        _ ->
          []
      end

    merged_data = %{
      "metadata" => build_metadata_v1(transcript, speakers),
      "utterances" => extract_speech_v1(transcript["utterances"] || []),
      "paragraphs" => paragraphs
    }

    {:ok, merged_data}
  end

  # New v2 implementation focusing on utterances
  defp convert_v2(transcript, opts) do
    transcript = Utils.maybe_decode(transcript)
    paragraphs_data = Keyword.get(opts, :paragraphs, []) |> Utils.maybe_decode()

    # Try utterances first, fall back to paragraphs
    speech_data = transcript["utterances"] || (paragraphs_data["paragraphs"] || [])
    speakers = extract_speakers_v2(speech_data)

    merged_data = %{
      "metadata" => build_metadata_v2(transcript, speakers),
      "utterances" => extract_speech_v2(speech_data)
    }

    {:ok, merged_data}
  end

  defp build_metadata_v2(data, speakers) do
    %{
      "version" => "2.0",
      "duration" => data["audio_duration"],
      "language" => data["language_code"],
      "source_url" => data["audio_url"],
      "source_vendor" => "assemblyai",
      "source_model" => data["model_version"] || "",
      "source_version" => data["model_version"] || "",
      "transcription_date" => data["created"],
      "speakers" => speakers
    }
  end

  # Rename existing metadata function
  defp build_metadata_v1(data, speakers) do
    %{
      "duration" => data["audio_duration"],
      "language" => data["language_code"],
      "source_url" => data["audio_url"],
      "speakers" => speakers
    }
  end

  defp extract_speech_v2(utterances) do
    Enum.map(utterances, fn utterance ->
      %{
        "start" => utterance["start"] / 1000.0,
        "end" => utterance["end"] / 1000.0,
        "text" => utterance["text"],
        "speaker" => utterance["speaker"],
        "confidence" => utterance["confidence"],
        "words" => Enum.map(utterance["words"] || [], &convert_word_v2/1)
      }
    end)
  end

  defp convert_word_v2(word) do
    %{
      "word" => word["text"],
      "start" => word["start"] / 1000.0,
      "end" => word["end"] / 1000.0,
      "confidence" => word["confidence"]
    }
  end

  # Rename existing functions to v1
  defp extract_speech_v1(data), do: extract_speech(data)
  defp extract_speakers_v1(utterances), do: extract_speakers(utterances)

  defp extract_speakers_v2(utterances) when is_list(utterances) do
    utterances
    |> Enum.map(&Map.get(&1, "speaker"))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.reduce(%{}, fn speaker_id, acc ->
      Map.put(acc, speaker_id, nil)
    end)
  end

  defp extract_speakers_v2(_), do: %{}

  defp extract_speech(data) do
    Enum.map(data, fn sentence ->
      words_converted =
        (sentence["words"] || [])
        |> Enum.map(&convert_timestamps/1)

      sentence
      |> convert_timestamps()
      |> Map.put("words", words_converted)
    end)
  end

  defp convert_timestamps(data) do
    data
    |> Map.update!("start", &(&1 / 1000.0))
    |> Map.update!("end", &(&1 / 1000.0))
  end

  defp extract_speakers(utterances) when is_list(utterances) do
    utterances
    |> Enum.map(&Map.get(&1, "speaker"))
    # Ensure extracted speakers are strings
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp extract_speakers(_), do: []
end
