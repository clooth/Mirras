#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Announcer module
# Providers helpers for responding to messages
#
module Mirras
  module Announcer
    # Reply to a message depending on the prefix
    # Notice the user if !, public channe reply if @
    def reply_to_msg(m, reply)
      # First get the prefix
      prefix = m.message[0]
      # Now act accordingly
      case prefix
      when "!" then m.user.msg(reply, true)
      when "@" then m.reply(reply)
      end
    end
  end
end