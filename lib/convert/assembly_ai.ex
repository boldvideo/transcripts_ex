defmodule BoldTranscriptsEx.Convert.AssemblyAI do
  @moduledoc """
  Handles conversion of AssemblyAI transcription files to Bold format.
  """

  require Logger

  alias BoldTranscriptsEx.Utils

  @doc """
  Converts an AssemblyAI transcript to the Bold Transcript format.

  ## Parameters

  - `main_transcript`: The JSON string of the main transcript data from AssemblyAI.
  - `opts`: Options for the conversion. Can include `:paragraphs` and `:sentences` data as JSON strings.

  ## Returns

  - `{:ok, merged_data}`: A tuple with `:ok` atom and the merged data in Bold Transcript format.

  ## Examples

      iex> BoldTranscriptsEx.Convert.AssemblyAI.transcript_to_bold(main_transcript)
      {:ok, %{"metadata" => metadata, "utterances" => utterances, "paragraphs" => paragraphs}}

  """
  def transcript_to_bold(transcript, opts) do
    paragraphs_data = Keyword.get(opts, :paragraphs, %{}) |> Utils.maybe_decode()
    sentences_data = Keyword.get(opts, :sentences, %{}) |> Utils.maybe_decode()
    speakers = extract_speakers(transcript["utterances"])

    # Warning if paragraphs or sentences data is missing
    log_missing_data_warning(paragraphs_data, sentences_data)

    paragraphs =
      if paragraphs_data != %{} and sentences_data != %{},
        do:
          merge_paragraphs_sentences(paragraphs_data["paragraphs"], sentences_data["sentences"]),
        else: paragraphs_data

    merged_data = %{
      "metadata" => extract_metadata(transcript, speakers),
      "utterances" => extract_speech(transcript["utterances"]),
      "paragraphs" => paragraphs
    }

    {:ok, merged_data}
  end

  @doc """
  Converts chapter data extracted from an AssemblyAI transcript JSON to WebVTT format.

  ## Parameters

  - `transcript_json`: The JSON string of the full transcript data from AssemblyAI, which includes chapters.
  - `opts`: Optional parameters for the conversion (unused for now, but included for future flexibility).

  ## Returns

  - A string in WebVTT format representing the chapters.

  ## Examples

      iex> transcript_json = "{...}" # Your full transcript JSON string here
      iex> BoldTranscriptsEx.Convert.AssemblyAI.chapters_to_webvtt(transcript_json)
      "WEBVTT\n\n1\n00:00:01.000 --> 00:00:05.000\nChapter 1\n\nSummary of chapter 1\n\n"

  """
  def chapters_to_webvtt(transcript, _opts \\ []) when is_map(transcript) do
    case Map.get(transcript, "chapters") do
      nil ->
        {:error, "No chapters found in the transcript"}

      chapters ->
        chapters_vtt =
          Enum.with_index(chapters, 1)
          |> Enum.map(fn {chapter, index} ->
            start_time = Utils.format_chapter_timestamp(chapter["start"])
            end_time = Utils.format_chapter_timestamp(chapter["end"])
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

  defp extract_metadata(data, speakers) do
    %{
      "duration" => data["audio_duration"],
      "language" => data["language_code"],
      "source_url" => data["audio_url"],
      "speakers" => speakers
    }
  end

  defp merge_paragraphs_sentences(paragraphs, sentences) do
    Enum.map(paragraphs, fn par ->
      merged_sentences =
        sentences
        |> Enum.filter(fn sen -> sen["start"] >= par["start"] && sen["end"] <= par["end"] end)
        |> extract_speech()

      Map.put(par, "sentences", merged_sentences)
      |> convert_timestamps()
      |> Map.delete("words")
    end)
  end

  defp extract_speech(data) do
    Enum.map(data, fn sentence ->
      words_converted = Enum.map(sentence["words"], &convert_timestamps/1)

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

  defp log_missing_data_warning(paragraphs_data, sentences_data) do
    if paragraphs_data == %{} or sentences_data == %{} do
      Logger.warning("""
      Missing paragraphs or sentences data. For comprehensive conversion results, it's recommended to include both paragraphs and sentences data.

      See AssemblyAI documentation for details: https://www.assemblyai.com/docs/api-reference/transcript

      /v2/transcript/:id/sentences
      /v2/transcript/:id/paragraphs
      """)
    end
  end
end
