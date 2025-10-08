defmodule BoldTranscriptsEx.Convert.LanguageTest do
  use ExUnit.Case

  alias BoldTranscriptsEx.Convert.Language

  doctest BoldTranscriptsEx.Convert.Language

  describe "normalize_deepgram/1" do
    test "normalizes en-US to en_us" do
      assert Language.normalize_deepgram("en-US") == "en_us"
    end

    test "normalizes en-GB to en_uk (special case)" do
      assert Language.normalize_deepgram("en-GB") == "en_uk"
    end

    test "normalizes en-AU to en_au" do
      assert Language.normalize_deepgram("en-AU") == "en_au"
    end

    test "normalizes de-DE to de_de" do
      assert Language.normalize_deepgram("de-DE") == "de_de"
    end

    test "normalizes es-ES to es_es" do
      assert Language.normalize_deepgram("es-ES") == "es_es"
    end

    test "defaults en to en_us" do
      assert Language.normalize_deepgram("en") == "en_us"
    end

    test "adds default region to base language codes" do
      assert Language.normalize_deepgram("de") == "de_de"
      assert Language.normalize_deepgram("es") == "es_es"
      assert Language.normalize_deepgram("fr") == "fr_fr"
    end

    test "handles nil by defaulting to en_us" do
      assert Language.normalize_deepgram(nil) == "en_us"
    end

    test "handles empty string by defaulting to en_us" do
      assert Language.normalize_deepgram("") == "en_us"
    end

    test "handles mixed case" do
      assert Language.normalize_deepgram("EN-US") == "en_us"
      assert Language.normalize_deepgram("De-De") == "de_de"
    end
  end

  describe "normalize_assemblyai/1" do
    test "passes through en_us unchanged" do
      assert Language.normalize_assemblyai("en_us") == "en_us"
    end

    test "passes through en_uk unchanged" do
      assert Language.normalize_assemblyai("en_uk") == "en_uk"
    end

    test "passes through en_au unchanged" do
      assert Language.normalize_assemblyai("en_au") == "en_au"
    end

    test "adds default region to de" do
      assert Language.normalize_assemblyai("de") == "de_de"
    end

    test "adds default region to es" do
      assert Language.normalize_assemblyai("es") == "es_es"
    end

    test "adds default region to fr" do
      assert Language.normalize_assemblyai("fr") == "fr_fr"
    end

    test "handles uppercase by lowercasing" do
      assert Language.normalize_assemblyai("EN_US") == "en_us"
      assert Language.normalize_assemblyai("EN_UK") == "en_uk"
    end

    test "handles nil by defaulting to en_us" do
      assert Language.normalize_assemblyai(nil) == "en_us"
    end

    test "handles empty string by defaulting to en_us" do
      assert Language.normalize_assemblyai("") == "en_us"
    end
  end

  describe "normalize_speechmatics/1" do
    test "normalizes en to en_us" do
      assert Language.normalize_speechmatics("en") == "en_us"
    end

    test "normalizes de to de_de" do
      assert Language.normalize_speechmatics("de") == "de_de"
    end

    test "normalizes es to es_es" do
      assert Language.normalize_speechmatics("es") == "es_es"
    end

    test "normalizes fr to fr_fr" do
      assert Language.normalize_speechmatics("fr") == "fr_fr"
    end

    test "normalizes pt to pt_pt" do
      assert Language.normalize_speechmatics("pt") == "pt_pt"
    end

    test "handles uppercase by lowercasing" do
      assert Language.normalize_speechmatics("EN") == "en_us"
      assert Language.normalize_speechmatics("DE") == "de_de"
    end

    test "handles nil by defaulting to en_us" do
      assert Language.normalize_speechmatics(nil) == "en_us"
    end

    test "handles empty string by defaulting to en_us" do
      assert Language.normalize_speechmatics("") == "en_us"
    end
  end

  describe "normalize/1" do
    test "normalizes en to en_us" do
      assert Language.normalize("en") == "en_us"
    end

    test "passes through other codes unchanged" do
      assert Language.normalize("de_de") == "de_de"
      assert Language.normalize("es_es") == "es_es"
    end

    test "handles nil by defaulting to en_us" do
      assert Language.normalize(nil) == "en_us"
    end

    test "handles empty string by defaulting to en_us" do
      assert Language.normalize("") == "en_us"
    end
  end
end
