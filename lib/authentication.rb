#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Authentication module
# Provides helpers for checking user permissions and ranks
#
module Authentication
  ADMINS = ["Clooth"]

  # Check if a user is an admin of the bot
  def is_admin?(user)
    ADMINS.include?(user.nick)
  end

  # Check if user has higher/or-equal mode than halfop
  def is_staff?(channel, user)
    if channel.owner?(user)
      return true
    elsif channel.opped?(user)
      return true
    elsif channel.half_opped?(user)
      return true
    else
      return false
    end
  end
end