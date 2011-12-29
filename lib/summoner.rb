#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Mirras Summoner
# This class takes care of bot spawning and managing.
#
# TODO:
# - Check for nick collision on connect
#
module Mirras
  class Summoner

    # Initialize a new summoner instance
    # Takes default values hash to override defaults
    def initialize(default_values={})
      # Default values used with every instance
      # TODO: Move to YAML
      @defaults = {
        nick:           "Mirras",
        realname:       "Mirras",
        user:           "Mirras Alpha",
        plugins:        [],
        plugins_prefix: /^!|@/,
        channels:       []
      }
      # Possible overriding of default values
      @defaults        = @defaults.merge(default_values)
      # Common plugins for each spawn
      @common_plugins  = []
      # Hash where to store spawned instances of Mirras
      # Each instance is found under the generated identifier
      @spawns          = {}
      # Amount of instances spawned
      @spawns_count    = 0
      # The last spawn instance
      @last_spawn      = nil
      # The last spawn identifier
      @last_identifier = nil
    end
    attr_reader :common_plugins, :spawns, :spawn_count, :last_spawn, :last_identifier
    attr_writer :common_plugins

    # Spawn a new instance of Mirras with given settings
    def spawn(options)
      # Check that all the required keys exist in the options hash
      required_values = [:server]
      required_values.each do |key|
        # If the given options don't include the required minimum options
        # We raise an error and don't let the bot spawn
        unless options.has_key?(key)
          raise InvalidArgumentError("You must provide at least the following parameters: #{required_values.join(', ')}")
        end
      end

      # Merge options with defaults
      options = @defaults.merge(options)

      # Get identifier
      identifier = generate_identifier(options)

      # Format nickname
      prepared_nick = options[:nick] + format_identifier(identifier)

      # Plugins list
      plugins = options[:plugins] | common_plugins

      # Create new instance
      @spawns[identifier] = Cinch::Bot.new do
        configure do |c|
          c.server          = options[:server]
          c.channels        = options[:channels]
          c.nick            = prepared_nick
          c.realname        = options[:realname] || @defaults[:realname]
          c.user            = options[:user] || @defaults[:user]
          c.password        = options[:password] || nil
          c.reconnect       = true
          c.plugins.plugins = plugins
          c.plugins.prefix  = options[:plugins_prefix]
          c.storage.backend = Cinch::Storage::YAML
          c.storage.basedir = "./data/"
          c.storage.autosave = true
        end
      end

      # Save last spawn information
      @last_spawn      = @spawns[identifier]
      @last_identifier = identifier

      # Increase spawn count
      @spawns_count += 1

      @last_spawn
    end

    # Locate an instance by identifier
    def locate_spawn(identifier)
      @spawns[identifier]
    end

    private

    # Figure out the identifier for the spawned bot
    def generate_identifier(options)
      # Custom identifier for the bot
      if options.has_key?(:identifier)
        identifier = options[:identifier]
        # Raise an error if its already in use
        raise InvalidArgumentError("Spawn identifier \"#{options[:identifier]}\" already in use.") if locate_spawn(identifier)
      # If we don't want an identifier at all (i.e. main bot instance)
      elsif options.has_key?(:no_identifier)
        identifier = ""
      # If not, generate the next identifier
      else
        identifier = sprintf("%02x", @spawns_count).upcase
      end
      identifier
    end

    # Format the identifier to be suitable for the nickname
    def format_identifier(identifier)
      identifier.empty? ? identifer : "|%s|" % identifier
    end
  end
end