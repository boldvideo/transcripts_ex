defmodule BoldTranscriptsEx.Convert.Common do
  @moduledoc """
  Conversion functions that are common to all providers.
  """
  alias BoldTranscriptsEx.Utils

  def text_to_chapters_webvtt(text, total_duration) do
    text
    |> String.split("\n")
    |> Enum.map(&convert_row_to_chapter/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.seconds)
    |> Enum.with_index(1)
    |> Enum.chunk_every(2, 1, [{%{seconds: total_duration}, -1}])
    |> Enum.reduce("WEBVTT\n\n", fn [{row, idx}, {next_row, _next_idx}], acc ->
      timestamp = Utils.format_chapter_timestamp(row.seconds, :second)
      next_timestamp = Utils.format_chapter_timestamp(next_row.seconds, :second)

      acc <> "#{idx}\n#{timestamp} -> #{next_timestamp}\n#{row.text}\n\n"
    end)
  end

  defp convert_row_to_chapter(row) do
    case Regex.named_captures(~r/(?<minutes>\d{2}):(?<seconds>\d{2}) (?<text>.*)/, row) do
      %{"minutes" => minutes, "seconds" => seconds, "text" => text} ->
        seconds = String.to_integer(minutes) * 60 + String.to_integer(seconds)
        %{seconds: seconds, text: text}

      _no_result ->
        nil
    end
  end
end
