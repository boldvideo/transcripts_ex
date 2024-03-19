defmodule BoldTranscriptsEx.WebVTT do
  require Logger

  @moduledoc """
  Provides functionality for parsing WebVTT chapter information.

  This module is designed to extract chapter information from WebVTT files,
  which are typically used for subtitles or chapter markers in video content.
  """

  @doc """
  Parses WebVTT content to extract chapters, converting them into a structured list.

  Each item in the returned list represents a chapter with its start time and title.

  ## Parameters

  - `webvtt`: The WebVTT content as a string.

  ## Returns

  A list of maps, each containing `:start` and `:title` keys for a chapter.

  ## Examples

      iex> webvtt_content = "WEBVTT\\n\\n1\\n00:00:03.000 --> 00:00:16.000\\nComing soon: Back to Stanford"
      iex> BoldTranscriptsEx.WebVTT.parse_chapters(webvtt_content)
      [%{start: "0:03", end: "0:16", title: "Coming soon: Back to Stanford"}]

  """
  def parse_chapters(nil), do: []

  def parse_chapters(webvtt) do
    webvtt
    |> String.split("\n\n", trim: true)
    # Drop the WEBVTT header
    |> Enum.drop(1)
    |> Enum.map(&parse_section/1)
  end

  def chapters_to_webvtt(chapters) do
    header = "WEBVTT\n\n"

    body =
      Enum.with_index(chapters)
      |> Enum.map(fn {chapter, index} ->
        format_chapter(chapter, index)
      end)
      |> Enum.join("\n\n")

    header <> body
  end

  defp format_chapter(chapter, index) do
    formatted_start = time_to_webvtt(chapter.start)
    formatted_end = time_to_webvtt(Map.get(chapter, :end, nil))

    "#{index + 1}\n#{formatted_start} --> #{formatted_end}\n#{chapter.title}"
  end

  defp parse_section(section) do
    [_, time_range, title] = String.split(section, "\n", parts: 3)
    {start_time, end_time} = parse_time_range(time_range)
    %{start: start_time, end: end_time, title: String.trim(title)}
  end

  defp parse_time_range(time_range) do
    [start_str, end_str] = String.split(time_range, " --> ")
    {parse_webvtt_time(start_str), parse_webvtt_time(end_str)}
  end

  defp parse_webvtt_time(time_str) do
    parts = String.split(time_str, ":")
    {hours, minutes, seconds} = parse_time_parts(parts)

    cond do
      hours > 0 -> "#{hours}:#{pad(minutes)}:#{pad(seconds)}"
      true -> "#{minutes}:#{pad(seconds)}"
    end
  end

  defp parse_time_parts(parts) do
    [hours, minutes, seconds_with_ms] =
      case parts do
        [h, m, s] -> [String.to_integer(h), String.to_integer(m), s]
        # Assume 0 hours if only minutes and seconds are provided
        [m, s] -> [0, String.to_integer(m), s]
        _ -> raise ArgumentError, "Invalid time format"
      end

    seconds = String.split(seconds_with_ms, ".") |> hd() |> String.to_integer()

    {hours, minutes, seconds}
  end

  # Default placeholder for invalid/missing times
  defp time_to_webvtt(nil), do: "99:59:59.999"

  defp time_to_webvtt(time) do
    parts = String.split(time, ":")

    case parts do
      [hours, minutes, seconds] ->
        hours <> ":" <> minutes <> ":" <> pad_milliseconds(seconds)

      [minutes, seconds] ->
        "00:" <> minutes <> ":" <> pad_milliseconds(seconds)

      _ ->
        # Fallback placeholder for unexpected formats
        "99:59:59.999"
    end
  end

  defp pad(number) when number < 10, do: "0#{number}"
  defp pad(number), do: Integer.to_string(number)

  defp pad_milliseconds(seconds) do
    case String.contains?(seconds, ".") do
      true -> seconds
      false -> seconds <> ".000"
    end
  end
end
