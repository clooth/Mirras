#
# Mirras IRC Bot
# Author: Clooth <zenverse@gmail.com>
# WWW: http://github.com/Clooth
# Module: Mirras
# Submodule: Paintbrush
#
# Allows easier coloring and styling of messages via html-like tags
#
module Mirras
  module Paintbrush
    Colors = {
      :white  => "00",
      :black  => "01",
      :blue   => "02",
      :green  => "03",
      :red    => "04",
      :brown  => "05",
      :purple => "06",
      :orange => "07",
      :yellow => "08",
      :lime   => "09",
      :teal   => "10",
      :aqua   => "11",
      :royal  => "12",
      :pink   => "13",
      :grey   => "14",
      :silver => "15",
    }

    Styles = {
      :bold       => 2.chr,
      :underlined => 31.chr,
      :underline  => 31.chr,
      :reversed   => 22.chr,
      :reverse    => 22.chr,
      :italic     => 22.chr,
      :reset      => 15.chr,
    }

    COLOR_START_TAG_REGEXP = /<col=\"([a-zA-Z,]+)\">/
    COLOR_END_TAG_REGEXP   = /<\/col>/

    def brush(text)
      parse_text_styles(parse_text_colors(text))
    end

    protected

    def parse_text_styles(text)
      text
    end

    def parse_text_colors(text)
      open_tags  = 0
      close_tags = 0
      text.scan(/(<col=\"([\w,]+)\">)(((?!<col).)*)(<\/col>)/).each do |values|
        start_tag, colors, content, x, end_tag = values

        colors = colors.split(",").take(2).inject([]) do |a,v|
          a << Colors[v.to_sym]; a
        end

        text.gsub!(/#{start_tag}/, "\x03%s" % colors.join(","))
        text.gsub!(/#{end_tag}/,   Styles[:reset])
      end
      text
    end
  end
end