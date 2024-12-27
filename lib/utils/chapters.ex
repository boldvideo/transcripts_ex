defmodule BoldTranscriptsEx.Utils.Chapters do
  @moduledoc """
  Provides utility functions for working with chapter data.

  This module handles:
  - Converting between different chapter formats
  - Parsing WebVTT chapter files
  - Converting chapters to WebVTT format
  - Time format conversions (WebVTT, milliseconds, human-readable)

  Chapter data can be represented in different formats:
  - WebVTT format (text with timestamps and titles)
  - Bold format (list of maps with start/end times and titles)
  - AssemblyAI format (embedded in transcript with gist as title)
  """

  @doc """
  Parses WebVTT content to extract chapters, converting them into a structured list.

  ## Parameters

  - `webvtt`: The WebVTT content as a string in format:
    ```
    WEBVTT

    1
    00:00:03.000 --> 00:00:16.000
    Chapter Title
    ```

  ## Returns

  A list of maps, each containing:
  - `:start` - Start time in format "MM:SS" or "HH:MM:SS"
  - `:end` - End time in same format as start
  - `:title` - Chapter title as string

  ## Examples

      iex> webvtt = \"\"\"
      ...> WEBVTT
      ...>
      ...> 1
      ...> 00:00:03.000 --> 00:00:16.000
      ...> Introduction
      ...> \"\"\"
      iex> BoldTranscriptsEx.Utils.Chapters.parse_chapters(webvtt)
      [%{start: "0:03", end: "0:16", title: "Introduction"}]
  """
  def parse_chapters(nil), do: []

  def parse_chapters(webvtt) do
    webvtt
    |> String.split("\n\n", trim: true)
    # Drop the WEBVTT header
    |> Enum.drop(1)
    |> Enum.map(&parse_section/1)
  end

  @doc """
  Converts a list of chapters into WebVTT format.

  ## Parameters

  - `chapters`: A list of maps, each containing:
    - `:start` - Start time as "MM:SS" or "HH:MM:SS"
    - `:end` - End time in same format as start
    - `:title` - Chapter title

  ## Returns

  A string in WebVTT format with chapter markers.

  ## Examples

      iex> chapters = [
      ...>   %{start: "0:03", end: "0:16", title: "Introduction"},
      ...>   %{start: "0:16", end: "1:00", title: "Main Content"}
      ...> ]
      iex> BoldTranscriptsEx.Utils.Chapters.chapters_to_webvtt(chapters)
      \"\"\"
      WEBVTT

      1
      00:00:03.000 --> 00:00:16.000
      Introduction

      2
      00:00:16.000 --> 00:01:00.000
      Main Content
      \"\"\"
  """
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

  def chapters_to_webvtt(:assemblyai, transcript) do
    case Map.get(transcript, "chapters") do
      nil ->
        {:error, "No chapters found in the transcript"}

      chapters ->
        chapters_vtt =
          Enum.with_index(chapters, 1)
          |> Enum.map(fn {chapter, index} ->
            start_time = ms_to_webvtt(chapter["start"])
            end_time = ms_to_webvtt(chapter["end"])
            gist = chapter["gist"]

            "#{index}\n#{start_time} --> #{end_time}\n#{gist}"
          end)
          |> Enum.join("\n\n")

        header = "WEBVTT\n\n"

        {:ok, header <> chapters_vtt}
    end
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
        hours <> ":" <> pad(minutes) <> ":" <> pad_with_ms(seconds)

      [minutes, seconds] ->
        "00:" <> pad(minutes) <> ":" <> pad_with_ms(seconds)

      _ ->
        # Fallback placeholder for unexpected formats
        "99:59:59.999"
    end
  end

  defp pad(number) when is_binary(number) do
    case String.length(number) do
      1 -> "0#{number}"
      _ -> number
    end
  end

  defp pad(number) when number < 10, do: "0#{number}"
  defp pad(number), do: Integer.to_string(number)

  defp pad_with_ms(seconds) do
    case String.contains?(seconds, ".") do
      true ->
        [sec, ms] = String.split(seconds, ".")
        "#{pad(sec)}.#{pad_ms(String.to_integer(ms))}"

      false ->
        "#{pad(seconds)}.000"
    end
  end

  @doc """
  Converts milliseconds to WebVTT timestamp format (HH:MM:SS.mmm)

  ## Examples

      iex> ms_to_webvtt(114160)
      "00:01:54.160"

      iex> ms_to_webvtt(5000)
      "00:00:05.000"
  """
  def ms_to_webvtt(ms) when is_integer(ms) do
    hours = div(ms, 3_600_000)
    remainder = rem(ms, 3_600_000)
    minutes = div(remainder, 60_000)
    remainder = rem(remainder, 60_000)
    seconds = div(remainder, 1000)
    milliseconds = rem(remainder, 1000)

    # Format with consistent padding
    "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}.#{pad_ms(milliseconds)}"
  end

  # Add this helper function for milliseconds padding
  defp pad_ms(ms) do
    ms
    |> Integer.to_string()
    |> String.pad_leading(3, "0")
  end
end
