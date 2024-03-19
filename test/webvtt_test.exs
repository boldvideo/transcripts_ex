defmodule BoldTranscriptsEx.WebVTTTest do
  use ExUnit.Case

  alias BoldTranscriptsEx.WebVTT

  @chapters_vtt_file "test/support/data/chapters.vtt"

  describe "parse_chapters/1" do
    test "parses WebVTT content correctly" do
      # Read the WebVTT file content
      chapters_vtt_content = File.read!(@chapters_vtt_file)

      # Expected output format for the chapters
      expected_chapters = [
        %{start: "0:03", title: "Coming soon: Back to Stanford"},
        %{start: "0:16", title: "Startups: The Mayfield Fellows Program"},
        %{start: "3:22", title: "Wonders of Startup Life: The First Myth"},
        %{start: "8:38", title: "How to Start a Startup: The Community"},
        %{start: "11:33", title: "How Instagram Found the Hardest Problem"},
        %{start: "15:15", title: "Myth #4: Starting a Startup in Stealth"},
        %{start: "21:30", title: "\"Starting a Company Is Not Building a Product\""},
        %{start: "23:01", title: "How to Start a Startup: The Process"},
        %{start: "24:47", title: "What Makes a Startup Startup So Fun?"},
        %{start: "30:21", title: "How To Build a Startup With a Co-Founder"},
        %{start: "33:56", title: "How To Find Your First Engineer"},
        %{start: "34:57", title: "How Did Filters Get Started"},
        %{start: "37:20", title: "Instagram on Hiring and Recruiting"},
        %{start: "38:53", title: "How Do We Think About Work Life Balance?"},
        %{start: "42:17", title: "In the Elevator With Startup Stock"},
        %{start: "45:46", title: "Instagram's Secret to Success"},
        %{start: "48:08", title: "How Do You Resolve Disagreements?"},
        %{start: "50:00", title: "When's the Right Time to Go to Fund?"},
        %{start: "52:12", title: "How To Build a Competent Startup"},
        %{start: "1:07:12", title: "Last Chapter"}
      ]

      # Call the function under test
      actual_chapters = WebVTT.parse_chapters(chapters_vtt_content)

      # Assert that the parsed chapters match the expected output
      assert actual_chapters == expected_chapters
    end
  end
end
