defmodule BoldTranscriptsEx.Convert.Deepgram do
  @moduledoc """
  Handles conversion of Deepgram transcription files to Bold format.
  """

  require Logger

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
  def transcript_to_bold(transcript, opts \\ []) do
    with {:ok, language} <- validate_language_option(opts) do
      transcript = Utils.maybe_decode(transcript)
      results = transcript["results"]["channels"] |> List.first()
      utterances = results["alternatives"] |> List.first() |> Map.get("words", [])

      speakers = extract_speakers(utterances)

      merged_data = %{
        "metadata" => extract_metadata(transcript, speakers, language),
        "utterances" => extract_speech(utterances),
        # Deepgram doesn't provide paragraph segmentation
        "paragraphs" => []
      }

      {:ok, merged_data}
    end
  end

  defp validate_language_option(opts) do
    case Keyword.get(opts, :language) do
      nil -> {:error, "Language option is required for Deepgram transcripts"}
      language when is_binary(language) -> {:ok, language}
      _ -> {:error, "Language must be a string"}
    end
  end

  defp extract_metadata(data, speakers, language) do
    %{
      "duration" => data["metadata"]["duration"],
      "language" => language,
      # Deepgram doesn't provide source URL in transcript
      "source_url" => nil,
      "speakers" => speakers
    }
  end

  defp extract_speech(words) do
    words
    |> Enum.map(fn word ->
      %{
        "start" => word["start"],
        "end" => word["end"],
        "confidence" => word["confidence"],
        "speaker" => word["speaker"],
        "text" => word["punctuated_word"] || word["word"]
      }
    end)
  end

  defp extract_speakers(words) when is_list(words) do
    words
    |> Enum.map(&Map.get(&1, "speaker"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_speakers(_), do: []
end
