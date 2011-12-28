require 'cinch'

class Admin
  include Cinch::Plugin
  include Authentication
  include Cinch::Helpers

  # Personalized prefixes for admin command
  set(:prefix => Proc.new{|m| "%s: " % m.bot.nick})

  # Spawning new instances of Mirras
  # !spawn server.address [channel [identifier]]
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

    # Everything is OK, so let's spawn a new instance
    $summoner.spawn(options).start
  end

  # Locating other instances
  # !locate identifier
  match /locate ([\w]+)/, method: :locate_instance
  def locate_instance(m, identifier)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)
    located_spawn = $summoner.locate_spawn(identifier)
    unless located_spawn.nil?
      return m.reply("Located spawn " + Format(:red, identifier) + " in " + Format(:red, located_spawn.config.server) + " on channels: #{located_spawn.channels.join(', ')}");
    end
    m.reply("Couldn't find spawn " + Format(:red, identifier));
  end

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

  # Sending commands to other bots
  match /tell ([a-zA-Z0-9]+) to (.+)/, method: :tell_spawn
  def tell_spawn(m, identifier, params)

  end

  match /join (\#[a-zA-Z0-9\-]+)$/, method: :tell_spawn
  def tell_spawn(m, identifier, params)

  end

  private

  def parse_identifier(nick)
    identifier = nick.scan(/\|(.+)\|/)
    identifier.pop.pop unless identifier.empty?
  end

end