defmodule BoldTranscriptsEx.WebVTT2 do
  require Logger

  def create(transcript) do
    transcript["utterances"]
    |> Enum.map(&process_line/1)
    |> IO.inspect()

    # |> IO.inspect()

    # |> List.flatten()
  end

  def process_line(%{"words" => words}) do
    chunk_fun = fn
      %{"text" => text}, {current_chunk, char_count} ->
        # +1 for the space
        new_char_count = char_count + byte_size(text) + 1

        if new_char_count <= 80 do
          {:cont, {Enum.reverse([text | Enum.reverse(current_chunk)]), new_char_count}}
        else
          {:cont, Enum.reverse(current_chunk), {[text], byte_size(text)}}
        end
    end

    after_fun = fn
      {[], _} -> {:cont, []}
      {current_chunk, _} -> {:cont, Enum.reverse(current_chunk), []}
    end

    Enum.chunk_while(words, {[], 0}, chunk_fun, after_fun)
  end

  # defp process_line(%{"words" => words}) do
  #   words
  #   |> Enum.reduce({[], 0}, fn word, {acc, acc_len} ->
  #     line_len = String.length(word) + acc_len + if acc_len == 0, do: 0, else: 1
  #
  #     if line_len > 78 do
  #     end
  #   end)
  # end

  # defp process_line(%{"words" => words}) do
  #   words
  #   |> Enum.map(& &1["text"])
  #   |> Enum.reduce({[], 0}, fn word, {acc, acc_len} ->
  #     new_len = String.length(word) + acc_len + if acc_len == 0, do: 0, else: 1
  #
  #     if new_len > 78 do
  #       {[Enum.join(acc, " ")], String.length(word)}
  #     else
  #       {acc ++ [word], new_len}
  #     end
  #   end)
  #   |> IO.inspect()
  #   |> handle_last_accumulator()
  # end

  defp handle_last_accumulator({words, _len}) when is_list(words) do
    [Enum.join(words, " ")]
    |> Enum.map(&split_into_lines/1)
  end

  defp split_into_lines(caption) do
    words = String.split(caption)
    {line1, line2} = split_at_midpoint(words)
    [Enum.join(line1, " "), Enum.join(line2, " ")]
  end

  defp split_at_midpoint(words) do
    midpoint = div(Enum.count(words), 2)
    Enum.split(words, midpoint)
  end
end
