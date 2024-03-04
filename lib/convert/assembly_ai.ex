defmodule BoldTranscriptsEx.Convert.AssemblyAI do
  @moduledoc """
  Handles conversion of AssemblyAI transcription files to Bold format.
  """

  alias Jason
  require Logger

  def convert(main_transcript, opts \\ []) do
    transcript_data = Jason.decode!(main_transcript)
    paragraphs_data = Keyword.get(opts, :paragraphs, %{}) |> Jason.decode!()
    sentences_data = Keyword.get(opts, :sentences, %{}) |> Jason.decode!()
    speakers = extract_speakers(transcript_data["utterances"])

    # Warning if paragraphs or sentences data is missing
    log_missing_data_warning(paragraphs_data, sentences_data)

    paragraphs =
      if paragraphs_data != %{} and sentences_data != %{},
        do:
          merge_paragraphs_sentences(paragraphs_data["paragraphs"], sentences_data["sentences"]),
        else: paragraphs_data

    merged_data = %{
      "metadata" => extract_metadata(transcript_data, speakers),
      "utterances" => extract_speech(transcript_data["utterances"]),
      "paragraphs" => paragraphs
    }

    {:ok, merged_data}
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

  # # Fallback for non-map inputs
  # defp convert_timestamps(_), do: %{}

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
