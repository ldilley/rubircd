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

require 'openssl'
require 'resolv'
require 'socket'
require_relative 'commands'
require_relative 'numerics'
require_relative 'options'
require_relative 'server'

class Network
  def self.start()
    begin
      if Options.listen_host != nil
        plain_server = TCPServer.open(Options.listen_host, Options.listen_port)
      else
        plain_server = TCPServer.open(Options.listen_port)
      end
    rescue Errno::EADDRNOTAVAIL => e
      puts("Invalid listen_host: #{Options.listen_host}")
      Log.write("Invalid listen_host: #{Options.listen_host}")
      Log.write(e)
      exit!
    rescue SocketError => e
      puts("Invalid listen_host: #{Options.listen_host}")
      Log.write("Invalid listen_host: #{Options.listen_host}")
      Log.write(e)
      exit!
    rescue => e
      puts("Unable to listen on TCP port: #{Options.listen_port}")
      Log.write("Unable to listen on TCP port: #{Options.listen_port}")
      Log.write(e)
      exit!
    end
    unless Options.ssl_port == nil
      begin
        if Options.listen_host != nil
          base_server = TCPServer.open(Options.listen_host, Options.ssl_port)
        else
          base_server = TCPServer.open(Options.ssl_port)
        end
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.cert = OpenSSL::X509::Certificate.new(File.read("cfg/cert.pem"))
        ssl_context.key = OpenSSL::PKey::RSA.new(File.read("cfg/key.pem"))
        ssl_server = OpenSSL::SSL::SSLServer.new(base_server, ssl_context)
      rescue => e
        puts("Unable to listen on SSL port: #{Options.ssl_port}")
        Log.write("Unable to listen on SSL port: #{Options.ssl_port}")
        Log.write(e)
        exit!
      end
    end
    #connection_check_thread = Thread.new() { Network.connection_checker() }
    if Options.io_type.to_s == "thread"
      plain_thread = Thread.new() { Network.plain_connections(plain_server) }
      unless Options.ssl_port == nil
        ssl_thread = Thread.new() { Network.ssl_connections(ssl_server) }
      end
      # Wait until threads complete before exiting program
      plain_thread.join()
      ssl_thread.join()
    end
    #else
    # ToDo: select() stuff here
    #end
  end # method

  # Future periodic ping checker
  #def self.connection_checker()
  #  loop do
  #    Server.users.each do |u|
  #      unless u.thread == nil
  #        if u.thread.status == "sleep"
  #          Thread.kill(u.thread)
  #        end
  #      end
  #    end
  #    sleep 10
  #  end
  #end

  def self.plain_connections(plain_server)
    loop do
      Thread.start(plain_server.accept()) do |plain_socket|
        Server.increment_clients()
        user = Network.register_connection(plain_socket, Thread.current)
        Network.welcome(user)
        Network.main_loop(user)
      end
    end
    rescue SocketError => e
      puts "Open file descriptor limit reached!"
      # We likely cannot write to the log file in this state, but try anyway...
      Log.write("Open file descriptor limit reached!")
  end

  def self.ssl_connections(ssl_server)
    loop do
      begin
        Thread.start(ssl_server.accept()) do |ssl_socket|
          Server.increment_clients()
          user = Network.register_connection(ssl_socket, Thread.current)
          Network.welcome(user)
          Network.main_loop(user)
        end 
      rescue SocketError => e
        puts "Open file descriptor limit reached!"
        # We likely cannot write to the log file in this state, but try anyway...
        Log.write("Open file descriptor limit reached!")
      rescue
        # Do nothing here since a plain-text connection likely came in... just continue on with the next connection
      end
    end
  end

  def self.recv(user)
    #data = user.socket.gets("\r\n").chomp("\r\n")
    data = user.socket.gets().chomp("\r\n") # ircII fix
    if data.length > Limits::MAXMSG
      data = data[0..Limits::MAXMSG-1]
    end
    unless data == nil
      Server.add_data_recv(data.length)
      user.data_recv += data.length
    end
    return data
    # Handle exception in case socket goes away...
    rescue
      # Testing close() method instead of original code below for a bit...
      Network.close(user)
      #if Server.remove_user(user) # this will affect WHOWAS -- work around this later
      #  Server.decrement_clients()
      #end
      #if user.thread != nil
      #  Thread.kill(user.thread)
      #end
  end

  def self.send(user, data)
    if data.length > Limits::MAXMSG
      data = data[0..Limits::MAXMSG-1]
    end
    unless data == nil
      Server.add_data_sent(data.length)
      user.data_sent += data.length
    end
    user.socket.write(data + "\x0D\x0A")
    # Handle exception in case socket goes away...
    rescue
      if Server.remove_user(user) # this will affect WHOWAS -- work around this later
        Server.decrement_clients()
      end
      if user.thread != nil
        Thread.kill(user.thread)
      end
  end

  def self.close(user)
    begin
      user.socket.close()
    rescue
      #
    ensure
      if user.channels.length > 0
        user.channels.each do |c|
          chan = Server.channel_map[c.to_s.upcase]
          chan.remove_user(user)
        end
      end
      if Server.remove_user(user)
        Server.decrement_clients()
      end
      unless user.thread == nil
        Thread.kill(user.thread)
      end
    end
  end

  def self.register_connection(client_socket, connection_thread)
    allowed_commands = ["CAP", "CAPAB", "NICK", "PASS", "QUIT", "USER"]
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
    timer_thread = Thread.new() {Network.registration_timer(user)}
    until(registered) do
      input = Network.recv(user)
      if input.empty?
        redo
      end
      input = input.split
      # Do not allow access to any other commands until the client is registered
      unless allowed_commands.any? { |c| c.casecmp(input[0].to_s.upcase) == 0 }
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
    Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** If you are having problems connecting due to ping timeouts, please type /quote PONG #{ping_time} or /raw PONG #{ping_time} now.")
    loop do
      ping_response = Network.recv(user).split
      if ping_response.empty?
        redo
      end
      if ping_response[0] =~ /(^pong$)/i && ping_response.length == 2
        if ping_response[1] == ":#{ping_time}" || ping_response[1] == "#{ping_time}"
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
      if input == nil
        return
      end
      if input.empty?
        redo
      end
      # output raw commands to foreground for now for debugging purposes
      puts input
      input = input.split
      if input[0].to_s.upcase == "PING"
        user.last_ping = Time.now.to_i
      else
        user.set_last_activity()
      end
      Command.parse(user, input)
    end
  end
end
