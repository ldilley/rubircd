# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details) 
# http://www.rubircd.rocks/
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
require_relative 'utility'

class Network
  @@ipv6_enabled = false
  @@listen_address = nil

  def self.ipv6_enabled
    @@ipv6_enabled
  end

  def self.listen_address
    @@listen_address
  end

  def self.start()
    begin
      if Options.listen_host != nil
        plain_server = TCPServer.open(Options.listen_host, Options.listen_port)
      else
        plain_server = TCPServer.open(Options.listen_port)
        local_ip_addresses = Socket.ip_address_list
        local_ip_addresses.each do |address|
          if address.ipv6?
            @@ipv6_enabled = true
          end
        end
      end
    rescue Errno::EADDRNOTAVAIL => e
      puts("Invalid listen_host: #{Options.listen_host}")
      Log.write(4, "Invalid listen_host: #{Options.listen_host}")
      Log.write(4, e)
      exit!
    rescue SocketError => e
      puts("Invalid listen_host: #{Options.listen_host}")
      Log.write(4, "Invalid listen_host: #{Options.listen_host}")
      Log.write(4, e)
      exit!
    rescue => e
      puts("Unable to listen on TCP port: #{Options.listen_port}")
      Log.write(4, "Unable to listen on TCP port: #{Options.listen_port}")
      Log.write(4, e)
      exit!
    end
    unless Options.ssl_port == nil
      begin
        if Options.listen_host != nil
          base_server = TCPServer.open(Options.listen_host, Options.ssl_port)
          *_, @@listen_address = base_server.addr
        else
          base_server = TCPServer.open(Options.ssl_port)
          *_, @@listen_address = base_server.addr
        end
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.cert = OpenSSL::X509::Certificate.new(File.read("cfg/cert.pem"))
        ssl_context.key = OpenSSL::PKey::RSA.new(File.read("cfg/key.pem"))
        ssl_server = OpenSSL::SSL::SSLServer.new(base_server, ssl_context)
      rescue => e
        puts("Unable to listen on SSL port: #{Options.ssl_port}")
        Log.write(4, "Unable to listen on SSL port: #{Options.ssl_port}")
        Log.write(4, e)
        exit!
      end
    end
    connection_check_thread = Thread.new() { Network.connection_checker() }
    if Options.io_type.to_s == "thread"
      plain_thread = Thread.new() { Network.plain_connections(plain_server) }
      unless Options.ssl_port == nil
        ssl_thread = Thread.new() { Network.ssl_connections(ssl_server) }
      end
      # Wait until threads complete before exiting program
      plain_thread.join()
      unless Options.ssl_port == nil
        ssl_thread.join()
      end
    else # if io_type == event, then use select()
      handle_select(plain_server, ssl_server)
    end
  end

  def self.handle_select(plain_server, ssl_server)
    timeout = 10
    if ssl_server == nil
      fds = [plain_server]
    else
      fds = [plain_server, ssl_server]
    end
    loop do
      begin
        ios = select(fds, [], [], timeout)
        unless ios.nil?
          ios[0].each do |client|
            if client == plain_server
              plain_client = plain_server.accept()
              fds << plain_client
              Server.increment_clients()
              user = Network.register_connection(plain_client, nil)
              if user == nil
                fds.delete(plain_client)
                Network.close(user, "Connection closed", true)
                break
              end
              unless Server.kline_mod == nil
                Network.check_for_kline(user)
              end
              Network.welcome(user)
            elsif ssl_server != nil && client == ssl_server
              begin
                ssl_client = ssl_server.accept()
              rescue
                Log.write(2, "Client disconnected before completing SSL handshake.")
                break
              end
              fds << ssl_client
              Server.increment_clients()
              user = Network.register_connection(ssl_client, nil)
              if user == nil
                fds.delete(ssl_client)
                Network.close(user, "Connection closed", true)
                break
              end
              unless Server.kline_mod == nil
                Network.check_for_kline(user)
              end
              Network.welcome(user)
            elsif client.eof?
              client.close()
            else # handle clients that are already connected
              # Find user by socket
              Server.users.each do |u|
                if client == u.socket
                  user = u
                end
              end
              if user == nil
                fds.delete(client) # user didn't exist, so remove the socket from file descriptor list
                Network.close(user, "Connection closed", true)
                break
              end
              input = Network.recv(user)
              if input == nil
                break
              end
              if input.empty?
                break
              end
              if Options.debug_mode
                puts input                      # output raw commands to foreground for debugging purposes
              end
              input = input.chomp.split(' ', 2) # input[0] should contain command and input[1] contains the rest
              if input[0].to_s.upcase == "PING"
                user.last_ping = Time.now.to_i
              else
                user.set_last_activity()
              end
              Command.parse(user, input)
            end
          end
        end
      rescue # client disconnected, so remove socket from file descriptor list
        fds.each do |sock|
          if sock.closed?
            fds.delete(sock)
          end
        end
      end
    end
  end

  # Periodic PING check
  def self.connection_checker()
    loop do
      Server.users.each do |u|
        if u != nil && u.is_registered?
          Network.send(u, "PING :#{Options.server_name}")
          ping_diff = Time.now.to_i - u.last_ping
          if ping_diff >= Limits::PING_STRIKES * Limits::PING_INTERVAL
            Network.close(u, "Ping timeout: #{ping_diff} seconds", false)
          end
        end
      end
      sleep Limits::PING_INTERVAL
    end
  end

  def self.plain_connections(plain_server)
    loop do
      Thread.start(plain_server.accept()) do |plain_socket|
        Server.increment_clients()
        user = Network.register_connection(plain_socket, Thread.current)
        unless Server.kline_mod == nil
          Network.check_for_kline(user)
        end
        Network.welcome(user)
        Network.main_loop(user)
      end
    end
    rescue SocketError => e
      puts "Open file descriptor limit reached!"
      Log.write(4, "Open file descriptor limit reached!") # we likely cannot write to the log file in this state, but try anyway...
  end

  def self.ssl_connections(ssl_server)
    loop do
      begin
        Thread.start(ssl_server.accept()) do |ssl_socket|
          Server.increment_clients()
          user = Network.register_connection(ssl_socket, Thread.current)
          unless Server.kline_mod == nil
            Network.check_for_kline(user)
          end
          Network.welcome(user)
          Network.main_loop(user)
        end 
      rescue SocketError => e
        puts "Open file descriptor limit reached!"
        Log.write(4, "Open file descriptor limit reached!") # we likely cannot write to the log file in this state, but try anyway...
      rescue
        # Do nothing here since a plain-text connection likely came in... just continue on with the next connection
      end
    end
  end

  def self.recv(user)
    #data = user.socket.gets("\r\n").chomp("\r\n")
    data = user.socket.gets().chomp("\r\n") # ircII fix -- blocking should be fine here until client sends EoL when in threaded mode
    if data.length > Limits::MAXMSG
      data = data[0..Limits::MAXMSG-1]
    end
    unless data == nil
      Server.add_data_recv(data.length)
      user.data_sent += data.length
    end
    return data
    # Handle exception in case socket goes away...
    rescue
      Network.close(user, "Connection closed", true)
  end

  def self.send(user, data)
    if data.length > Limits::MAXMSG
      data = data[0..Limits::MAXMSG-1]
    end
    unless data == nil
      Server.add_data_sent(data.length)
      user.data_recv += data.length
    end
    user.socket.write(data + "\x0D\x0A")
    # Handle exception in case socket goes away...
    rescue
      Network.close(user, "Connection closed", true)
  end

  def self.close(user, reason, lost_socket)
    begin
      user.socket.close()
    rescue => e
     # The exception below usually produces "closed stream" messages which occur during high load.
     # Connection throttling and z-lining if client floods are detected should prevent any server hangs.
     #puts(e)
    ensure
      Server.users.each do |u|
        if u != nil && u.is_admin? && u.umodes.include?('v') && u.socket.closed? == false && !lost_socket
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** QUIT: #{user.nick}!#{user.ident}@#{user.hostname} has disconnected: #{reason}")
        end
      end
      if user != nil && user.get_channels_length() > 0
        user_channels = user.get_channels_array()
        user_channels.each do |c|
          chan = Server.channel_map[c.to_s.upcase]
          if chan != nil
            chan.users.each do |u|
              # Do not broadcast QUIT for invisible administrators in a channel who disconnect.
              # Only do this for other administrators
              user_is_invisible = chan.invisible_nick_in_channel?(u.nick)
              if user != nil && u != nil && user.nick != u.nick && u.socket.closed? == false && user_is_invisible && u.is_admin?
                Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} QUIT :#{reason}")
              end
              # Checking if user and 'u' are nil below prevent a "SystemStackError: stack level too deep" exception.
              # However, this may need to be fixed since stale nicks may hang around in channels when no client is actually connected.
              # So, FixMe: Figure out why user and/or 'u' objects become nil in the first place and prevent this from happening.
              unless user_is_invisible
                if user != nil && u != nil && user.nick != u.nick && u.socket.closed? == false
                  Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} QUIT :#{reason}")
                end
              end
            end
            chan.remove_user(user)
            chan.remove_invisible_user(user)
            unless chan.modes.include?('r') || chan.users.length > 0
              Server.remove_channel(chan.name.upcase)
            end
          end
        end
      end
      whowas_loaded = Command.command_map["WHOWAS"]
      unless whowas_loaded == nil
        # Checking if user object is nil below prevents a "NoMethodError: undefined method `nick' for nil:NilClass" when using JRuby.
        if user != nil && user.nick != nil && user.nick != "*"
          Server.whowas_mod.add_entry(user, Time.now.asctime)
        end
      end
      if Server.remove_user(user)
        Server.decrement_clients()
      end
      unless user == nil || user.thread == nil
        Thread.kill(user.thread)
      end
    end
  end

  def self.register_connection(client_socket, connection_thread)
    allowed_commands = ["CAP", "CAPAB", "NICK", "PASS", "QUIT", "SERVER", "USER"]
    sock_domain, client_port, client_hostname, client_ip = client_socket.peeraddr
    user = User.new("*", nil, client_hostname, client_ip, nil, client_socket, connection_thread)
    Log.write(1, "Received connection from #{user.ip_address}.")
    if Server.client_count >= Options.max_connections
      Network.send(user, "ERROR :Closing link: [Server too busy]")
      Server.decrement_clients()
      Network.close(user, "Server too busy", false)
    end
    unless Server.zline_mod == nil
      Server.zline_mod.list_zlines.each do |zline|
        if zline.target.casecmp(client_ip) == 0
          Network.send(user, "ERROR :Closing link: #{client_ip} [Z-lined (#{zline.reason})]")
          Server.users.each do |u|
            if u.is_admin? || u.is_operator?
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{client_ip} was z-lined: #{zline.reason}")
            end
          end
          Log.write(2, "#{client_ip} was z-lined: #{zline.reason}")
          Server.decrement_clients()
          Network.close(user, "Z-lined #{client_ip} (#{zline.reason})", false)
        end
      end
    end
    # Thanks to darabiesvampire for contributing the clone detection code below
    unless Options.max_clones == nil
      clone_count = 0
      Server.users.each do |u|
        if u.ip_address == user.ip_address
          clone_count += 1
          if clone_count >= Options.max_clones
            Network.send(user, "ERROR :Closing link: [Maximum number of connections from the same IP address exceeded]")
            Server.users.each do |su|
              if su.is_admin? || su.is_operator?
                Network.send(su, ":#{Options.server_name} NOTICE #{su.nick} :*** BROADCAST: Maximum number of connections from #{user.ip_address} exceeded.")
              end
            end
            Log.write(1, "Maximum number of connections from #{user.ip_address} exceeded.")
            Server.decrement_clients()
            Network.close(user, "Maximum number of connections from the same IP address exceeded", false)
          end
        end
      end
    end
    Server.add_user(user)
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
    good_pass = false
    until(registered) do
      input = Network.recv(user)
      if input == nil # client disconnected
        Network.close(user, "Connection closed", true)
        return nil
      end
      if input.empty?
        redo
      end
      input = input.chomp.split(' ', 2) # input[0] should contain command and input[1] contains the rest
      # Do not allow access to any other commands until the client is registered
      unless allowed_commands.any? { |c| c.casecmp(input[0].to_s.upcase) == 0 }
        unless Command.command_map[input[0].to_s.upcase] == nil
          Network.send(user, Numeric.ERR_NOTREGISTERED(input[0].to_s.upcase))
          redo
        end
        redo
      end
      if input[0].to_s.casecmp("PASS") == 0
        pass_cmd = Command.command_map["PASS"]
        unless pass_cmd == nil
          if input.length > 1
            good_pass = pass_cmd.call(user, input[1..-1])
          else
            good_pass = pass_cmd.call(user, "")
          end
        end
      else
        Command.parse(user, input)
      end
      if user.nick != "*" && user.ident != nil && user.gecos != nil && !user.is_negotiating_cap?
        if Options.server_hash != nil && !good_pass
          Network.send(user, "ERROR :Closing link: [Access denied]")
          Network.close(user, "Access denied", false)
        end
        registered = true
      else
        if user.nick != "*" && user.ident != nil && user.gecos != nil && user.is_negotiating_cap?
          Network.send(user, Numeric.ERR_NOTREGISTERED("CAP")) # user has not closed CAP with END
        end
        redo
      end
    end # until

    # Ensure we get a valid ping response during registration
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
          user.last_ping = Time.now.to_i

          # Set umode +i if auto_invisible is enabled.
          if Options.auto_invisible.to_s == "true"
            user.add_umode('i')
          end

          # Set cloak_host if auto_cloak is true or umode is +x.
          # This must be taken care of before virtual hosts are used to avoid overwriting the user's virtual host.
          unless Options.cloak_host == nil
            unless user.has_umode?('x')
              if Options.auto_cloak.to_s == "true"
                user.add_umode('x')
                user.set_vhost(Options.cloak_host)
              end
            end
          end

          # Set vhost if module is loaded and user criteria is met...
          unless Server.vhost_mod == nil
            vhost = Server.vhost_mod.find_vhost(user.ident, user.hostname)
            if vhost != nil
              if Utility.is_valid_hostname?(vhost) || Utility.is_valid_address?(vhost)
                user.set_vhost(vhost)
              else
                Log.write(3, "Virtual host was not set for #{user.nick}!#{user.ident}@#{user.hostname} since vhost is invalid: #{vhost}")
              end
            end
          end

          return user
        else
          redo # ping response incorrect
        end
      else
        redo # wrong number of args or not a pong
      end
    end
  end

  def self.registration_timer(user)
    Kernel.sleep Limits::REGISTRATION_TIMEOUT
    Network.send(user, "ERROR :Closing link: [Registration timeout]")
    Network.close(user, "Registration timeout", false)
  end

  def self.check_for_kline(user)
    Server.kline_mod.list_klines().each do |kline|
      tokens = kline.target.split('@', 2) # 0 = ident and 1 = host
      if (tokens[0].casecmp(user.ident) == 0 && tokens[1] == '*') || (tokens[0].casecmp(user.ident) == 0 && tokens[1].casecmp(user.hostname) == 0)
        Network.send(user, "ERROR :Closing link: #{kline.target} [K-lined (#{kline.reason})]")
        Server.users.each do |u|
          if u.is_admin? || u.is_operator?
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{kline.target} was k-lined: #{kline.reason}")
          end
          Log.write(2, "#{kline.target} was k-lined: #{kline.reason}")
          Network.close(user, "K-lined #{kline.target} (#{kline.reason})", false)
        end
      end
    end
  end

  def self.welcome(user)
    Server.users.each do |u|
      if u.is_admin? && u.umodes.include?('v')
        Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** CONNECT: #{user.nick}!#{user.ident}@#{user.hostname} has connected.")
      end
    end
    Network.send(user, Numeric.RPL_WELCOME(user.nick))
    Network.send(user, Numeric.RPL_YOURHOST(user.nick))
    Network.send(user, Numeric.RPL_CREATED(user.nick))
    Network.send(user, Numeric.RPL_MYINFO(user.nick))
    Network.send(user, Numeric.RPL_ISUPPORT1(user.nick, Options.server_name))
    Network.send(user, Numeric.RPL_ISUPPORT2(user.nick, Options.server_name))
    # If WALLCHOPS/WALLVOICES module not loaded, don't bother sending a third ISUPPORT
    unless Mod.find("WALLCHOPS").nil? && Mod.find("WALLVOICES").nil?
      Network.send(user, Numeric.RPL_ISUPPORT3(user.nick, Options.server_name))
    end
    Network.send(user, Numeric.RPL_LUSERCLIENT(user.nick))
    Network.send(user, Numeric.RPL_LUSEROP(user.nick))
    Network.send(user, Numeric.RPL_LUSERCHANNELS(user.nick))
    Network.send(user, Numeric.RPL_LUSERME(user.nick))
    Network.send(user, Numeric.RPL_LOCALUSERS(user.nick))
    Network.send(user, Numeric.RPL_GLOBALUSERS(user.nick))
    motd_cmd = Command.command_map["MOTD"]
    unless motd_cmd == nil
      motd_cmd.call(user, "")
    end
    fjoin_cmd = Command.command_map["FJOIN"]
    unless fjoin_cmd == nil
      unless Options.auto_join == nil
        arg_array = []
        arg_array[0] = "#{user.nick} #{Options.auto_join}"
        fjoin_cmd.call(Options.server_name, arg_array)
      end
    end
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
      if Options.debug_mode
        puts input                      # output raw commands to foreground for debugging purposes
      end
      input = input.chomp.split(' ', 2) # input[0] should contain command and input[1] contains the rest
      if input[0].to_s.upcase == "PING"
        user.last_ping = Time.now.to_i
      else
        user.set_last_activity()
      end
      Command.parse(user, input)
    end
  end
end
