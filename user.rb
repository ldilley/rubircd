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

class User
  # Used to create a new user object when a client connects
  def initialize(nick, ident, hostname, ip_address, gecos, socket, thread)
    @nick = nick
    @ident = ident
    @hostname = hostname
    @server = Options.server_name
    @ip_address = ip_address
    @gecos = gecos
    @is_registered = false
    @is_admin = false
    @is_operator = false
    @is_service = false
    @is_nick_registered = false
    @is_negotiating_cap = false
    @away_message = ""
    @away_since = nil              # gets set to current time when calling AWAY
    @socket = socket
    @thread = thread
    @umodes = Array.new
    @invites = Array.new
    @channels = Array.new
    @session_capabilities = Array.new
    @signon_time = Time.now.to_i
    @last_activity = Time.now.to_i # used to determine whether the client should be pinged
    @last_ping = Time.now.to_i
    @data_recv = 0                 # amount of data client has received from us in bytes
    @data_sent = 0                 # amount of data client has sent to us in bytes
    if Options.io_type.to_s == "thread"
      # Only create locks for items that can change (ident should not for example)
      @nick_lock = Mutex.new
      @hostname_lock = Mutex.new # for vhost support
      @away_lock = Mutex.new
      @umodes_lock = Mutex.new
      @invites_lock = Mutex.new
      @channels_lock = Mutex.new
      @activity_lock = Mutex.new
    end
  end

  def change_nick(new_nick)
    if Options.io_type.to_s == "thread"
      @nick_lock.synchronize { @nick = new_nick }
    else
      @nick = new_nick
    end
  end

  def change_ident(new_ident)
    @ident = new_ident
  end

  def change_hostname(new_hostname)
    if Options.io_type.to_s == "thread"
      @hostname_lock.synchronize { @hostname = new_hostname }
    else
      @hostname = new_hostname
    end
  end

  def change_gecos(new_gecos)
    @gecos = new_gecos
  end

  def set_registered()
    @is_registered = true
  end

  def set_admin()
    @is_admin = true
    add_umode('a')
    Server.oper_count += 1
  end

  def set_operator()
    @is_operator = true
    add_umode('o')
    Server.oper_count += 1
  end

  def set_service()
    @is_service = true
  end

  def set_nick_registered()
    @is_nick_registered = true
  end

  def set_away(message)
    if Options.io_type.to_s == "thread"
      @away_lock.synchronize do
        @away_message = message
        if message.length < 1
          @away_since = ""
        else
          @away_since = Time.now.to_i
        end
      end
    else
      @away_message = message
      @away_since = Time.now.to_i
    end
  end

  def away_message
    @away_message
  end

  def away_since
    @away_since
  end

  def add_umode(umode)
    if Options.io_type.to_s == "thread"
      @umodes_lock.synchronize { @umodes.push(umode) }
    else
      @umodes.push(umode)
    end
  end

  def remove_umode(umode)
    if Options.io_type.to_s == "thread"
      @umodes_lock.synchronize { @umodes.delete(umode) }
    else
      @umodes.delete(umode)
    end
    if umode == 'a'
      @is_admin = false
    end
    if umode == 'o'
      @is_operator = false
    end
  end

  def add_invite(channel)
    if Options.io_type.to_s == "thread"
      @invites_lock.synchronize do
        if invites.length >= Limits::MAXINVITES
          @invites.delete_at(0)
        end
        @invites.push(channel)
      end
    else
      if invites.length >= Limits::MAXINVITES
        @invites.delete_at(0)
      end
      @invites.push(channel)
    end
  end

  def remove_invite(channel)
    if Options.io_type.to_s == "thread"
      @invites_lock.synchronize { @invites.delete(channel) }
    else
      @invites.delete(channel)
    end
  end

  def add_channel(channel)
    if Options.io_type.to_s == "thread"
      @channels_lock.synchronize { @channels.push(channel) }
    else
      @channels.push(channel)
    end
  end

  def remove_channel(channel)
    if Options.io_type.to_s == "thread"
      @channels_lock.synchronize { @channels.delete(channel) }
    else
      @channels.delete(channel)
    end
  end

  def set_last_activity()
    if Options.io_type.to_s == "thread"
      @activity_lock.synchronize { @last_activity = Time.now.to_i }
    else
      @last_activity = Time.now.to_i
    end
  end

  def umodes
    @umodes
  end

  def invites
    @invites
  end

  def last_activity
    @last_activity
  end

  attr_reader :nick, :ident, :hostname, :server, :ip_address, :gecos, :is_registered, :is_admin, :is_operator, :is_service, :is_nick_registered, :thread, :channels, :signon_time
  attr_accessor :socket, :last_ping, :data_recv, :data_sent, :is_negotiating_cap, :session_capabilities
end

class Oper
  def initialize(nick, hash, host)
    @nick = nick
    @hash = hash
    @host = host
  end

  def nick
    @nick
  end

  def hash
    @hash
  end

  def host
    @host
  end
end
