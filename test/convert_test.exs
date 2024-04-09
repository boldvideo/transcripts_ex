defmodule BoldTranscriptsEx.ConvertTest do
  use ExUnit.Case

  alias BoldTranscriptsEx.Convert

  doctest BoldTranscriptsEx.Convert

  describe "text_to_chapters_webvtt/2" do
    test "converts a text input into chapters WebVTT format" do
      input = "00:00 Hello World\n00:37 Introduction\n01:59 The End\n\n"
      output = Convert.text_to_chapters_webvtt(input, 155)

      assert output == """
             WEBVTT

             1
             00:00:00.000 -> 00:00:37.000
             Hello World

             2
             00:00:37.000 -> 00:01:59.000
             Introduction

             3
             00:01:59.000 -> 00:02:35.000
             The End

             """
    end

    test "removes lines it cannot parse" do
      input = "00:00 Hello World\n00: Introduction\n01:59\n02:12 The End\n\n"
      output = Convert.text_to_chapters_webvtt(input, 155)

      assert output == """
             WEBVTT

             1
             00:00:00.000 -> 00:02:12.000
             Hello World

             2
             00:02:12.000 -> 00:02:35.000
             The End

             """
    end

    test "sorts timestamps" do
      input = "01:59 The End\n00:30 Hello World\n\n"
      output = Convert.text_to_chapters_webvtt(input, 155)

      assert output == """
             WEBVTT

             1
             00:00:30.000 -> 00:01:59.000
             Hello World

             2
             00:01:59.000 -> 00:02:35.000
             The End

             """
    end

    test "handles single-digit timestamps" do
      input = "0:12 The Start\n02:33 The End\n\n"
      output = Convert.text_to_chapters_webvtt(input, 155)

      assert output == """
             WEBVTT

             1
             00:00:12.000 -> 00:02:33.000
             The Start

             2
             00:02:33.000 -> 00:02:35.000
             The End

             """
    end

    test "handles hour timestamps as well" do
      input = "00:00 The Start\n1:00:01 Introduction\n01:02:33 The End\n\n"
      output = Convert.text_to_chapters_webvtt(input, 3755)

      assert output == """
             WEBVTT

             1
             00:00:00.000 -> 01:00:01.000
             The Start

             2
             01:00:01.000 -> 01:02:33.000
             Introduction

             3
             01:02:33.000 -> 01:02:35.000
             The End

             """
    end

    test "returns nil if no valid chapters can be found" do
      input = "01: The End\n"
      assert Convert.text_to_chapters_webvtt(input, 155) == nil
    end
  end

  describe "chapters_webvtt_to_text/1" do
    test "converts a chapters WebVTT text into a text with one chapter per line" do
      input = """
      WEBVTT

      1
      00:00:00.000 -> 00:00:37.000
      Hello World

      2
      00:00:37.000 -> 00:01:59.000
      Introduction

      3
      00:01:59.000 -> 00:02:35.000
      The End
      """

      output = Convert.chapters_webvtt_to_text(input)

      assert output == "00:00 Hello World\n00:37 Introduction\n01:59 The End"
    end
  end
end
