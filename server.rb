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
  VERSION = "RubIRCd v0.1a"
  RELEASE = "maiden voyage"
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
  @@link_count = 0
  @@links = Array.new
  @@users = Array.new

  def self.init_chanmap
    @@channel_map = {}
  end

  def self.add_user(user)
    @@users.push(user)
  end

  def self.remove_user(user)
    if @@users.delete(user) != nil
      return true
    else
      return false
    end
  end

  def self.add_channel(channel)
    @@channel_map[channel.name.upcase] = channel
  end

  def self.remove_channel(channel)
    @@channel_map.delete(channel)
  end

  def self.users
    @@users
  end

  def self.channel_map
    @@channel_map
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

  class << self; attr_accessor :client_count, :visible_count, :invisible_count, :unknown_count, :oper_count, :local_users, :global_users, :local_users_max, :global_users_max, :start_timestamp, :channel_count, :link_count end
end
