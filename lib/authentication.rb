#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Authentication module
# Provides helpers for checking user permissions and ranks
# TODO: Store admin information in a YAML hash
#
module Mirras
  module Authentication
    ADMINS = ["Clooth", "Clooth_"]

    # Check if a user is an admin of the bot
    def is_admin?(user)
      ADMINS.include?(user.nick)
    end

    # Check if user has higher/or-equal mode than halfop
    def is_staff?(channel, user)
      case user
      when channel.owner?(user)
      when channel.opped?(user)
      when channel.half_opped?(user)
        return true
      end
      false
    end
  end
end