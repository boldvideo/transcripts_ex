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
      [%{start: "0:03", title: "Coming soon: Back to Stanford"}]

  """
  def parse_chapters(webvtt) do
    webvtt
    |> String.split("\n\n", trim: true)
    # Drop the WEBVTT header
    |> Enum.drop(1)
    |> Enum.map(&parse_section/1)
  end

  defp parse_section(section) do
    [_, time_range, title] = String.split(section, "\n", parts: 3)
    %{start: parse_time(String.slice(time_range, 0, 12)), title: String.trim(title)}
  end

  defp parse_time(time_range) do
    [start_time | _] = String.split(time_range, " --> ")
    format_time(start_time)
  end

  defp format_time(time_str) do
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

  defp pad(number) when number < 10, do: "0#{number}"
  defp pad(number), do: Integer.to_string(number)
end
