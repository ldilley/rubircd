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

class Server
  VERSION = "jrIRC v0.1a"
  RELEASE = "maiden voyage"
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
  @@channel_count = 0
  @@link_count = 0
  @@start_timestamp = 0   # holds server startup date and time
  @@links = Array.new
  @@users = Array.new

  def self.add_user(user)
    @@users.push(user)
  end

  def self.users
    @@users
  end

  class << self; attr_accessor :client_count, :start_timestamp end
end
