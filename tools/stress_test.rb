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

require 'socket'

# Configurables
server = "localhost"
port = 6667
base_nick = "tester"
counter = 0

loop do
  t = Thread.new {
    connection = TCPSocket.open(server, port)
    puts(connection.gets("\r\n").chomp("\r\n"))
    puts(connection.gets("\r\n").chomp("\r\n"))
    connection.write("NICK #{base_nick}#{counter}\r\n")
    connection.write("USER test test localhost :Tester\r\n")
    output = connection.gets("\r\n").chomp("\r\n").split
    pong_string = output[1]
    connection.write("PONG #{pong_string}\r\n")
    25.times { puts(connection.gets("\r\n").chomp("\r\n")) }
    10.times do |n|
      connection.write("JOIN #test#{n}\r\n")
      connection.write("PRIVMSG #test#{n} :Hello world!\n\n")
    end
    counter += 1
    sleep 1
  }
  t.join
end
