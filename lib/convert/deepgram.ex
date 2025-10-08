defmodule BoldTranscriptsEx.Convert.Deepgram do
  @moduledoc """
  Handles conversion of Deepgram transcription files to Bold format.
  """

  require Logger

  alias BoldTranscriptsEx.Convert.Language
  alias BoldTranscriptsEx.Utils

  @doc """
  Converts a Deepgram transcript to the Bold Transcript format.

  ## Parameters

  - `transcript`: The JSON string or decoded map of the transcript data from Deepgram.
  - `opts`: Options for the conversion:
    - `:language`: (required) The language code of the transcript (e.g., "en", "lt")

  ## Returns

  - `{:ok, merged_data}`: A tuple with `:ok` atom and the data in Bold Transcript format.
  - `{:error, reason}`: If required options are missing.

  ## Examples

      iex> BoldTranscriptsEx.Convert.Deepgram.transcript_to_bold(transcript, language: "lt")
      {:ok, %{"metadata" => metadata, "utterances" => utterances, "paragraphs" => paragraphs}}

  """
  @supported_versions [1, 2]

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

  defp apply_version(transcript, opts, 2), do: convert_v2(transcript, opts)
  defp apply_version(transcript, opts, 1), do: convert_v1(transcript, opts)

  defp convert_v1(transcript, opts) do
    transcript = Utils.maybe_decode(transcript)

    with {:ok, language} <- determine_language(transcript, opts),
         paragraphs <- extract_speech_v1(transcript),
         speakers = extract_speakers(paragraphs),
         metadata <- build_metadata_v1(transcript, speakers, language) do
      # TODO: if no utterances, fallback to paragraphs

      merged_data = %{
        "metadata" => metadata,
        "paragraphs" => paragraphs
      }

      {:ok, merged_data}
    end
  end

  defp convert_v2(transcript, opts) do
    transcript = Utils.maybe_decode(transcript)

    with {:ok, language} <- determine_language(transcript, opts),
         speaker_map <- build_speaker_map(transcript),
         utterances <- extract_speech_v2(transcript, speaker_map),
         {:ok, metadata} <- build_metadata_v2(transcript, language) do
      merged_data = %{
        "metadata" => metadata,
        "utterances" => utterances
      }

      {:ok, merged_data}
    end
  end

  defp determine_language(transcript, opts) do
    user_language = Keyword.get(opts, :language)

    detected_language =
      get_in(transcript, ["results", "channels", Access.at(0), "detected_language"])

    case {user_language, detected_language} do
      # User provided language takes precedence
      {lang, _} when is_binary(lang) ->
        {:ok, Language.normalize_deepgram(lang)}

      # Fall back to detected language
      {nil, lang} when is_binary(lang) ->
        {:ok, Language.normalize_deepgram(lang)}

      _ ->
        {:error,
         "No valid language found. Please provide a language or enable language detection."}
    end
  end

  defp build_metadata_v2(transcript, language) do
    model_id = get_in(transcript, ["metadata", "models", Access.at(0)])
    model_info = get_in(transcript, ["metadata", "model_info", model_id])

    speaker_map = build_speaker_map(transcript)

    speakers =
      Map.values(speaker_map)
      |> Enum.sort()
      |> Enum.reduce(%{}, fn id, acc -> Map.put(acc, id, nil) end)

    {:ok,
     %{
       "version" => "2.0",
       "duration" => get_in(transcript, ["metadata", "duration"]),
       "language" => language,
       "source_url" => nil,
       "source_vendor" => "deepgram",
       "source_model" => model_info["name"],
       "source_version" => model_info["version"],
       "transcription_date" => get_in(transcript, ["metadata", "created"]),
       "speakers" => speakers
     }}
  end

  defp build_metadata_v1(data, speakers, language) do
    %{
      "duration" => data["metadata"]["duration"],
      "language" => language,
      # Deepgram doesn't provide source URL in transcript
      "source_url" => nil,
      "speakers" => speakers
    }
  end

  defp extract_speech_v1(transcript) do
    # utterances = transcript["results"]["utterances"] || []
    results = transcript["results"]["channels"] |> List.first()
    data = results["alternatives"] |> List.first() |> Map.get("words", [])

    Enum.map(data, fn sentence ->
      words_converted =
        (sentence["words"] || [])
        |> Enum.map(&convert_word/1)

      sentence
      |> convert_sentence()
      |> Map.put("words", words_converted)
    end)
  end

  defp extract_speech_v2(transcript, speaker_map) do
    utterances = transcript["results"]["utterances"] || []

    utterances
    |> Enum.map(&convert_utterance(&1, speaker_map))
  end

  defp convert_utterance(data, speaker_map) do
    %{
      "start" => data["start"],
      "end" => data["end"],
      "confidence" => data["confidence"],
      "speaker" => speaker_map[data["speaker"]],
      "text" => data["transcript"],
      "words" => (data["words"] || []) |> Enum.map(&convert_word_v2(&1, speaker_map))
    }
  end

  defp convert_word_v2(word, speaker_map) do
    %{
      "word" => word["punctuated_word"] || word["word"],
      "start" => word["start"],
      "end" => word["end"],
      "confidence" => word["confidence"],
      "speaker" => speaker_map[word["speaker"]]
    }
  end

  defp convert_word(data) do
    data
    |> Map.put("text", data["punctuated_word"] || data["word"])
    |> Map.put("start", data["start"])
    |> Map.put("end", data["end"])
    |> Map.put("confidence", data["confidence"])
    |> Map.put("speaker", data["speaker"])
  end

  defp convert_sentence(data) do
    data
    |> Map.put("text", data["transcript"])
    |> Map.put("start", data["start"])
    |> Map.put("end", data["end"])
    |> Map.put("confidence", data["confidence"])
    |> Map.put("speaker", data["speaker"])
  end

  # defp extract_speech(words) do
  #   words
  #   |> Enum.map(fn word ->
  #     %{
  #       "start" => word["start"],
  #       "end" => word["end"],
  #       "confidence" => word["confidence"],
  #       "speaker" => word["speaker"],
  #       "text" => word["punctuated_word"] || word["word"]
  #     }
  #   end)
  # end

  defp extract_speakers(words) when is_list(words) do
    words
    |> Enum.map(&Map.get(&1, "speaker"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  # defp extract_speakers(_), do: []

  # defp extract_speakers_v2(transcript) do
  #   words =
  #     get_in(transcript, [
  #       "results",
  #       "channels",
  #       Access.at(0),
  #       "alternatives",
  #       Access.at(0),
  #       "words"
  #     ]) || []

  #   words
  #   |> Enum.map(&Map.get(&1, "speaker"))
  #   |> Enum.uniq()
  #   |> Enum.sort()
  #   |> Enum.with_index()
  #   |> Enum.map(fn {_, index} ->
  #     # "A" starts at ASCII 65, so this converts 0->A, 1->B, etc.
  #     <<65 + index>>
  #   end)
  #   |> Enum.reduce(%{}, fn speaker_id, acc ->
  #     Map.put(acc, speaker_id, nil)
  #   end)
  # end

  # Creates a mapping from Deepgram's numeric speaker IDs (0, 1, 2) to our letter-based IDs (A, B, C)
  defp build_speaker_map(transcript) do
    words =
      get_in(transcript, [
        "results",
        "channels",
        Access.at(0),
        "alternatives",
        Access.at(0),
        "words"
      ]) || []

    words
    |> Enum.map(&Map.get(&1, "speaker"))
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.with_index()
    |> Enum.into(%{}, fn {speaker_num, index} ->
      # 65 is ASCII 'A'
      {speaker_num, <<65 + index>>}
    end)
  end
end
