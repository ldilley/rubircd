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

require_relative 'channel'
require_relative 'config'
require_relative 'log'
require_relative 'network'
require_relative 'server'
require_relative 'user'

print("Initializing logging... ")
Log.write("Initializing logging...")
puts("done.")
Log.write("Logging initialized.")
print("Parsing configuration file... ")
JRIRC::Config.parse
puts("done.")
Log.write("Configuration loaded.")
puts("Server name: #{JRIRC::Config.server_name}\nTCP port: #{JRIRC::Config.listen_port}")
print("Populating reserved nicknames... ")
chanserv = User.new("ChanServ", "services", JRIRC::Config.server_name, "Channel Services")
global = User.new("Global", "services", JRIRC::Config.server_name, "Global Messenger")
memoserv = User.new("MemoServ", "services", JRIRC::Config.server_name, "Memo Services")
nickserv = User.new("NickServ", "services", JRIRC::Config.server_name, "Nickname Services")
operserv = User.new("OperServ", "services", JRIRC::Config.server_name, "Operator Services")
Server.add_user(chanserv)
Server.add_user(global)
Server.add_user(memoserv)
Server.add_user(nickserv)
Server.add_user(operserv)
puts("done.")
Log.write("Reserved nicknames populated.")
Server.client_count = 0
puts("Starting network and waiting for incoming connections... ")
Network.start
