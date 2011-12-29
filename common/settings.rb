#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Settings
# Easy to use channel-specific settings storage
#
# TODO:
# - Custom storage to save settings in channel-specific files to prevent dataloss
# - Global bot settings
#
class Setting
  @name  = nil
  @value = nil
  @possible_values = []
  @errors = nil

  def initialize(name, value, possible_values)
    @name  = name
    @value = value
    @possible_values = possible_values
  end

  def set(value)
    if @possible_values.include? value
      @value  = value
      @errors = nil?
      true
    else
      @errors = "Invalid value for setting \"#{@name}\", possible values include: #{@possible_values.join(', ')}"
      false
    end
  end

  def to_s
    @value
  end

  attr_reader :name, :value, :possible_values, :errors
end

class Settings
  include Cinch::Plugin
  include Mirras::Authentication
  include Mirras::Announcer

  # Initial channel-specific settings
  CHANNEL_SETTINGS = {
    # Public replies for bot commands via the @ command prefix
    "public" => Setting.new("public", "on", ["on", "off"])
  }

  # Possible error messages
  ERRORS = {
    UNKNOWN_SETTING_NAME: "Unknown setting name: %s."
  }

  # Possible reply messages
  MESSAGES = {
    USAGE:     "Settings - Setting values: " + Cinch::Formatting.format(:red, "!set name value") + " - Getting values: " + Cinch::Formatting.format(:red, "!get name"),
    VALUE_SET: "Settings - Value for: %s set to %s.",
    VALUE_GET: "Settings - Value of %s is currently set to %s."
  }

  def initialize(*args)
    super
    storage[:settings] ||= {}
  end

  # Example command formats:
  # !set setting_name setting_value
  # !get setting_name
  match /settings/i,      :method => :usage
  match /set (.+) (.+)/i, :method => :set_setting
  match /get (.+)/i,      :method => :get_setting

  # Set a setting for the current channel
  def set_setting(m, setting_name, setting_value)
    channel = m.channel
    user    = m.user
    # Only ops of the channel or owners of the bot
    # are allowed to set a value for a setting
    if (is_admin?(user) || is_staff?(channel, user))
      channel_name = channel.name
      # Check if a settings object exists for this channel
      # If not, create it with default settings
      if storage[:settings][channel_name].nil?
        create_initial_settings_for channel_name
      end
      channel_settings = storage[:settings][channel_name]
      # Check if a setting object exists for the setting key
      if channel_settings[setting_name].nil?
        return reply_to_msg(m, ERRORS[:UNKNOWN_SETTING_NAME] % setting_name)
      end
      # Attempt to set the value
      if channel_settings[setting_name].set(setting_value) == true
        return reply_to_msg(m, MESSAGES[:VALUE_SET] % [setting_name, setting_value])
      end
      # If there were any errors, we're here still
      return reply_to_msg(m, channel_settings[setting_name].errors)
    end
  end

  # Get a setting's value by its name for the current channel
  def get_setting(m, setting_name)
    channel = m.channel
    user    = m.user
    if (is_admin?(user) || is_staff?(channel, user))
      channel_name = channel.name
      # Check if the setting exists
      if storage[:settings][channel_name].nil?
        create_initial_settings_for channel_name
      end
      channel_settings = storage[:settings][channel_name]
      # Unknown setting name error
      if channel_settings[setting_name].nil?
        return reply_to_msg(m, ERRORS[:UNKNOWN_SETTING_NAME] % setting_name)
      end
      # Setting was found
      return reply_to_msg(m, MESSAGES[:VALUE_GET] % [setting_name, channel_settings[setting_name]])
    end
  end

  # Output some general help on using the Settings commands
  def usage(m)
    reply_to_msg(m, MESSAGES[:USAGE])
  end

  private

  # Set up initial settings hash for the channel in question
  def create_initial_settings_for(channel_name)
    storage[:settings][channel_name] = CHANNEL_SETTINGS
    storage.save
  end
end