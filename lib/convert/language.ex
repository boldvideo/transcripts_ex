defmodule BoldTranscriptsEx.Convert.Language do
  @moduledoc """
  Language code normalization for transcript vendors.

  Converts vendor-specific language codes to a unified internal format:
  - Underscore-separated lowercase: `en_us`, `en_uk`, `de_de`
  - Base English defaults to `en_us`
  - Base languages get default region: `de` → `de_de`, `es` → `es_es`

  ## Vendor Formats

  - **Deepgram**: BCP-47 format (`en-US`, `en-GB`, `de-DE`)
  - **AssemblyAI**: Underscore format (`en_us`, `en_uk`, `de`)
  - **Speechmatics**: Base language only (`en`, `de`, `es`)
  """

  @doc """
  Normalizes Deepgram BCP-47 language codes to internal format.

  ## Examples

      iex> BoldTranscriptsEx.Convert.Language.normalize_deepgram("en-US")
      "en_us"

      iex> BoldTranscriptsEx.Convert.Language.normalize_deepgram("en-GB")
      "en_uk"

      iex> BoldTranscriptsEx.Convert.Language.normalize_deepgram("de-DE")
      "de_de"

      iex> BoldTranscriptsEx.Convert.Language.normalize_deepgram("en")
      "en_us"

      iex> BoldTranscriptsEx.Convert.Language.normalize_deepgram(nil)
      "en_us"
  """
  def normalize_deepgram(nil), do: "en_us"
  def normalize_deepgram(""), do: "en_us"

  def normalize_deepgram(code) when is_binary(code) do
    code
    |> String.downcase()
    |> String.replace("-", "_")
    |> handle_deepgram_special_cases()
  end

  defp handle_deepgram_special_cases("en_gb"), do: "en_uk"
  defp handle_deepgram_special_cases("en"), do: "en_us"

  defp handle_deepgram_special_cases(code) do
    case String.contains?(code, "_") do
      true -> code
      false -> add_default_region(code)
    end
  end

  @doc """
  Normalizes AssemblyAI underscore-format language codes to internal format.

  ## Examples

      iex> BoldTranscriptsEx.Convert.Language.normalize_assemblyai("en_us")
      "en_us"

      iex> BoldTranscriptsEx.Convert.Language.normalize_assemblyai("en_uk")
      "en_uk"

      iex> BoldTranscriptsEx.Convert.Language.normalize_assemblyai("de")
      "de_de"

      iex> BoldTranscriptsEx.Convert.Language.normalize_assemblyai("EN_US")
      "en_us"

      iex> BoldTranscriptsEx.Convert.Language.normalize_assemblyai(nil)
      "en_us"
  """
  def normalize_assemblyai(nil), do: "en_us"
  def normalize_assemblyai(""), do: "en_us"

  def normalize_assemblyai(code) when is_binary(code) do
    normalized = String.downcase(code)

    case String.contains?(normalized, "_") do
      true -> normalized
      false -> add_default_region(normalized)
    end
  end

  @doc """
  Normalizes Speechmatics base language codes to internal format.

  ## Examples

      iex> BoldTranscriptsEx.Convert.Language.normalize_speechmatics("en")
      "en_us"

      iex> BoldTranscriptsEx.Convert.Language.normalize_speechmatics("de")
      "de_de"

      iex> BoldTranscriptsEx.Convert.Language.normalize_speechmatics("es")
      "es_es"

      iex> BoldTranscriptsEx.Convert.Language.normalize_speechmatics("fr")
      "fr_fr"

      iex> BoldTranscriptsEx.Convert.Language.normalize_speechmatics(nil)
      "en_us"
  """
  def normalize_speechmatics(nil), do: "en_us"
  def normalize_speechmatics(""), do: "en_us"

  def normalize_speechmatics(code) when is_binary(code) do
    code
    |> String.downcase()
    |> add_default_region()
  end

  @doc """
  Generic language code normalizer with fallback to en_us.

  ## Examples

      iex> BoldTranscriptsEx.Convert.Language.normalize("en")
      "en_us"

      iex> BoldTranscriptsEx.Convert.Language.normalize(nil)
      "en_us"

      iex> BoldTranscriptsEx.Convert.Language.normalize("")
      "en_us"
  """
  def normalize(nil), do: "en_us"
  def normalize(""), do: "en_us"

  def normalize(code) when is_binary(code) do
    case String.downcase(code) do
      "en" -> "en_us"
      other -> other
    end
  end

  # Private helper to add default regional variants
  defp add_default_region("en"), do: "en_us"
  defp add_default_region(lang), do: "#{lang}_#{lang}"
end
