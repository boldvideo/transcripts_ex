defmodule BoldTranscriptsEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :bold_transcripts_ex,
      version: "0.4.2",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
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
      {:jason, "~> 1.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
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
        "GitHub" => "https://github.com/bold-app/bold_transcripts_ex"
      }
    ]
  end
end
