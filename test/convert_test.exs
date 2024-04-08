defmodule BoldTranscriptsEx.ConvertTest do
  use ExUnit.Case

  alias BoldTranscriptsEx.Convert

  describe "text_to_chapters_webvtt" do
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
  end
end
