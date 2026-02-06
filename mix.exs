defmodule BoldTranscriptsEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :bold_transcripts_ex,
      version: "0.8.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/boldvideo/transcripts_ex",
      homepage_url: "https://bold.video",
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
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
    A library for converting transcripts from various providers
    (AssemblyAI, Deepgram, Speechmatics, Mistral) to Bold's unified transcript format.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE llms.txt .formatter.exs),
      links: %{
        "GitHub" => "https://github.com/boldvideo/transcripts_ex",
        "Bold Video" => "https://bold.video"
      }
    ]
  end
end
