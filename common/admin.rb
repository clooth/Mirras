#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Module: Mirras Admin Plugin
# This plugin allows bot admins to manage the spawns
# Features:
#   spawn server.hostname [channel_to_join [spawn_identifier]]
#     Spawns a new bot instance with an incremented (or custom)
#     identifier to the specific network & channel
#   locate bot_identifier
#     Returns what server the spawn is on and which channels
#   list our spawns
#     List all currently connected spawns, their networks and channels they're on
#   say channel message
#   say message
#     Say the given message on the current (or specified) channel
#   join channel_name
#     Join the specified channel
#
require 'cinch'

class Admin
  include Cinch::Plugin
  include Cinch::Helpers
  include Authentication
  include Mirras::Paintbrush

  # All admin commands are prefixed by the bot's name
  # So we don't get a shitload of
  set(:prefix => Proc.new{|m| "%s: " % m.bot.nick})

  # Set up some initial storage for admin plugin settings
  def initialize(*args)
    super
    storage[:settings] ||= {}
  end

  # Spawning new instances of Mirras
  # Mirras: spawn server.address [channel [identifier]]
  match /spawn ([\w\.]+) ?([\w\#\-]+)? ?([a-zA-Z0-9]+)?$/, :method => :spawn_instance
  def spawn_instance(m, server, channel=nil, identifier=nil)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)

    options = {}

    # Validate given server
    if server != "localhost" && server.match(/^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}$/).nil?
      return m.reply("At least give me a valid server..")
    end
    options[:server] = server

    # Validate given channel
    unless channel.nil?
      if channel.match(/^\#[a-zA-Z0-9\-]+$/).nil?
        return m.reply("At least give me a valid channel..")
      end
      options[:channels] = channel.to_a
    end

    # Validate identifier
    unless identifier.nil?
      located_spawn = $summoner.locate_spawn(identifier)
      unless located_spawn.nil?
        return m.reply("Identifier already in use.")
      end
      options[:identifier] = identifier
    end

    m.reply(brush('Okay, I summoned a spawn to <col="orange">%s%s</col>' % [server, channel]))

    # Everything is OK, so let's spawn a new instance
    $summoner.spawn(options).start
  end

  # Locating other instances
  # Mirras: locate identifier
  match /locate ([\w]+)/, method: :locate_instance
  def locate_instance(m, identifier)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)
    located_spawn = $summoner.locate_spawn(identifier)
    unless located_spawn.nil?
      return m.reply("Located spawn " + Format(:red, identifier) + " in " + Format(:red, located_spawn.config.server) + " on channels: #{located_spawn.channels.join(', ')}");
    end
    m.reply("Couldn't find spawn " + Format(:red, identifier));
  end

  # List all spawns across networks
  # Mirras: list our spawns
  match /list our spawns$/, method: :list_spawns
  def list_spawns(m)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)
    all_spawns = $summoner.spawns
    all_spawns.each do |identifier, spawn|
      server = spawn.config.server
      channels = spawn.channels.join(', ')
      m.reply("Spawn #{Format(:red, identifier)} is on #{server} in #{channels}")
    end
  end

  # Saying the specified text on the current or the wanted channel
  # Mirras: say lol
  # Mirras: say #mirras hello
  match /say (.+)/, method: :say_stuff
  def say_stuff(m, text, channel=nil)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)
    m.reply(brush(text))
  end

  # Joining and parting channels
  match /join (.+)/, method: :join_channel
  def join_channel(m, target)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)

    if m.bot.channels.include? Channel(target)
      m.reply(brush('I\'m already there..'))
    else
      m.reply(brush('I entered <col="orange">'+ target +'</col>'))
    end
  end

  match /leave (.+)/, method: :part_channel
  def part_channel(m, target)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)

    channel = Channel(target)

    unless channel.is_a? Channel
      return m.reply(brush('Uhh.. what?'))
    end

    if m.bot.channels.include? channel
      channel.part
    else
      return m.reply(brush('How can I leave from where I\'m not..?'))
    end

    m.reply(brush('I left from <col="orange">'+ channel.name +'</col>'))
  end

  # Disconnecting and reconnecting
  match /disconnect$/, method: :disconnect
  def disconnect(m)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)
    m.bot.quit("Farewell my friends.")
  end

  private

  def parse_identifier(nick)
    identifier = nick.scan(/\|(.+)\|/)
    identifier.pop.pop unless identifier.empty?
  end

end