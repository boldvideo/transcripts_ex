defmodule BoldTranscriptsEx.WebVTT do
  require Logger

  # Configuration for subtitle generation
  @max_chars_per_line 42
  @max_lines_per_subtitle 2
  # 150ms pause threshold for natural breaks
  @pause_threshold 0.15
  # Subtract 200ms from end time for better readability
  @subtitle_end_offset 0.0

  @moduledoc """
  Provides functionality for working with WebVTT files.

  This module handles:
  - Converting Bold transcripts to WebVTT subtitles
  - Smart subtitle splitting based on word timing and natural pauses
  - Line length optimization for readability
  - Speaker identification in subtitles using WebVTT's <v> tag

  Configuration:
  - Maximum #{@max_chars_per_line} characters per line
  - Maximum #{@max_lines_per_subtitle} lines per subtitle
  - Natural breaks at pauses longer than #{@pause_threshold}s
  - #{@subtitle_end_offset}s gap between subtitles for better readability
  """

  @doc """
  Generates WebVTT subtitles from a Bold transcript.

  ## Parameters

  - `transcript`: A Bold transcript map containing:
    - `metadata.speakers` - Map of speaker IDs to names
    - `utterances` - List of utterances with word-level timing

  ## Returns

  A string containing the WebVTT subtitles with speaker labels.

  ## Examples

      iex> transcript = %{
      ...>   "metadata" => %{"speakers" => %{"A" => "John"}},
      ...>   "utterances" => [
      ...>     %{
      ...>       "start" => 0.0,
      ...>       "end" => 2.5,
      ...>       "text" => "Hello world",
      ...>       "speaker" => "A",
      ...>       "words" => [
      ...>         %{"word" => "Hello", "start" => 0.0, "end" => 1.0},
      ...>         %{"word" => "world", "start" => 1.5, "end" => 2.5}
      ...>       ]
      ...>     }
      ...>   ]
      ...> }
      iex> BoldTranscriptsEx.WebVTT.generate_subtitles(transcript)
      "WEBVTT\\n\\n1\\n00:00:00.000 --> 00:00:02.300\\n<v John>Hello world</v>"
  """
  def generate_subtitles(transcript) do
    header = "WEBVTT\n\n"
    speaker_names = extract_speaker_names(transcript["metadata"])

    body =
      transcript["utterances"]
      |> Enum.map(&process_utterance(&1, speaker_names))
      |> List.flatten()
      |> Enum.with_index(1)
      |> Enum.map(&format_subtitle/1)
      |> Enum.join("\n\n")

    header <> body
  end

  defp process_utterance(%{"words" => words, "speaker" => speaker}, speaker_names) do
    # First, split by silences longer than the pause threshold
    word_groups = split_by_silence(words, @pause_threshold)

    # Then split each group by character limit
    word_groups
    |> Enum.flat_map(&split_by_char_limit(&1, @max_chars_per_line * @max_lines_per_subtitle))
    |> Enum.map(fn group ->
      first_word = List.first(group)
      last_word = List.last(group)
      text = Enum.map_join(group, " ", & &1["word"])
      text = split_into_two_lines(text)

      %{
        start_time: first_word["start"],
        end_time: last_word["end"] - @subtitle_end_offset,
        text: format_text(text, speaker, speaker_names)
      }
    end)
  end

  defp split_into_two_lines(text) when byte_size(text) <= @max_chars_per_line, do: text

  defp split_into_two_lines(text) do
    words = String.split(text, " ")
    {first_line, rest} = split_at_limit(words, @max_chars_per_line, [], "")

    first_line = Enum.join(first_line, " ")
    second_line = Enum.join(rest, " ")

    if byte_size(second_line) > @max_chars_per_line do
      # If second line is too long, try to balance the lines better
      words = String.split(text, " ")
      total_length = byte_size(text)
      target_length = div(total_length, 2)
      {first_line, rest} = split_at_limit(words, target_length, [], "")
      Enum.join(first_line, " ") <> "\n" <> Enum.join(rest, " ")
    else
      first_line <> "\n" <> second_line
    end
  end

  defp split_at_limit([], _limit, acc, _current), do: {Enum.reverse(acc), []}

  defp split_at_limit(rest, _limit, acc, current) when byte_size(current) > @max_chars_per_line do
    {Enum.reverse(acc), rest}
  end

  defp split_at_limit([word | rest], limit, acc, current) do
    next = if current == "", do: word, else: current <> " " <> word

    if byte_size(next) <= limit do
      split_at_limit(rest, limit, [word | acc], next)
    else
      {Enum.reverse(acc), [word | rest]}
    end
  end

  defp split_by_silence(words, threshold) do
    Enum.reduce(words, {[], []}, fn word, {chunks, current_chunk} ->
      case current_chunk do
        [] ->
          # Start the first chunk
          {chunks, [word]}

        _ ->
          # Calculate silence duration
          last_word = List.last(current_chunk)
          silence = word["start"] - last_word["end"]

          if silence > threshold do
            # Start a new chunk
            {chunks ++ [current_chunk], [word]}
          else
            # Add word to current chunk
            {chunks, current_chunk ++ [word]}
          end
      end
    end)
    |> finalize_chunks()
  end

  defp finalize_chunks({chunks, current_chunk}) do
    # Add the last chunk if it's not empty
    if current_chunk != [], do: chunks ++ [current_chunk], else: chunks
  end

  defp split_by_char_limit(words, char_limit) do
    words
    |> Enum.chunk_while(
      [],
      fn word, acc ->
        current_text =
          (acc ++ [word])
          |> Enum.map_join(" ", & &1["word"])

        if String.length(current_text) <= char_limit do
          {:cont, acc ++ [word]}
        else
          if acc == [] do
            {:cont, [word], []}
          else
            {:cont, acc, [word]}
          end
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, acc, []}
      end
    )
  end

  defp format_subtitle({subtitle, index}) do
    "#{index}\n#{format_subtitle_time(subtitle.start_time)} --> #{format_subtitle_time(subtitle.end_time)}\n#{subtitle.text}"
  end

  defp format_text(text, speaker_id, speaker_names) do
    case Map.get(speaker_names, speaker_id) do
      nil -> text
      name when is_binary(name) and byte_size(name) > 0 -> "<v #{name}>#{text}</v>"
      _ -> text
    end
  end

  defp extract_speaker_names(nil), do: %{}
  defp extract_speaker_names(%{"speakers" => speakers}) when is_map(speakers), do: speakers

  defp extract_speaker_names(%{"speakers" => speakers}) when is_list(speakers) do
    speakers
    |> Enum.reduce(%{}, fn
      %{"id" => id, "name" => name}, acc -> Map.put(acc, id, name)
      _, acc -> acc
    end)
  end

  defp extract_speaker_names(_), do: %{}

  defp format_subtitle_time(seconds) when is_integer(seconds),
    do: format_subtitle_time(seconds * 1.0)

  defp format_subtitle_time(seconds) when is_float(seconds) do
    total_milliseconds = trunc(seconds * 1000)
    hours = div(total_milliseconds, 3_600_000)
    remaining = rem(total_milliseconds, 3_600_000)
    minutes = div(remaining, 60_000)
    remaining = rem(remaining, 60_000)
    seconds = div(remaining, 1_000)
    milliseconds = rem(remaining, 1_000)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}.#{pad_milliseconds(milliseconds)}"
  end

  defp pad(number) when number < 10, do: "0#{number}"
  defp pad(number), do: Integer.to_string(number)

  defp pad_milliseconds(num) do
    num
    |> Integer.to_string()
    |> String.pad_leading(3, "0")
  end
end
