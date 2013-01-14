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
require_relative 'commands'
require_relative 'numeric'
require_relative 'options'
require_relative 'server'

class Network
  def self.start
    server = TCPServer.open(Options.listen_port)
    loop do
      Thread.start(server.accept) do |client|
        Server.client_count += 1
        user = Network.registration_loop(client)
        Network.welcome(client, user)
        Network.main_loop(client, user)
      end # Thread
    end # loop
  end # method

  def self.registration_loop(client)
    client.puts(":#{Options.server_name} NOTICE Auth :*** Looking up your hostname...")
    sock_domain, client_port, client_hostname, client_ip = client.peeraddr
    client.puts(":#{Options.server_name} NOTICE Auth :*** Found your hostname (#{client_hostname})")
    registered = false
    valid_nick = false
    timer_thread = Thread.new() { Network.registration_timer(client) }
    until(registered && valid_nick) do
      input = client.gets("\r\n").chomp("\r\n")
      if input.empty?
        redo
      end
      tokens = input.split
      if tokens[0] =~ /(^nick$)/i && tokens.length == 1
        client.puts(Numeric.ERR_NEEDMOREPARAMS("null", "NICK"))
        redo
      end
      if tokens[0] =~ /(^nick$)/i && tokens.length > 2
        client.puts(Numeric.ERR_ERRONEOUSNICKNAME("null"))
        redo
      end
      if tokens[0] =~ /(^nick$)/i && tokens.length == 2
        if tokens[1] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i && tokens[1].length >=1 && tokens[1].length <= Limits::NICKLEN
          Server.users.each do |user|
            if user.nick.casecmp(tokens[1]) == 0
              client.puts(Numeric.ERR_NICKNAMEINUSE("null"))
              break
            end
          end
          nick = tokens[1]
          valid_nick = true
          if registered
            ping_time = Time.now.to_i
            client.puts("PING :#{ping_time}")
            ping_response = client.gets("\r\n").chomp("\r\n")
            pong_tokens = ping_response.split
            if pong_tokens[0] =~ /(^pong$)/i && pong_tokens[1] == ":#{ping_time}"
              Thread.kill(timer_thread)
              user = User.new(nick, ident, client_hostname, gecos) 
              Server.add_user(user)
              return user
            else
              redo
            end
          end
        else
          client.puts(Numeric.ERR_ERRONEOUSNICKNAME("null"))
          redo
        end
      end
      if tokens[0] =~ /(^user$)/i && tokens.length < 5
        client.puts(Numeric.ERR_NEEDMOREPARAMS("null", "USER"))
        redo
      end
      if tokens[0] =~ /(^user$)/i && tokens.length >= 5
        gecos = tokens[4]
        # We don't care about the 2nd and 3rd fields since they are supposed to be hostname and server (these can be spoofed for users)
        # The 2nd field matches the 1st (ident string) for certain clients (FYI)
        if tokens[1].length <= Limits::IDENTLEN && gecos[0] == ':'
          if tokens[1] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
            ident = tokens[1]
          else
            redo
          end
          gecos = tokens[4..tokens.length].join(" ")
          gecos = gecos[1..gecos.length] # remove leading ':'
          if gecos.length > Limits::GECOSLEN
            gecos = gecos[0..Limits::GECOSLEN-1]
          end
          registered = true
          if valid_nick
            ping_time = Time.now.to_i
            client.puts("PING :#{ping_time}")
            ping_response = client.gets("\r\n").chomp("\r\n")
            pong_tokens = ping_response.split
            if pong_tokens[0] =~ /(^pong$)/i && pong_tokens[1] == ":#{ping_time}"
              Thread.kill(timer_thread)
              user = User.new(nick, ident, client_hostname, gecos)
              Server.add_user(user)
              return user
            else
              redo
            end
          end
        else
          redo
        end
      end
    end # until
  end # method

  def self.registration_timer(client)
    Kernel.sleep Limits::REGISTRATION_TIMEOUT
    client.puts("ERROR :Closing link: [Registration timeout]")
    client.close
    Server.client_count -= 1
  end

  def self.welcome(client, user)
    client.puts(Numeric.RPL_WELCOME(user.nick))
    client.puts(Numeric.RPL_YOURHOST(user.nick))
    client.puts(Numeric.RPL_CREATED(user.nick))
    client.puts(Numeric.RPL_MYINFO(user.nick))
    client.puts(Numeric.RPL_ISUPPORT1(user.nick))
    client.puts(Numeric.RPL_ISUPPORT2(user.nick))
    client.puts(Numeric.RPL_LUSERCLIENT(user.nick))
    client.puts(Numeric.RPL_LUSEROP(user.nick))
    client.puts(Numeric.RPL_LUSERCHANNELS(user.nick))
    client.puts(Numeric.RPL_LUSERME(user.nick))
    client.puts(Numeric.RPL_LOCALUSERS(user.nick))
    client.puts(Numeric.RPL_GLOBALUSERS(user.nick))
    client.puts(Numeric.RPL_MOTDSTART(user.nick))
    # ToDo: read motd.txt and send line by line below
    client.puts(Numeric.RPL_MOTD(user.nick, "Welcome!"))
    client.puts(Numeric.RPL_ENDOFMOTD(user.nick))
  end

  def self.main_loop(client, user)
    loop do
      input = client.gets("\r\n").chomp("\r\n")
      if input.empty?
        redo
      end
      input = input.split
      Command.parse(client, user, input)
    end
  end
end # class
