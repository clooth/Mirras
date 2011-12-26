#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Dicing
# Simple Dicing:
# <actor1> !roll 100x1
# <mirras> actor1: Rolled 56

# Dice object, can be multiple sided
class Die
  @sides = 6

  # Create a new die with the given sides
  def initialize(sides)
    @sides = sides
  end

  # Perform a roll on the die
  def roll
    (rand(@sides-1)+1)
  end
end

class Dicing
  include Cinch::Plugin

  # Error messages
  # Notice messages

  def initialize(*args)
    super
    storage[:dicing] = {}
  end

  # Normal dicing methods include !dice and !roll
  match /(dice|roll) (.+)/i, method: :roll_single_mode

  # Perform a normal single-player dice roll
  def roll_single_mode(m, mode)
    channel = m.channel
    user    = m.user
  end
end
=begin
class Dicing
  include Cinch::Plugin
  RESPONSE = "Rolled: %s"

  match /dice (.+)/i
  def perform_roll(message, roll_type)
    channel = message.channel
    user    = message.user
    if channel.owner?(user) || channel.opped?(user) ||
       channel.voiced?(user) || channel.half_opped?(user)
      if roll_type == "50x2"
        return RESPONSE % "#{rand(49)+1} and #{rand(49)+1}"
      elsif roll_type == "100x1"
        return RESPONSE % "#{rand(99)+1}"
      end
    end
    if roll_type == "6x2"
      return RESPONSE % "#{rand(5)+1} and #{rand(5)+1}"
    end
    if roll_type == "12x1"
      return RESPONSE % "#{rand(11)+1}"
    end
  end

  def execute(m, roll_type)
    roll = perform_roll(m, roll_type)
    unless roll.nil?
      m.reply(roll, true)
    else
      m.reply("Possible dicing parameters are: 6x2, 12x1, 50x2 and 100x1", true)
    end
  end
end
=end