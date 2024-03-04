defmodule BoldTranscriptsEx do
  def test do
    transcript_data = File.read!("data/transcript.json")
    paragraphs_data = File.read!("data/paragraphs.json")
    sentences_data = File.read!("data/sentences.json")

    {:ok, converted_data} =
      BoldTranscriptsEx.Convert.AssemblyAI.convert(transcript_data,
        paragraphs: paragraphs_data,
        sentences: sentences_data
      )

    File.write("data/output.json", Jason.encode!(converted_data))
  end
end
