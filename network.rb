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

require 'resolv'
require 'socket'
require_relative 'commands'
require_relative 'numerics'
require_relative 'options'
require_relative 'server'

class Network
  def self.start()
    begin
      server = TCPServer.open(Options.listen_port)
    rescue
      puts("Unable to listen on TCP port #{Options.listen_port}.")
      Log.write("Unable to listen on TCP port #{Options.listen_port}.")
      exit!
    end
    begin
      ssl_server = TCPServer.open(Options.ssl_port)
    rescue
      puts("Unable to listen on TCP port #{Options.ssl_port}.")
      Log.write("Unable to listen on TCP port #{Options.ssl_port}.")
      exit!
    end
    loop do
      Thread.start(server.accept) do |client_socket|
        Server.client_count += 1
        user = Network.register_user(client_socket, Thread.current)
        Network.welcome(user)
        Network.main_loop(user)
      end # Thread
    end # loop
  end # method

  def self.recv(user)
    return user.socket.gets("\r\n").chomp("\r\n")
    # Handle exception in case socket goes away...
    rescue
      if Server.remove_user(user) # this will affect WHOWAS -- work around this later
        Server.client_count -= 1
      end
      if user.thread != nil
        Thread.kill(user.thread)
      end
  end

  def self.send(user, data)
    user.socket.write(data + "\x0D\x0A")
    # Handle exception in case socket goes away...
    rescue
      if Server.remove_user(user) # this will affect WHOWAS -- work around this later
        Server.client_count -= 1
      end
      if user.thread != nil
        Thread.kill(user.thread)
      end
  end

  def self.close(user)
    begin
      user.socket.close()
    rescue
      if Server.remove_user(user)
        Server.client_count -= 1
      end
      if user.thread != nil
        Thread.kill(user.thread)
      end
    end
  end

  def self.register_user(client_socket, connection_thread)
    sock_domain, client_port, client_hostname, client_ip = client_socket.peeraddr
    user = User.new("*", nil, client_hostname, client_ip, nil, client_socket, connection_thread)
    if Server.client_count >= Options.max_connections
      Network.send(user, "ERROR :Closing link: [Server too busy]")
      Network.close(user)
    end
    Server.add_user(user)
    Log.write("Received connection from #{user.ip_address}.")
    Network.send(user, ":#{Options.server_name} NOTICE Auth :*** Looking up your hostname...")
    begin
      hostname = Resolv.getname(client_ip)
    rescue
      Network.send(user, ":#{Options.server_name} NOTICE Auth :*** Couldn't look up your hostname")
      hostname = client_ip
    else
      Network.send(user, ":#{Options.server_name} NOTICE Auth :*** Found your hostname (#{hostname})")
    ensure
      user.change_hostname(hostname)
    end
    registered = false
    timer_thread = Thread.new() { Network.registration_timer(user) }
    until(registered) do
      input = Network.recv(user)
      if input.empty?
        redo
      end
      input = input.split
      # Do not allow access to any other commands until the client is registered
      unless input[0].to_s.upcase == "CAP" || input[0].to_s.upcase == "NICK" || input[0].to_s.upcase == "QUIT" || input[0].to_s.upcase == "USER"
        unless Command.command_map[input[0].to_s.upcase] == nil
          Network.send(user, Numeric.ERR_NOTREGISTERED(input[0].to_s.upcase))
          redo
        end
        redo
      end
      Command.parse(user, input)
      if user.nick != "*" && user.ident != nil && user.gecos != nil
        registered = true
      else
        redo
      end
    end # until

    # Ensure we get a valid ping response
    ping_time = Time.now.to_i
    Network.send(user, "PING :#{ping_time}")
    loop do
      ping_response = Network.recv(user).split
      if ping_response.empty?
        redo
      end
      if ping_response[0] =~ /(^pong$)/i && ping_response.length == 2
        if ping_response[1] == ":#{ping_time}"
          Thread.kill(timer_thread)
          user.set_registered
          return user
        else
          redo # ping response incorrect
        end
      else
        redo # wrong number of args or not a pong
      end
    end # loop
  end # method

  def self.registration_timer(user)
    Kernel.sleep Limits::REGISTRATION_TIMEOUT
    Network.send(user, "ERROR :Closing link: [Registration timeout]")
    Network.close(user)
  end

  def self.welcome(user)
    Network.send(user, Numeric.RPL_WELCOME(user.nick))
    Network.send(user, Numeric.RPL_YOURHOST(user.nick))
    Network.send(user, Numeric.RPL_CREATED(user.nick))
    Network.send(user, Numeric.RPL_MYINFO(user.nick))
    Network.send(user, Numeric.RPL_ISUPPORT1(user.nick, Options.server_name))
    Network.send(user, Numeric.RPL_ISUPPORT2(user.nick, Options.server_name))
    Network.send(user, Numeric.RPL_LUSERCLIENT(user.nick))
    Network.send(user, Numeric.RPL_LUSEROP(user.nick))
    Network.send(user, Numeric.RPL_LUSERCHANNELS(user.nick))
    Network.send(user, Numeric.RPL_LUSERME(user.nick))
    Network.send(user, Numeric.RPL_LOCALUSERS(user.nick))
    Network.send(user, Numeric.RPL_GLOBALUSERS(user.nick))
    Command.handle_motd(user, "")
  end

  def self.main_loop(user)
    loop do
      input = Network.recv(user)
      if input.empty?
        redo
      end
      # output raw commands to foreground for now for debugging purposes
      puts input
      input = input.split
      if input[0].to_s.upcase == "PING"
        user.last_ping = Time.now.to_i
      else
        user.last_activity = Time.now.to_i
      end
      Command.parse(user, input)
    end
  end
end # class
