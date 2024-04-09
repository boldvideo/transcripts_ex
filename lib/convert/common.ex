defmodule BoldTranscriptsEx.Convert.Common do
  @moduledoc """
  Conversion functions that are common to all providers.
  """
  alias BoldTranscriptsEx.Utils

  @doc """
  Converts a text input to a chapters WebVTT text.

  Expects the input text and a total duration in Seconds.
  """
  def text_to_chapters_webvtt(text, total_duration) do
    text
    |> String.split("\n")
    |> Enum.map(&convert_row_to_chapter/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      rows -> convert_rows_to_chapters(rows, total_duration)
    end
  end

  defp convert_rows_to_chapters(rows, total_duration) do
    rows
    |> Enum.sort_by(& &1.seconds)
    |> Enum.with_index(1)
    |> Enum.chunk_every(2, 1, [{%{seconds: total_duration}, -1}])
    |> Enum.reduce("WEBVTT\n\n", fn [{row, idx}, {next_row, _next_idx}], acc ->
      timestamp = Utils.format_chapter_timestamp(row.seconds, :second)
      next_timestamp = Utils.format_chapter_timestamp(next_row.seconds, :second)

      acc <> "#{idx}\n#{timestamp} -> #{next_timestamp}\n#{row.text}\n\n"
    end)
  end

  @timestamp_and_text_regex ~r/((?<hours>\d{2}):)?(?<minutes>\d{2}):(?<seconds>\d{2}) (?<text>.*)/

  defp convert_row_to_chapter(row) do
    case Regex.named_captures(@timestamp_and_text_regex, row) do
      %{"hours" => hours, "minutes" => minutes, "seconds" => seconds, "text" => text} ->
        hours = if hours == "", do: "00", else: hours

        seconds =
          String.to_integer(hours) * 3600 + String.to_integer(minutes) * 60 +
            String.to_integer(seconds)

        %{seconds: seconds, text: text}

      _no_result ->
        nil
    end
  end

  @doc """
  Converts a chapters WebVTT into a text with one chapter and timestamp per line.
  """
  def chapters_webvtt_to_text(webvtt) do
    webvtt
    |> String.split("\n")
    |> Enum.drop(2)
    |> Enum.chunk_every(4)
    |> Enum.map(&convert_chapter_to_row/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  @full_timestamp_regex ~r/(?<hours>\d{2}):(?<minutes>\d{2}):(?<seconds>\d{2})/

  defp convert_chapter_to_row([_idx, timestamps, text, _newline] = _chapter) do
    case Regex.named_captures(@full_timestamp_regex, timestamps) do
      %{"hours" => hours, "minutes" => minutes, "seconds" => seconds} ->
        hours = if hours == "00", do: "", else: "#{hours}:"

        hours <> "#{minutes}:#{seconds} #{text}"

      _no_result ->
        nil
    end
  end

  defp convert_chapter_to_row(_chapter), do: nil
end
