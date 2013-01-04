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

require 'socket'

# Configurables
server_name = "irc.devux.org"
port = 1997

server = TCPServer.open(port)
client_count = 0
users = Array.new
loop {
  Thread.start(server.accept) do |client|
    client_count = client_count+1
    done = 0
    client.puts(":#{server_name} NOTICE Auth :*** Looking up your hostname...")
    sock_domain, client_port, client_hostname, client_ip = client.peeraddr
    client.puts(":#{server_name} NOTICE Auth :*** Found your hostname (#{client_hostname})")
    # client sends "NICK <nick>"
    incoming = client.gets("\r\n").chomp("\r\n")
    puts(incoming.split)
    # client sends "USER <ident> <ident> <hostname> :<gecos>
    incoming = client.gets("\r\n").chomp("\r\n")
    puts(incoming.split)
    # send PING and expect a PONG back
    client.puts("PING :#{Time.now.to_i}")
    incoming = client.gets("\r\n").chomp("\r\n")
    puts(incoming.split)
    user = client.gets("\r\n").chomp("\r\n")
    users.push(user)
    while done == 0 do
      message = client.gets("\r\n").chomp("\r\n")
      #message = client.gets()
      #client.puts(message)
      if message == 'quit'
        done = 1
        client.close()
        client_count = client_count-1
        users.delete(user)
      elsif message == 'date' || message == 'time'
        client.puts(Time.now.ctime)
      elsif message == 'who'
        client.puts("Current connections: #{client_count}")
        client.puts("Users online: ")
        users.each { |x| client.puts(x) }
      else
        client.puts("Invalid command")
      end
    end
  end
}
