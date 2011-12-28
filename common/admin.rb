require 'cinch'

class Admin
  include Cinch::Plugin
  include Cinch::Helpers
  include Authentication
  include Mirras::Paintbrush

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

    m.reply(brush('Okay, I summoned a spawn to <col="orange">%s%s</col>' % [server, channel]))

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

  # List all spawns across networks
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
  match /say (.+)/, method: :say_stuff
  def say_stuff(m, text)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)
    m.reply(brush(text))
  end

  # Joining and parting channels
  match /join (.+)/, method: :join_channel
  def join_channel(m, target)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)

    # Multiple channels
    targets = target.split(' ')
    targets.each do |channel|
      Channel(channel).join
    end

    if targets.size > 0
      m.reply(brush('I entered <col="orange">'+ targets.join(', ') +'</col>'))
    end
  end

  match /leave (.+)/, method: :part_channel
  def part_channel(m, target)
    return m.reply("I'm afraid I can't do that, #{m.user.nick}") unless is_admin?(m.user)

    # Multiple channels
    targets = target.split(' ')
    targets.each do |channel|
      Channel(channel).part
    end

    if targets.size > 0
      m.reply(brush('I left from <col="orange">'+ targets.join(', ') +'</col>'))
    end
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