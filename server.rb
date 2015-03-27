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

# Contains the properties of an IRC server along with some static utility methods
class Server
  VERSION = 'RubIRCd v0.2a'
  RELEASE = 'mildly dangerous'
  URL = 'http://www.rubircd.rocks/'
  MODE_ADMIN = 'a'          # is an IRC administrator
  MODE_BOT = 'b'            # is a bot
  MODE_INVISIBLE = 'i'      # invisible in WHO and NAMES output
  MODE_OPERATOR = 'o'       # is an IRC operator
  MODE_REGISTERED = 'r'     # indicates that the nickname is registered
  MODE_SERVER = 's'         # can see server messages such as kills
  MODE_VERBOSE = 'v'        # can see client connect/quit messages
  MODE_WALLOPS = 'w'        # can receive oper wall messages
  USER_MODES = 'abiorsvwx'
  STATUS_PREFIXES = '&!~@%+'
  @client_count = 0
  @visible_count = 0
  @invisible_count = 0
  @unknown_count = 0
  @oper_count = 0
  @local_users = 0
  @global_users = 0
  @local_users_max = 0
  @global_users_max = 0
  @channel_count = 0
  @link_count = 0
  @friendly_start_date = 0 # holds server start date and time in friendly format
  @start_timestamp = 0     # holds server start timestamp in integer format
  @data_recv = 0           # amount of data server has received in bytes since it started
  @data_sent = 0           # amount of data server has sent in bytes since it started
  @links = []
  @users = []
  @admins = []
  @opers = []

  def self.init_locks
    @client_count_lock = Mutex.new
    @link_count_lock = Mutex.new
    @users_lock = Mutex.new
    @channels_lock = Mutex.new
    @data_recv_lock = Mutex.new
    @data_sent_lock = Mutex.new
  end

  def self.init_chanmap
    @channel_map = {}
  end

  def self.init_kline
    @kline_mod = Mod.find('KLINE')
  end

  def self.init_qline
    @qline_mod = Mod.find('QLINE')
  end

  def self.init_vhost
    @vhost_mod = Mod.find('VHOST')
  end

  def self.init_whowas
    @whowas_mod = Mod.find('WHOWAS')
  end

  def self.init_zline
    @zline_mod = Mod.find('ZLINE')
  end

  # TODO: Pass user as an argument and determine if they are invisible, an operator, unknown, etc.
  def self.increment_clients
    @client_count_lock.lock if Options.io_type.to_s == 'thread'
    @client_count += 1
    @local_users += 1
    @local_users_max = @local_users if @local_users > @local_users_max
    # TODO: Handle global users after server linking is implemented
    @client_count_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.decrement_clients
    @client_count_lock.lock if Options.io_type.to_s == 'thread'
    @client_count -= 1
    @local_users -= 1
    # TODO: Handle global users after server linking is implemented
    @client_count_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.nick_exists?(nick)
    default_return_value = false
    if Options.io_type.to_s == 'thread'
      @users_lock.synchronize do
        @users.each { |u| return true if u.nick.casecmp(nick) == 0 }
      end
    else
      @users.each { |u| return true if u.nick.casecmp(nick) == 0 }
    end
    default_return_value
  end

  def self.get_user_by_nick(nick)
    default_return_value = nil
    if Options.io_type.to_s == 'thread'
      @users_lock.synchronize do
        @users.each { |u| return u if u.nick.casecmp(nick) == 0 }
      end
    else
      @users.each { |u| return u if u.nick.casecmp(nick) == 0 }
    end
    default_return_value
  end

  def self.add_user(user)
    @users_lock.lock if Options.io_type.to_s == 'thread'
    @users.push(user)
    @users_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.remove_user(user)
    @users_lock.lock if Options.io_type.to_s == 'thread'
    if !@users.delete(user).nil?
      Server.oper_count -= 1 if user.admin || user.operator
      return true
    else
      return false
    end
    @users_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.channel_exists?(channel)
    if Options.io_type.to_s == 'thread'
      @channels_lock.synchronize { @channel_map.include?(channel.upcase) }
    else
      return @channel_map.include?(channel.upcase)
    end
  end

  def self.add_channel(channel)
    @channels_lock.lock if Options.io_type.to_s == 'thread'
    @channel_map[channel.name.upcase] = channel
    @channel_count += 1
    @channels_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.remove_channel(channel)
    @channels_lock.lock if Options.io_type.to_s == 'thread'
    @channel_map.delete(channel)
    @channel_count -= 1
    @channels_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.add_admin(admin)
    @admins.push(admin)
  end

  def self.add_oper(oper)
    @opers.push(oper)
  end

  def self.add_data_recv(amount)
    @data_recv_lock.lock if Options.io_type.to_s == 'thread'
    @data_recv += amount
    @data_recv_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def self.add_data_sent(amount)
    @data_sent_lock.lock if Options.io_type.to_s == 'thread'
    @data_sent += amount
    @data_sent_lock.unlock if Options.io_type.to_s == 'thread'
  end

  # If called_from_rehash is true, we do not want to exit the server process while it is up during a rescue
  def self.read_motd(called_from_rehash)
    @motd = IO.readlines('cfg/motd.txt')
    rescue => e
      return e if called_from_rehash
      puts 'failed. Unable to open motd.txt file!'
      exit!
  end

  def self.users
    if Options.io_type.to_s == 'thread'
      @users_lock.synchronize { @users }
    else
      @users
    end
  end

  def self.channel_map
    if Options.io_type.to_s == 'thread'
      @channels_lock.synchronize { @channel_map }
    else
      @channel_map
    end
  end

  def self.client_count
    if Options.io_type.to_s == 'thread'
      @client_count_lock.synchronize { @client_count }
    else
      @client_count
    end
  end

  def self.local_users
    if Options.io_type.to_s == 'thread'
      @client_count_lock.synchronize { @local_users }
    else
      @local_users
    end
  end

  def self.local_users_max
    if Options.io_type.to_s == 'thread'
      @client_count_lock.synchronize { @local_users_max }
    else
      @local_users_max
    end
  end

  def self.data_recv
    if Options.io_type.to_s == 'thread'
      @data_recv_lock.synchronize { @data_recv }
    else
      @data_recv
    end
  end

  def self.data_sent
    if Options.io_type.to_s == 'thread'
      @data_sent_lock.synchronize { @data_sent }
    else
      @data_sent
    end
  end

  class << self
    attr_reader :motd, :kline_mod, :qline_mod, :vhost_mod, :whowas_mod, :zline_mod, :admins, :opers
    attr_accessor :visible_count, :invisible_count, :unknown_count, :oper_count, :global_users, :global_users_max, :channel_count, :friendly_start_date, :start_timestamp, :link_count
  end
end
