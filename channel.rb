# $Id$
# jrIRC
# Copyright (c) 2013 (see authors.txt for details) 
# http://www.devux.org/projects/jrirc/
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
    @create_timestamp = Time.now
  end

  attr_reader :mask  # This is used to locate the unique mask for ban removal
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
  MODE_LIMIT = 'l'      # limit set
  MODE_LOCKED = 'k'     # key set
  MODE_MODERATED = 'm'  # only voiced users can chat
  MODE_NOEXTERN = 'n'   # no external PRIVMSG
  MODE_PRIVATE = 'p'    # will not show up in LIST output
  MODE_REGISTERED = 'r' # channel is registered
  MODE_SECRET = 's'     # will not show up in LIST or WHOIS output
  MODE_TOPIC = 't'      # only channel operators can change topic
  CHANNEL_MODES = "abfilkmnoprstv"
  ISUPPORT_CHANNEL_MODES = "ab,fil,k,mnoprstv" # comma separated modes that accept arguments -- needed for numeric 005 (RPL_ISUPPORT)
  ISUPPORT_PREFIX = "(afov)&~@+"
  @bans
  @name
  @modes
  @topic
  @users
  @founder
  @create_timestamp

  def initialize(name, founder)
    @bans = Array.new
    @name = name
    @modes = Array.new
    @modes.push('n')
    @modes.push('t')
    @topic = ""
    @users = Array.new
    @founder = founder 
    @create_timestamp = Time.now
  end

  def add_ban(creator, mask, reason)
    ban = Ban.new(creator, mask, reason)
    @bans.push(ban)
  end

  def remove_ban(mask)
    @bans.each do |ban|
      if ban.mask == mask
        @bans.delete(ban)
      # else
      # ToDo: send appropriate RPL
      end
    end
  end

  def add_mode(mode)
    @modes.push(mode)
  end

  def remove_mode(mode)
    @modes.delete(mode)
  end

  def clear_modes
    @modes.clear
  end

  def set_topic(new_topic)
    @topic = new_topic
  end

  def add_user(user)
    user_ref = user
    @users.push(user_ref)
  end

  def remove_user(user)
    @users.delete(user)
  end

  def users
    @users
  end

  attr_reader :name, :founder
end
