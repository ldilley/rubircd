# $Id$
# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details) 
# http://www.rubircd.org/
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

class Ban
  def initialize(creator, mask, reason)
    @creator = creator
    @mask = mask
    @reason = reason
    @create_timestamp = Time.now.to_i
  end

  attr_reader :creator, :mask, :reason, :create_timestamp
end

class Channel
  MODE_ADMIN = 'a'      # server administrator
  FLAG_ADMIN = '&'
  MODE_CHANOP = 'o'     # channel operator
  FLAG_CHANOP = '@'
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
  CHANNEL_MODES = "abfiklmnoprstv"
  ISUPPORT_CHANNEL_MODES = "b,k,l,imnprst" # comma separated modes that accept arguments -- needed for numeric 005 (RPL_ISUPPORT)
  ISUPPORT_PREFIX = "(afov)&~@+"
  @bans
  @name
  @key
  @limit
  @modes
  @topic
  @topic_author
  @topic_time
  @users
  @url
  @founder
  @is_registered
  @create_timestamp

  def initialize(name, founder)
    @bans = Array.new
    @name = name
    @key = nil
    @limit = nil
    @modes = Array.new
    @modes.push('n')
    @modes.push('t')
    @topic = ""
    @users = Array.new
    @founder = founder
    @is_registered = false
    @create_timestamp = Time.now.to_i
    if Options.io_type.to_s == "thread"
      @bans_lock = Mutex.new
      @modes_lock = Mutex.new
      @topic_lock = Mutex.new
      @users_lock = Mutex.new
    end
  end

  def set_key(key)
    @key = key
  end

  def set_limit(limit)
    @limit = limit
  end

  def add_ban(creator, mask, reason)
    if Options.io_type.to_s == "thread"
      @bans_lock.synchronize do
        ban = Ban.new(creator, mask, reason)
        @bans.push(ban)
      end
    else
      ban = Ban.new(creator, mask, reason)
      @bans.push(ban)
    end
  end

  def remove_ban(mask)
    if Options.io_type.to_s == "thread"
      @bans_lock.synchronize do
        @bans.each do |ban|
          if ban.mask == mask
            @bans.delete(ban)
          # else
            # ToDo: send appropriate RPL
          end
        end
      end
    else
      @bans.each do |ban|
        if ban.mask == mask
          @bans.delete(ban)
        # else
          # ToDo: send appropriate RPL
        end
      end
    end
  end

  def add_mode(mode)
    if Options.io_type.to_s == "thread"
      @modes_lock.synchronize { @modes.push(mode) }
    else
      @modes.push(mode)
    end
  end

  def remove_mode(mode)
    if Options.io_type.to_s == "thread"
      @modes_lock.synchronize { @modes.delete(mode) }
    else
      @modes.delete(mode)
    end
  end

  def clear_modes
    if Options.io_type.to_s == "thread"
      @modes_lock.synchronize { @modes.clear() }
    else
      @modes.clear()
    end
  end

  def set_topic(user, new_topic)
    if Options.io_type.to_s == "thread"
      @topic_lock.synchronize do
        @topic_author = "#{user.nick}!#{user.ident}@#{user.hostname}"
        @topic = new_topic
        @topic_time = Time.now.to_i
      end
    else
      @topic_author = "#{user.nick}!#{user.ident}@#{user.hostname}"
      @topic = new_topic
      @topic_time = Time.now.to_i
    end
  end

  def set_registered()
    @is_registered = true
  end

  def clear_topic()
    if Options.io_type.to_s == "thread"
      @topic_lock.synchronize do
        @topic_author = ""
        @topic = ""
        @topic_time = ""
      end
    else
      @topic_author = ""
      @topic = ""
      @topic_time = ""
    end
  end

  def add_user(user)
    if Options.io_type.to_s == "thread"
      @users_lock.synchronize do
        user_ref = user
        @users.push(user_ref)
      end
    else
      user_ref = user
      @users.push(user_ref)
    end
  end

  def remove_user(user)
    if Options.io_type.to_s == "thread"
      @users_lock.synchronize { @users.delete(user) }
    else
      @users.delete(user)
    end
  end

  def bans
    @bans
  end

  def users
    @users
  end

  def modes
    @modes
  end

  def create_timestamp
    @create_timestamp
  end

  attr_reader :name, :key, :limit, :topic, :topic_author, :topic_time, :url, :founder, :is_registered
end
