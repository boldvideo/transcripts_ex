defmodule BoldTranscriptsEx.WebVTT do
  @moduledoc """
  Converts Bold JSON transcripts into WebVTT format with enhanced processing for readability,
  synchronization, and segmentation, allowing parameterization for greater flexibility.
  """

  require Logger

  # Entry point with parameters
  def create(transcript, opts \\ []) do
    character_per_line = Keyword.get(opts, :characterPerLine, 42)
    max_lines = Keyword.get(opts, :maxLines, 2)
    max_time_in_ms = Keyword.get(opts, :maxTimeInMs, 1000)

    vtt =
      transcript["utterances"]
      |> Enum.map(&format_utterance_to_vtt(&1, character_per_line, max_lines, max_time_in_ms))
      |> Enum.join("\n\n")
      |> (fn content -> "WEBVTT\n\n" <> content end).()

    {:ok, vtt}
  end

  defp format_utterance_to_vtt(
         %{"start" => start, "end" => finish, "text" => text},
         character_per_line,
         max_lines,
         _max_time_in_ms
       ) do
    start_time = format_time(start)
    end_time = format_time(finish)
    text_lines = process_text(text, character_per_line, max_lines)

    "#{start_time} --> #{end_time}\n#{text_lines}\n"
  end

  def format_time(seconds) do
    milliseconds = round(seconds * 1_000)
    hours = div(milliseconds, 3_600_000)
    minutes = div(rem(milliseconds, 3_600_000), 60_000)
    seconds = div(rem(milliseconds, 60_000), 1_000)
    remaining_milliseconds = rem(milliseconds, 1_000)

    formatted_hours = pad_with_zeroes(hours, 2)
    formatted_minutes = pad_with_zeroes(minutes, 2)
    formatted_seconds = pad_with_zeroes(seconds, 2)
    formatted_milliseconds = pad_with_zeroes(remaining_milliseconds, 3)

    "#{formatted_hours}:#{formatted_minutes}:#{formatted_seconds}.#{formatted_milliseconds}"
  end

  defp pad_with_zeroes(number, desired_length) do
    Integer.to_string(number) |> String.pad_leading(desired_length, "0")
  end

  defp process_text(text, character_per_line, max_lines) do
    text
    |> split_sentences()
    |> Enum.map(&wrap_text(&1, character_per_line, max_lines))
    |> Enum.join("\n")
  end

  defp split_sentences(text) do
    Regex.split(~r/(?<=[.!?])\s+/, text)
  end

  defp wrap_text(sentence, line_length, max_lines) do
    sentence
    |> String.graphemes()
    |> Enum.reduce({[], 0, 0}, fn grapheme, {lines, current_line_length, line_count} ->
      if line_count < max_lines and current_line_length + String.length(grapheme) <= line_length do
        update_lines(lines, grapheme, current_line_length, line_count)
      else
        start_new_line(lines, grapheme, line_count)
      end
    end)
    |> elem(0)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp update_lines([], grapheme, _, _) do
    {[grapheme], String.length(grapheme), 1}
  end

  defp update_lines(lines, grapheme, current_line_length, line_count) do
    last_line = List.last(lines) <> grapheme
    updated_lines = List.update_at(lines, -1, fn _ -> last_line end)
    {updated_lines, current_line_length + String.length(grapheme), line_count}
  end

  defp start_new_line(lines, grapheme, line_count) do
    {lines ++ [grapheme], String.length(grapheme), line_count + 1}
  end
end
