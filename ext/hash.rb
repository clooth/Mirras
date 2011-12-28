#
# Mirras Runescape IRC Bot
# Author: Clooth <zenverse@gmail.com>
# Feature: Hash extensions
# Extend the Hash class to support more things
#
class Hash
  def with_defaults(defaults)
    self.merge(defaults) { |key, old, new| old.nil? ? new : old }
  end

  def with_defaults!(defaults)
    self.merge!(defaults) { |key, old, new| old.nil? ? new : old }
  end
end