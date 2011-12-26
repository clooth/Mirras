#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Main bot
#

require 'cinch'
require 'cinch/storage/yaml'
require './lib/authentication'
require './lib/announcer'

Dir["./plugins/**/*.rb"].each {|file|
  require file
}

mirras = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.swiftirc.net"
    c.channels = ["#mirras"]
    c.nick = "Mirras"
    c.realname = "Mirras"
    c.user = "Mirras ALPHA"
    c.password = ""
    c.reconnect = true
    c.plugins.plugins = [Settings, Transporter, InviteJoiner]
    c.plugins.prefix = /^[!@]/

    c.storage.backend = Cinch::Storage::YAML
    c.storage.basedir = "./data/"
    c.storage.autosave = true
  end

  # Join a channel
  on :message, /^!join (.+)/ do |m, channel|
    bot.join(channel) if is_admin?(m.user)
  end

  # Part a channel
  on :message, /^!part (.+)/ do |m, channel|
    channel = channel || m.channel

    if channel
      bot.part(channel) if is_admin?(m.user)
    end
  end

  # Send a global message
  on :message, /^!global (.+)/ do |m, text|
    bot.channels.each do |channel|
      Channel(channel).send(Format(:red, "[") + Format(:orange, "GLOBAL") + Format(:red,"]") + " #{text}")
    end
  end
end

mirras.start