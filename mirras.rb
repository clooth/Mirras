#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Main bot
#
require 'partyhat'
require 'cinch'
require 'cinch/storage/yaml'

# Require extensions
Dir["./ext/**/*.rb"].each {|file|
  require file
}

# Require core modules
require './lib/authentication'
require './lib/paintbrush'
require './lib/announcer'
require './lib/summoner'

# New summoner instance
$summoner = Summoner.new

# Require common plugins
Dir["./common/**/*.rb"].each {|file|
  require file
}

# Require all plugins
Dir["./plugins/**/*.rb"].each {|file|
  require file
}

# Set some shared plugins for all bots
$summoner.common_plugins = [Admin, Dicing]

# Spawn a new instance of the bot
$summoner.spawn(
  server:   ARGV[0] || "local.irc.dev",
  channels: ARGV[1].to_a || ["#dev"],
  password: "",
  plugins:  [Google, Dicing, InviteJoiner]
)

$summoner.last_spawn.start

=begin
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
=end