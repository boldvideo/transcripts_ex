defmodule BoldTranscriptsEx.WebVTT2 do
  require Logger

  def create(transcript) do
    transcript["utterances"]
    |> Enum.map(&process_line/1)
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
end
