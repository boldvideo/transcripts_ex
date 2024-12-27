defmodule BoldTranscriptsEx.Utils.ChaptersTest do
  use ExUnit.Case

  alias BoldTranscriptsEx.Utils.Chapters

  @chapters_vtt_file "test/support/data/chapters.vtt"

  describe "parse_chapters/1" do
    test "parses WebVTT content correctly" do
      # Read the WebVTT file content
      chapters_vtt_content = File.read!(@chapters_vtt_file)

      # Expected output format for the chapters
      expected_chapters = [
        %{start: "0:03", title: "Coming soon: Back to Stanford", end: "0:16"},
        %{start: "0:16", title: "Startups: The Mayfield Fellows Program", end: "3:22"},
        %{start: "3:22", title: "Wonders of Startup Life: The First Myth", end: "8:38"},
        %{start: "8:38", title: "How to Start a Startup: The Community", end: "11:33"},
        %{start: "11:33", title: "How Instagram Found the Hardest Problem", end: "15:13"},
        %{start: "15:15", title: "Myth #4: Starting a Startup in Stealth", end: "21:27"},
        %{
          start: "21:30",
          title: "\"Starting a Company Is Not Building a Product\"",
          end: "22:58"
        },
        %{start: "23:01", title: "How to Start a Startup: The Process", end: "24:47"},
        %{start: "24:47", title: "What Makes a Startup Startup So Fun?", end: "30:20"},
        %{start: "30:21", title: "How To Build a Startup With a Co-Founder", end: "33:56"},
        %{start: "33:56", title: "How To Find Your First Engineer", end: "34:56"},
        %{start: "34:57", title: "How Did Filters Get Started", end: "37:19"},
        %{start: "37:20", title: "Instagram on Hiring and Recruiting", end: "38:53"},
        %{start: "38:53", title: "How Do We Think About Work Life Balance?", end: "42:17"},
        %{start: "42:17", title: "In the Elevator With Startup Stock", end: "45:45"},
        %{start: "45:46", title: "Instagram's Secret to Success", end: "48:05"},
        %{start: "48:08", title: "How Do You Resolve Disagreements?", end: "50:00"},
        %{start: "50:00", title: "When's the Right Time to Go to Fund?", end: "52:12"},
        %{start: "52:12", title: "How To Build a Competent Startup", end: "54:31"},
        %{start: "1:07:12", title: "Last Chapter", end: "1:29:31"}
      ]

      # Call the function under test
      actual_chapters = Chapters.parse_chapters(chapters_vtt_content)

      # Assert that the parsed chapters match the expected output
      assert actual_chapters == expected_chapters
    end
  end

  describe "chapters_to_webvtt/1" do
    test "converts chapter data to WebVTT format correctly" do
      chapters = [
        %{start: "00:00:03", end: "00:00:16", title: "Coming soon: Back to Stanford"},
        %{start: "00:00:16", end: "00:03:22", title: "Startups: The Mayfield Fellows Program"},
        %{start: "00:03:22", end: "00:08:38", title: "Wonders of Startup Life: The First Myth"},
        %{start: "00:52:12", end: "00:54:31", title: "How To Build a Competent Startup"},
        %{start: "00:54:31", title: "Last Chapter"}
      ]

      expected_webvtt_content = """
      WEBVTT

      1
      00:00:03.000 --> 00:00:16.000
      Coming soon: Back to Stanford

      2
      00:00:16.000 --> 00:03:22.000
      Startups: The Mayfield Fellows Program

      3
      00:03:22.000 --> 00:08:38.000
      Wonders of Startup Life: The First Myth

      4
      00:52:12.000 --> 00:54:31.000
      How To Build a Competent Startup

      5
      00:54:31.000 --> 99:59:59.999
      Last Chapter
      """

      actual_webvtt_content = Chapters.chapters_to_webvtt(chapters)

      assert String.trim_trailing(actual_webvtt_content) ==
               String.trim_trailing(expected_webvtt_content)
    end
  end
end
