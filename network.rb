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
require_relative 'numerics'
require_relative 'options'
require_relative 'server'

class Network
  def self.start()
    server = TCPServer.open(Options.listen_port)
    loop do
      Thread.start(server.accept) do |client|
        Server.client_count += 1
        user = Network.register_user(client, Thread.current)
        Network.welcome(client, user)
        Network.main_loop(client, user, Thread.current)
      end # Thread
    end # loop
  end # method

  def self.register_user(client, thread)
    client.puts(":#{Options.server_name} NOTICE Auth :*** Looking up your hostname...")
    sock_domain, client_port, client_hostname, client_ip = client.peeraddr
    client.puts(":#{Options.server_name} NOTICE Auth :*** Found your hostname (#{client_hostname})")
    registered = false
    user = User.new("*", nil, client_hostname, nil)
    timer_thread = Thread.new() { Network.registration_timer(client) }
    until(registered) do
      begin
        input = client.gets("\r\n").chomp("\r\n")
      rescue Errno::EBADF => e
        puts("Client connection closed during registration.")
        Thread.kill(thread)
      end
      if input.empty?
        redo
      end
      input = input.split
      Command.parse(client, user, input)
      if user.nick != "*" && user.ident != nil && user.gecos != nil
        registered = true
      else
        redo
      end
    end # until

    # Ensure we get a valid ping response
    ping_time = Time.now.to_i
    client.puts("PING :#{ping_time}")
    loop do
      begin
        ping_response = client.gets("\r\n").chomp("\r\n").split
      rescue Errno::EBADF => e
        puts("Client connection closed during initial ping.")
        Thread.kill(thread)
      end
      if ping_response.empty?
        redo
      end
      if ping_response[0] =~ /(^pong$)/i && ping_response.length == 2
        if ping_response[1] == ":#{ping_time}"
          Thread.kill(timer_thread)
          user.set_registered
          Server.add_user(user)
          return user
        else
          redo # ping response incorrect
        end
      else
        redo # wrong number of args or not a pong
      end
    end # loop
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

  def self.main_loop(client, user, thread)
    loop do
      begin
        input = client.gets("\r\n").chomp("\r\n")
      rescue IOError => e
        puts("Client connection closed during main_loop.")
        Thread.kill(thread)
      end
      if input.empty?
        redo
      end
      input = input.split
      Command.parse(client, user, input)
    end
  end
end # class
