defmodule BoldTranscriptsEx.Utils do
  @doc """
  Decodes a binary into json if necessary.
  """
  def maybe_decode(json) when is_binary(json) do
    Jason.decode!(json)
  end

  def maybe_decode(json) when is_map(json) do
    json
  end

  @doc """
  Formats a duration from millisecond or seconds to a chapter timestamp like `01:12:34.000`
  with `HH:MM:SS.000` format (hour, minutes, seconds).
  """
  def format_chapter_timestamp(milliseconds, :millisecond) do
    milliseconds
    |> div(1000)
    |> format_chapter_timestamp(:second)
  end

  def format_chapter_timestamp(seconds, :second) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    seconds = rem(seconds, 60)

    do_format_chapter_timestamp(hours, minutes, seconds)
  end

  defp do_format_chapter_timestamp(hours, minutes, seconds) do
    "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}.000"
  end

  def pad(number, leading_zero_count \\ 2) do
    String.pad_leading(Integer.to_string(number), leading_zero_count, "0")
  end
end
