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
require_relative 'server'
require_relative 'user'

print("Parsing configuration file... ")
config = JRIRC::Config.new
puts("done.")
puts("Server name: #{config.server_name}\nTCP port: #{config.listen_port}")
# Proof of concept
puts("Simulating creation of a new user object...")
user = User.new("Joe", "joe", "localhost.dom", "something witty here")
puts("Current nick is: #{user.nick}")
user.change_nick("Jim")
puts("Nick changed to: #{user.nick}")
user.add_channel("#jibber")
user.add_channel("#jabber")
user.add_channel("#foo")
puts("\nCurrent channels:")
user.channels.each { |channel| puts(channel) }
user.remove_channel("#foo")
puts("\nChannels after removing #foo:")
user.channels.each { |channel| puts(channel) }
puts("\nCreating channel #test with a sample ban...")
channel = Channel.new("#test", "Jim")
channel.add_ban("Jim", "*!*jed@localhost.dom", "too smelly")
channel.remove_ban("*!*jed@localhost.dom")
puts("\nTesting logging functionality...")
log = Log.new
log.write_log("This is only a test.")
