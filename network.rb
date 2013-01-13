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
require_relative 'config'
require_relative 'numeric'
require_relative 'server'

class Network
  def self.start
    server = TCPServer.open(JRIRC::Config.listen_port)
    loop do
      Thread.start(server.accept) do |client|
        Server.client_count += 1
        client.puts(":#{JRIRC::Config.server_name} NOTICE Auth :*** Looking up your hostname...")
        sock_domain, client_port, client_hostname, client_ip = client.peeraddr
        client.puts(":#{JRIRC::Config.server_name} NOTICE Auth :*** Found your hostname (#{client_hostname})")
        # Registration loop
        not_registered = true
        while(not_registered) do
          input = client.gets("\r\n").chomp("\r\n")
          if input.empty?
            redo
          end
          tokens = input.split
          if tokens[0] =~ /(^nick$)/i && tokens.length == 1
            client.puts(Numeric.make("461", "null", Numeric::ERR_NEEDMOREPARAMS))
            redo
          end
          if tokens[0] =~ /(^nick$)/i && tokens.length > 2
            client.puts(Numeric.make("432", "null", Numeric::ERR_ERRONEOUSNICKNAME))
            redo
          end
          if tokens[0] =~ /(^nick$)/i && tokens.length == 2
            if tokens[1] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i && tokens[1].length >=1 && tokens[1].length <= Limits::NICKLEN
              Server.users.each do |user|
                if user.nick.casecmp(tokens[1]) == 0
                  client.puts(Numeric.make("433", "null", Numeric::ERR_NICKNAMEINUSE))
                  break
                end
              end
              nick = tokens[1]
            else
              client.puts(Numeric.make("432", "null", Numeric::ERR_ERRONEOUSNICKNAME))
              redo
            end
          end
          if tokens[0] =~ /(^user$)/i && tokens.length < 5
            client.puts(Numeric.make("461", "null", Numeric::ERR_NEEDMOREPARAMS))
            redo
          end
          if tokens[0] =~ /(^user$)/i && tokens.length >= 5
            gecos = tokens[4]
            if tokens[1].length <= 9 && tokens[2].length <= 9 && gecos[0] == ':'
              gecos = tokens[4..tokens.length]
              gecos = gecos[1..gecos.length] # Remove leading ':'
              puts(gecos)
            else
              redo
            end
          end
        end # while
      end # Thread
    end # loop
  end # method
end # class
