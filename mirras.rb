require 'cinch'

module Mirras
  # General
  COMMAND_PREFIXES       = "(!|@|.|~)"
  # Dicing
  DICING_RESPONSE_FORMAT = "Rolled: %s"
end

mirras = Cinch::Bot.new do
  configure do |c|
    c.server          = 'irc.swiftirc.net'
    c.channels        = ['#mirras']
    c.nick            = 'Mirras'
    c.realname        = 'Mirras IRC Bot'
    c.user            = 'Mirras ALPHA'
    c.reconnect       = true
  end

  # Dicing
  # Usage: !dice 50x2/6x2/100x1
  # TODO: Abstract into a plugin
  # TODO: Add support for more dice types
  on :message, /#{Mirras::COMMAND_PREFIXES}dice (50x2|6x2|100x1)/ do |m, prefix, roll_type|
    rolled = case roll_type
      when "50x2"  then "#{rand(49)+1} and #{rand(49)+1}"
      when "6x2"   then "#{rand(5)+1} and #{rand(5)+1}"
      when "100x1" then "#{rand(99)+1}"
    end
    m.reply Mirras::DICING_RESPONSE_FORMAT % rolled
  end
end

mirras.start