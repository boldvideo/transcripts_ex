defmodule BoldTranscriptsEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :bold_transcripts_ex,
      version: "0.6.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A library for converting transcripts from various providers (AssemblyAI, Deepgram)
    to Bold's unified transcript format.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/boldvideo/transcripts_ex",
        "Bold Video" => "https://bold.video"
      }
    ]
  end
end
