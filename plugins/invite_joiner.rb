#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: InviteJoiner
# Somewhat fun way to allow the bot to join channels on invite
#
class InviteJoiner
  include Cinch::Plugin
  include Authentication

  # Give the bot permission to join
  POSITIVE_ANSWERS = [
    "yeh", "ok", "sure", "yeah", "yes", "kk", "go on",
    "why not", "maybe this time", "don't be too late",
    "come back for dinner"
  ]

  # Don't give permission
  NEGATIVE_ANSWERS = [
    "no", "nope", "noep", "noep lol", "lolno", "fuck no",
    "you wish", "stfu", "not this time", "no they're assholes"
  ]

  # Positive responses in case given permission to join
  POSITIVE_RESPONSES = [
    "Yay!", "Thanks dad! <3", "Woot!", "Awesome!", "I'm going in...",
    "I'll be good!"
  ]

  # Negative responses in case not given permission
  NEGATIVE_RESPONSES = [
    "Okay :(", ":'(", "Asshole.", "Fine.", "You never loved me anyway.",
    "Whatever.", "I didn't want to anyway.", "They probably didn't have cookies anyway.",
    "I suppose I could've been exploited sexually."
  ]

  def initialize(*args)
    super
    @permission_asked = false
    @asked_channel    = nil
  end

  listen_to :invite,  :method => :join_on_invite
  def join_on_invite(message)
    # If we haven't asked for permission yet
    if @permission_asked == false
      Channel("#mirras").send("Clooth: #{message.user.nick} wants me to join #{message.channel}, can I go?")
      @permission_asked = true
      @asked_channel = message.channel
    end
  end

  listen_to :message, :method => :deal_with_responses
  def deal_with_responses(message)
    # Should we do anything?
    return unless @permission_asked == true
    return unless is_admin?(message.user)
    # Were we shown green light?
    unless message.message.scan(/^(#{POSITIVE_ANSWERS.join('|')})$/).empty?
      Channel("#mirras").send(POSITIVE_RESPONSES[rand(POSITIVE_RESPONSES.size)])
      bot.join(@asked_channel)
      @permission_asked = false
      @asked_channel = nil
      return
    end
    # No?
    unless message.message.scan(/^(#{NEGATIVE_ANSWERS.join('|')})$/).empty?
      Channel("#mirras").send(NEGATIVE_RESPONSES[rand(NEGATIVE_RESPONSES.size)])
      @permission_asked = false
      @asked_channel = nil
      return
    end
  end
end