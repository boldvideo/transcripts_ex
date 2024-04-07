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
end
