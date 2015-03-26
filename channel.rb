# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details)
# http://www.rubircd.rocks/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Represents a ban record
class Ban
  def initialize(creator, mask, reason)
    @creator = creator
    @mask = mask
    @reason = reason
    @create_timestamp = Time.now.to_i
  end

  attr_reader :creator, :mask, :reason, :create_timestamp
end

# Contains the properties of an IRC channel along
# with some static utility methods
class Channel
  MODE_ADMIN = 'a'      # server administrator
  FLAG_ADMIN = '&'
  MODE_OPER = 'z'       # IRC operator
  FLAG_OPER = '!'
  MODE_CHANOP = 'o'     # channel operator
  FLAG_CHANOP = '@'
  MODE_HALFOP = 'h'     # half operator
  FLAG_HALFOP = '%'
  MODE_VOICE = 'v'      # can chat in moderated channels
  FLAG_VOICE = '+'
  MODE_FOUNDER = 'f'    # if nick is registered and is founder of the channel
  FLAG_FOUNDER = '~'
  MODE_BAN = 'b'        # ban
  MODE_INVITE = 'i'     # invite only
  MODE_LOCKED = 'k'     # key set
  MODE_LIMIT = 'l'      # limit set
  MODE_MODERATED = 'm'  # only voiced users can chat
  MODE_NOEXTERN = 'n'   # no external PRIVMSG
  MODE_PRIVATE = 'p'    # will not show up in LIST output
  MODE_REGISTERED = 'r' # channel is registered
  MODE_SECRET = 's'     # will not show up in LIST or WHOIS output
  MODE_TOPIC = 't'      # only channel operators can change topic
  CHANNEL_MODES = 'abfhiklmnoprstvz'
  ISUPPORT_CHANNEL_MODES = 'b,k,l,imnprst' # comma-separated modes that accept arguments -- needed for numeric 005 (RPL_ISUPPORT)
  ISUPPORT_PREFIX = '(azfohv)&!~@%+'

  def initialize(name, founder)
    @bans = []
    @name = name
    @key = nil
    @limit = nil
    @modes = []
    @modes.push('n')
    @modes.push('t')
    @topic = ''
    @topic_author = nil
    @topic_time = nil
    @users = []
    @invisible_users = [] # users who IJOIN
    @url = nil
    @founder = founder
    @registered = false
    @create_timestamp = Time.now.to_i
    return unless Options.io_type.to_s == 'thread'
    @bans_lock = Mutex.new
    @modes_lock = Mutex.new
    @topic_lock = Mutex.new
    @users_lock = Mutex.new
  end

  def key=(key)
    @mode_lock.lock if Options.io_type.to_s == 'thread'
    @key = key
    @mode_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def limit=(limit)
    @mode_lock.lock if Options.io_type.to_s == 'thread'
    @limit = limit
    @mode_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.valid_channel_name?(channel)
    if channel =~ /^[#][A-Za-z0-9_!-]*$/
      return true
    else
      return false
    end
  end

  def add_ban(creator, mask, reason)
    @bans_lock.lock if Options.io_type.to_s == 'thread'
    ban = Ban.new(creator, mask, reason)
    @bans.push(ban)
    @bans_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_ban(mask)
    @bans_lock.lock if Options.io_type.to_s == 'thread'
    @bans.each do |ban|
      next unless ban.mask == mask
      @bans.delete(ban)
      # TODO: else send appropriate RPL
    end
    @bans_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def add_mode(mode)
    @modes_lock.lock if Options.io_type.to_s == 'thread'
    @modes.push(mode)
    @modes_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_mode(mode)
    @modes_lock.lock if Options.io_type.to_s == 'thread'
    @modes.delete(mode)
    @modes_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def clear_modes
    @modes_lock.lock if Options.io_type.to_s == 'thread'
    @modes.clear
    @modes_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def mode?(mode)
    if Options.io_type.to_s == 'thread'
      @modes_lock.synchronize { @modes.include?(mode) }
    else
      @modes.include?(mode)
    end
  end

  def set_topic(user, new_topic)
    @topic_lock.lock if Options.io_type.to_s == 'thread'
    @topic_author = "#{user.nick}!#{user.ident}@#{user.hostname}"
    @topic = new_topic
    @topic_time = Time.now.to_i
    @topic_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def registered=(registered)
    @modes_lock.lock if Options.io_type.to_s == 'thread'
    @registered = registered
    @modes_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def clear_topic
    @topic_lock.lock if Options.io_type.to_s == 'thread'
    @topic_author = ''
    @topic = ''
    @topic_time = ''
    @topic_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def nick_in_channel?(nick)
    if Options.io_type.to_s == 'thread'
      @users_lock.synchronize do
        @users.each do |u|
          return true if u.nick.casecmp(nick) == 0
        end
      end
      return false
    else
      @users.each do |u|
        return true if u.nick.casecmp(nick) == 0
      end
      return false
    end
  end

  def invisible_nick_in_channel?(nick)
    if Options.io_type.to_s == 'thread'
      @users_lock.synchronize do
        @invisible_users.each do |iu|
          return true if iu.nick.casecmp(nick) == 0
        end
      end
      return false
    else
      @invisible_users.each do |iu|
        return true if iu.nick.casecmp(nick) == 0
      end
      return false
    end
  end

  def add_user(user)
    @users_lock.lock if Options.io_type.to_s == 'thread'
    user_ref = user
    @users.push(user_ref)
    @users_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_user(user)
    @users_lock.lock if Options.io_type.to_s == 'thread'
    @users.delete(user)
    @users_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def add_invisible_user(user)
    @users_lock.lock if Options.io_type.to_s == 'thread'
    @invisible_users << user
    @users_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_invisible_user(user)
    @users_lock.lock if Options.io_type.to_s == 'thread'
    @invisible_users.delete(user)
    @users_lock.unlock if Options.io_type.to_s == 'thread'
  end

  attr_reader :bans, :name, :key, :limit, :modes, :topic, :topic_author, :topic_time, :users, :invisible_users, :url, :founder, :registered, :create_timestamp
end
