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

class Server
  VERSION = "RubIRCd v0.2a"
  RELEASE = "mildly dangerous"
  URL = "http://www.rubircd.org/"
  MODE_ADMIN = 'a'        # is an IRC administrator
  MODE_BOT = 'b'          # is a bot
  MODE_INVISIBLE = 'i'    # invisible in WHO and NAMES output
  MODE_OPERATOR = 'o'     # is an IRC operator
  MODE_PROTECTED = 'p'    # cannot be banned, kicked, or killed
  MODE_REGISTERED = 'r'   # indicates that the nickname is registered
  MODE_SERVER = 's'       # can see server messages such as kills
  MODE_WALLOPS = 'w'      # can receive oper wall messages
  USER_MODES = "abioprsw"
  STATUS_PREFIXES = "~&@+"
  @@client_count = 0
  @@visible_count = 0
  @@invisible_count = 0
  @@unknown_count = 0
  @@oper_count = 0
  @@local_users = 0
  @@global_users = 0
  @@local_users_max = 0
  @@global_users_max = 0
  @@channel_count = 0
  @@link_count = 0
  @@start_timestamp = 0   # holds server startup date and time
  @@data_recv = 0         # amount of data server has received in bytes since it started
  @@data_sent = 0         # amount of data server has sent in bytes since it started
  @@links = Array.new
  @@users = Array.new
  @@admins = Array.new
  @@opers = Array.new
  @@reserved_nicks = Array.new

  def self.init_locks()
    @@client_count_lock = Mutex.new
    @@channel_count_lock = Mutex.new
    @@link_count_lock = Mutex.new
    @@users_lock = Mutex.new
    @@channels_lock = Mutex.new
    @@data_recv_lock = Mutex.new
    @@data_sent_lock = Mutex.new
  end

  def self.init_chanmap
    @@channel_map = {}
  end

  # ToDo: Pass user as an argument and determine if they are invisible, an operator, unknown, etc.
  def self.increment_clients()
    if Options.io_type.to_s == "thread"
      @@client_count_lock.synchronize do
        @@client_count += 1
        @@local_users += 1
        if @@local_users > @@local_users_max
          @@local_users_max = @@local_users
        end
        # ToDo: Handle global users after server linking is implemented
      end
    else
      @@client_count += 1 
      @@local_users += 1 
      if @@local_users > @@local_users_max
        @@local_users_max = @@local_users
      end
    end
  end

  def self.decrement_clients()
    if Options.io_type.to_s == "thread"
      @@client_count_lock.synchronize do
        @@client_count -= 1
        @@local_users -= 1
        # ToDo: Handle global users after server linking is implemented
      end
    else
      @@client_count -= 1
      @@local_users -= 1
    end
  end

  def self.add_user(user)
    if Options.io_type.to_s == "thread"
      @@users_lock.synchronize { @@users.push(user) }
    else
      @@users.push(user)
    end
  end

  def self.remove_user(user)
    if Options.io_type.to_s == "thread"
      @@users_lock.synchronize do
        if @@users.delete(user) != nil
          if user.is_admin || user.is_operator
            Server.oper_count -= 1
          end
          return true
        else
          return false
        end
      end
    else
      if @@users.delete(user) != nil
        if user.is_admin || user.is_operator
          Server.oper_count -= 1
        end
        return true
      else
        return false
      end
    end
  end

  def self.add_channel(channel)
    if Options.io_type.to_s == "thread"
      @@channels_lock.synchronize { @@channel_map[channel.name.upcase] = channel }
    else
      @@channel_map[channel.name.upcase] = channel
    end
  end

  def self.remove_channel(channel)
    if Options.io_type.to_s == "thread"
      @@channels_lock.synchronize { @@channel_map.delete(channel) }
    else
      @@channel_map.delete(channel)
    end
  end

  def self.add_admin(admin)
    @@admins.push(admin)
  end

  def self.add_oper(oper)
    @@opers.push(oper)
  end

  def self.add_reserved_nick(nick)
    @@reserved_nicks.push(nick)
  end

  def self.add_data_recv(amount)
    if Options.io_type.to_s == "thread"
      @@data_recv_lock.synchronize do
        @@data_recv += amount
      end
    else
      @@data_recv += amount
    end
  end

  def self.add_data_sent(amount)
    if Options.io_type.to_s == "thread"
      @@data_sent_lock.synchronize do
        @@data_sent += amount
      end
    else
      @@data_sent += amount
    end
  end

  def self.read_motd()
    begin
      @@motd = IO.readlines("cfg/motd.txt")
    rescue
      puts("failed. Unable to open motd.txt file!")
      exit!
    end
  end

  def self.motd
    @@motd
  end

  def self.users
    @@users
  end

  def self.channel_map
    @@channel_map
  end

  def self.client_count
    if Options.io_type.to_s == "thread"
      @@client_count
    else
      @@client_count
    end
  end

  def self.local_users
    @@local_users
  end

  def self.local_users_max
    @@local_users_max
  end

  def self.admins
    @@admins
  end

  def self.opers
    @@opers
  end

  def self.reserved_nicks
    @@reserved_nicks
  end

  def self.data_recv
    @@data_recv
  end

  def self.data_sent
    @@data_sent
  end

  class << self; attr_accessor :visible_count, :invisible_count, :unknown_count, :oper_count, :global_users, :global_users_max, :start_timestamp, :channel_count, :link_count end
end
