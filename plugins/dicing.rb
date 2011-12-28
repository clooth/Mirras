#
# Mirras IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Dicing Plugin
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
    (rand(@sides-1)+1).to_i
  end

  def self.six
    Die.new(6).roll
  end

  def self.twelve
    Die.new(12).roll
  end

  def self.hundred
    Die.new(100).roll
  end
end

# Dicing duel object with bot users, spoils and status
class DicingDuel
  @bet           = nil
  @bet_string    = nil
  @spoils        = nil
  @spoils_string = nil

  @contenders = []
  @rolls      = {}

  @winner = nil
  @loser  = nil

  def initialize(first_user, second_user, bet_info)
    # Save users
    @contenders = [first_user.nick.downcase, second_user.nick.downcase]

    # Parse the given bet and double it
    @bet           = Partyhat::Util.parse_number(bet_info[0])
    @bet_string    = bet_info[0]

    # Calculate spoils
    @spoils        = (@bet * 2).to_f
    @spoils        = (@spoils / 100) * 95
    @spoils_string = Partyhat::Util.shorten_number(@spoils)

    # Store rolls
    @rolls = {}
  end
  attr_accessor :contenders, :rolls, :bet, :bet_string, :spoils, :spoils_string

  def already_rolled?(user)
    @rolls.has_key?(user.nick.downcase)
  end

  def get_roll_for(user)
    @rolls[user.nick.downcase]
  end

  def roll_dice(user)
    @rolls[user.nick.downcase] = (Die.new(6).roll + Die.new(6).roll)
  end

  def finished?
    @rolls.size == 2
  end

  def winning_roll
    @rolls.values.max
  end

  def winning_user
    @rolls.key(winning_roll)
  end

  def losing_roll
    @rolls.values.min
  end

  def losing_user
    @rolls.key(losing_roll)
  end

  def tied?
    losing_roll == winning_roll
  end
end

