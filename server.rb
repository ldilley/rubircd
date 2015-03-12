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

class Server
  VERSION = "RubIRCd v0.2a"
  RELEASE = "mildly dangerous"
  URL = "http://www.rubircd.rocks/"
  MODE_ADMIN = 'a'        # is an IRC administrator
  MODE_BOT = 'b'          # is a bot
  MODE_INVISIBLE = 'i'    # invisible in WHO and NAMES output
  MODE_OPERATOR = 'o'     # is an IRC operator
  MODE_REGISTERED = 'r'   # indicates that the nickname is registered
  MODE_SERVER = 's'       # can see server messages such as kills
  MODE_VERBOSE = 'v'      # can see client connect/quit messages
  MODE_WALLOPS = 'w'      # can receive oper wall messages
  USER_MODES = "abiorsvwx"
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
  @@friendly_start_date = 0 # holds server start date and time in friendly format
  @@start_timestamp = 0     # holds server start timestamp in integer format
  @@data_recv = 0           # amount of data server has received in bytes since it started
  @@data_sent = 0           # amount of data server has sent in bytes since it started
  @@links = Array.new
  @@users = Array.new
  @@admins = Array.new
  @@opers = Array.new

  def self.init_locks()
    @@client_count_lock = Mutex.new
    @@channel_count_lock = Mutex.new
    @@link_count_lock = Mutex.new
    @@users_lock = Mutex.new
    @@channels_lock = Mutex.new
    @@data_recv_lock = Mutex.new
    @@data_sent_lock = Mutex.new
  end

  def self.init_chanmap()
    @@channel_map = {}
  end

  def self.init_whowas()
    @@whowas_mod = Command::Standard::Whowas.new
  end

  def self.init_kline()
    @@kline_mod = Command::Standard::Kline.new
  end

  def self.init_qline()
    @@qline_mod = Command::Standard::Qline.new
  end

  def self.init_vhost()
    @@vhost_mod = Command::Optional::Vhost.new
  end

  def self.init_zline()
    @@zline_mod = Command::Standard::Zline.new
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

  def self.nick_exists?(nick)
    if Options.io_type.to_s == "thread"
      @@users_lock.synchronize do
        @@users.each do |u|
          return true if u.nick.casecmp(nick) == 0
        end
      end
    else
      @@users.each do |u|
        return true if u.nick.casecmp(nick) == 0
      end
    end
    return false
  end

  def self.get_user_by_nick(nick)
    if Options.io_type.to_s == "thread"
      @@users_lock.synchronize do
        @@users.each do |u|
          return u if u.nick.casecmp(nick) == 0
        end
      end
    else
      @@users.each do |u|
        return u if u.nick.casecmp(nick) == 0
      end
    end
    return nil
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
          if user.is_admin? || user.is_operator?
            Server.oper_count -= 1
          end
          return true
        else
          return false
        end
      end
    else
      if @@users.delete(user) != nil
        if user.is_admin? || user.is_operator?
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
      @@channel_count_lock.synchronize { @@channel_count += 1 }
    else
      @@channel_map[channel.name.upcase] = channel
      @@channel_count += 1
    end
  end

  def self.remove_channel(channel)
    if Options.io_type.to_s == "thread"
      @@channels_lock.synchronize { @@channel_map.delete(channel) }
      @@channel_count_lock.synchronize { @@channel_count -= 1 }
    else
      @@channel_map.delete(channel)
      @@channel_count -= 1
    end
  end

  def self.add_admin(admin)
    @@admins.push(admin)
  end

  def self.add_oper(oper)
    @@opers.push(oper)
  end

  def self.add_data_recv(amount)
    if Options.io_type.to_s == "thread"
      @@data_recv_lock.synchronize { @@data_recv += amount }
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

  # If called_from_rehash is true, we do not want to exit the server process while it is up during a rescue
  def self.read_motd(called_from_rehash)
    begin
      @@motd = IO.readlines("cfg/motd.txt")
    rescue => e
      return e if called_from_rehash
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

  def self.whowas_mod
    @@whowas_mod
  end

  def self.kline_mod
    @@kline_mod
  end

  def self.qline_mod
    @@qline_mod
  end

  def self.vhost_mod
    @@vhost_mod
  end

  def self.zline_mod
    @@zline_mod
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

  def self.data_recv
    @@data_recv
  end

  def self.data_sent
    @@data_sent
  end

  class << self; attr_accessor :visible_count, :invisible_count, :unknown_count, :oper_count, :global_users, :global_users_max, :channel_count, :friendly_start_date, :start_timestamp, :link_count end
end