class Dicing
  include Cinch::Plugin
  include Authentication
  include Mirras::Paintbrush

  # Error messages
  ERR_USER_NOT_PRESENT     = 'I couldn\'t find <col="orange">%s</col> on the channel. Both contenders <col="orange">must be present</col> in the channel before a duel can begin.'
  ERR_USER_ALREADY_DUELING = 'There is already an ongoing duel for <col="orange">%s</col>'
  ERR_USER_DUPLICATED      = 'How is <col="orange">%s</col> supposed to duel alone?'
  ERR_INVALID_BET          = 'The bet <col="orange">"%s"</col> is not valid. Valid bet formats include: <col="orange">50k</col>, <col="orange">100k</col>, <col="orange">1m</col>, <col="orange">200m</col> and <col="orange">1b</col>'
  ERR_NO_DUEL_FOUND        = 'You are currently <col="orange">not in a duel</col>.'
  ERR_NO_DUEL_FOUND_USER   = '<col="orange">%s</col> is currently <col="orange">not in a duel</col>.'
  ERR_ALREADY_ROLLED       = 'You already rolled once, no second tries.'

  # Notice messages
  MSG_NEW_DICING_DUEL      = '<col="orange">New Duel</col> | Pot: <col="orange">%s</col> | Contenders <col="orange">%s</col> and <col="orange">%s</col>, please roll your dice by typing <col="orange">!roll</col> | Good luck!'
  MSG_NEW_DICING_DUEL_ROLL = '<col="orange">%s vs. %s</col> | <col="orange">Duel</col> | <col="orange">Rolling two 6-sided dice</col> | <col="orange">%s</col> rolled a <col="orange">%s</col>'
  MSG_DICING_DUEL_OVER     = '<col="orange">%s vs. %s</col> | <col="orange">Duel ended!</col> | Congratulations, <col="orange">%s</col>, you won! | Spoils: <col="orange">%s</col>'
  MSG_DICING_DUEL_TIED     = '<col="orange">%s vs. %s</col> | <col="orange">Duel ended!</col> | It was a tie.. re-rolling!'
  MSG_DICING_DUEL_STOPPED  = '<col="orange">Duel ended!</col> | The duel between <col="orange">%s</col> and <col="orange">%s</col> was ended'

  MSG_NORMAL_DICE_ROLL     = '<col="orange">Rolling a %s-sided die!</col> | Rolled: <col="orange">%s</col>'
  MSG_COMBINATION_DICE_ROLL= '<col="orange">Rolling %s %s-sided dice!</col> | Rolled: <col="orange">%s</col>'

  def initialize(*args)
    super
    # On going
    @ongoing_duels = []
  end

  # Start a new dicing duel
  # !newdd (name1) (name2) (bet)
  match /newdd (.+) (.+) (.+)/, method: :new_dicing_duel
  def new_dicing_duel(m, first_user, second_user, bet)
    channel = m.channel

    # Get the objects
    first_user  = User(first_user)
    second_user = User(second_user)

    # User validations
    [first_user, second_user].each do |user|
      # Validate users presence in the channel
      return m.reply(brush(ERR_USER_NOT_PRESENT % user))     unless channel.has_user?(user)
      # Validate that the users aren't already in a dicing duel
      return m.reply(brush(ERR_USER_ALREADY_DUELING % user)) unless dicing_duel_for(user).nil?
    end

    # Make sure the usernames aren't the same
    return m.reply(brush(ERR_USER_DUPLICATED % first_user)) if first_user == second_user

    # Validate bet format
    unless bet_match = bet.match(/((\d+)(k|m|b|gp))/i)
      return m.reply(brush(ERR_INVALID_BET % bet))
    end

    # Initiate new dicing duel
    duel = DicingDuel.new(first_user, second_user, bet_match)
    @ongoing_duels << duel

    # Announce
    m.reply(brush(MSG_NEW_DICING_DUEL % [duel.spoils_string, duel.contenders.first, duel.contenders.last]))
  end

  match /stopdd ?(.+)?/, method: :end_dicing_duel
  def end_dicing_duel(m, user)
    duel = dicing_duel_for(user.nick)
    if duel.nil?
      return m.reply(ERR_NO_DUEL_FOUND_USER % user.nick)
    end
    ended = @ongoing_duels.delete(duel)
    return m.reply(MSG_DICING_DUEL_STOPPED % [ended.contenders.first, ended.contenders.last])
  end

  # Dicing duel roll
  match /roll$/i, method: :roll_duel_dice
  def roll_duel_dice(m)
    user = m.user
    duel = dicing_duel_for(user)
    # Duel in progress?
    return m.reply(brush(ERR_NO_DUEL_FOUND % user.nick)) if duel.nil?
    # Already rolled?
    return m.reply(brush(ERR_ALREADY_ROLLED % user.nick)) if duel.already_rolled?(user)

    # Roll the dice!
    m.reply(brush(MSG_NEW_DICING_DUEL_ROLL % [duel.contenders.first, duel.contenders.last, user.nick, duel.roll_dice(user)]))

    # Are we finished?
    if duel.finished?
      # If we have a tie, we need to reroll
      if duel.tied?
        # Grab info
        contenders = duel.contenders
        bet = duel.bet_string
        # Delete old duel
        @ongoing_duels.delete(duel)
        # Notify of the tied duel
        m.reply(brush(MSG_DICING_DUEL_TIED % [duel.contenders.first, duel.contenders.last]))
        # Create new duel
        return new_dicing_duel(m, contenders.first, contenders.last, bet)
      else
        m.reply(brush(MSG_DICING_DUEL_OVER % [duel.contenders.first, duel.contenders.last, duel.winning_user, duel.spoils_string]))
        @ongoing_duels.delete(duel)
        return
      end
    end
  end

  # Normal dice roll
  match /roll (\d+)$/i, method: :roll_normal_dice
  def roll_normal_dice(m, sides)
    m.reply(brush(MSG_NORMAL_DICE_ROLL % [sides.to_i, Die.new(sides.to_i).roll]), true)
  end

  # Combination dice roll
  match /roll (\d+)x(\d+)$/i, method: :roll_combination_dice
  def roll_combination_dice(m, sides, count)
    count = count.to_i
    sides = sides.to_i
    total = 0; count.times { total += Die.new(sides).roll }

    m.reply(brush(MSG_COMBINATION_DICE_ROLL % [count, sides, total]), true)
  end

  private

  def dicing_duel_for(user)
    @ongoing_duels.each do |duel|
      if duel.contenders.include?(user.nick.downcase)
        return duel
      end
    end
    nil
  end
end