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

require 'digest/sha2'
require_relative 'numerics'
require_relative 'options'
require_relative 'server'

class Command
  @@command_map = {}

  def self.parse(user, input)
    handler = @@command_map[input[0].to_s.upcase]
    if handler == nil
      Network.send(user, Numeric.ERR_UNKNOWNCOMMAND(user.nick, input[0]))
      return
    end
    handler.call(user, input[1..-1])
  end

  def self.register_commands()
    @@command_map["ADMIN"] = Proc.new()     { |user, args| handle_admin(user, args) }
    @@command_map["AWAY"] = Proc.new()      { |user, args| handle_away(user, args) }
    @@command_map["CAP"] = Proc.new()       { |user, args| handle_cap(user, args) }
    @@command_map["CAPAB"] = Proc.new()     { |user, args| handle_capab(user, args) }
    @@command_map["INFO"] = Proc.new()      { |user, args| handle_info(user, args) }
    @@command_map["JOIN"] = Proc.new()      { |user, args| handle_join(user, args) }
    @@command_map["MODE"] = Proc.new()      { |user, args| handle_mode(user, args) }
    @@command_map["MODLIST"] = Proc.new()   { |user, args| handle_modlist(user, args) }
    @@command_map["MODLOAD"] = Proc.new()   { |user, args| handle_modload(user, args) }
    @@command_map["MODUNLOAD"] = Proc.new() { |user, args| handle_modunload(user, args) }
    @@command_map["MOTD"] = Proc.new()      { |user, args| handle_motd(user, args) }
    @@command_map["NAMES"] = Proc.new()     { |user, args| handle_names(user, args) }
    @@command_map["NICK"] = Proc.new()      { |user, args| handle_nick(user, args) }
    @@command_map["NOTICE"] = Proc.new()    { |user, args| handle_notice(user, args) }
    @@command_map["OPER"] = Proc.new()      { |user, args| handle_oper(user, args) }
    @@command_map["PART"] = Proc.new()      { |user, args| handle_part(user, args) }
    @@command_map["PING"] = Proc.new()      { |user, args| handle_ping(user, args) }
    @@command_map["PRIVMSG"] = Proc.new()   { |user, args| handle_privmsg(user, args) }
    @@command_map["QUIT"] = Proc.new()      { |user, args| handle_quit(user, args) }
    @@command_map["TIME"] = Proc.new()      { |user, args| handle_time(user, args) }
    @@command_map["TOPIC"] = Proc.new()     { |user, args| handle_topic(user, args) }
    @@command_map["USER"] = Proc.new()      { |user, args| handle_user(user, args) }
    @@command_map["VERSION"] = Proc.new()   { |user, args| handle_version(user, args) }
    @@command_map["WHO"] = Proc.new()       { |user, args| handle_who(user, args) }
    @@command_map["WHOIS"] = Proc.new()     { |user, args| handle_whois(user, args) }
  end

  def self.register_command(command_name, command_proc)
    @@command_map[command_name.upcase] = command_proc
  end

  def self.unregister_command(command)
    @@command_map.delete(command.to_s.upcase)
  end

  # ADMIN
  # args[0] = optional server name
  def self.handle_admin(user, args)
    if args.length < 1 || args[0] =~ /^#{Options.server_name}$/i
      Network.send(user, Numeric.RPL_ADMINME(user.nick, Options.server_name))
      Network.send(user, Numeric.RPL_ADMINLOC1(user.nick, Options.server_name))
      Network.send(user, Numeric.RPL_ADMINLOC2(user.nick, Options.server_name))
      Network.send(user, Numeric.RPL_ADMINEMAIL(user.nick, Options.server_name))
    #elsif to handle arbitrary servers when others are linked
    else
      Network.send(user, Numeric.ERR_NOSUCHSERVER(user.nick, args[0]))
    end
  end

  # AWAY
  # args[0] = message
  def self.handle_away(user, args)
    if args.length < 1
      user.set_away("")
      Network.send(user, Numeric.RPL_UNAWAY(user.nick))
    else
      message = args[0..-1].join(" ")
      if message[0] == ':'
        message = message[1..-1]
      end
      if message.length > Limits::AWAYLEN
        message = message[0..Limits::AWAYLEN-1]
      end
      user.set_away(message)
      Network.send(user, Numeric.RPL_NOWAWAY(user.nick))
    end
  end

  # CAP
  # args[0] = subcommand
  def self.handle_cap(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "CAP"))
      return
    end
    case args[0].to_s.upcase
      when "ACK"
        return
      when "CLEAR"
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} ACK :")
        return
      when "END"
        return
      when "LIST"
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} LIST :")
        return
      when "LS"
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} LS :")
        return
      when "REQ"
        return
      else
        Network.send(user, Numeric.ERR_INVALIDCAPCMD(user.nick, args[0]))
        return
    end
  end

  # CAPAB
  # args[0 ... ?] = stuff from Limits class
  def self.handle_capab(server, args)
    # ToDo: Handshaking stuff for server linking
    #Network.send(server, "CAPAB ...")
  end

  # INFO
  # args[0] = optional server name
  def self.handle_info(user, args)
    if args.length < 1 || args[0] =~ /^#{Options.server_name}$/i
      Network.send(user, Numeric.RPL_INFO(user.nick, "#{Server::VERSION}-#{Server::RELEASE}"))
      Network.send(user, Numeric.RPL_INFO(user.nick, Server::URL))
      Network.send(user, Numeric.RPL_ENDOFINFO(user.nick))
    #elsif to handle arbitrary servers when others are linked
    else
      Network.send(user, Numeric.ERR_NOSUCHSERVER(user.nick, args[0]))
    end
  end

  # JOIN
  # args[0 ...] = channel or channels that are comma separated
  # args[1? ...] = optional key or keys that are comma separated
  def self.handle_join(user, args)
  # ToDo: Handle conditions such as invite only and keys later once channels support those modes
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "JOIN"))
      return
    end
    channels = args[0].split(',')
    if args.length == 2
      keys = args[1].split(',')
    end
    channels.each do |channel|
      if user.channels.length >= Limits::MAXCHANNELS
        Network.send(user, Numeric.ERR_TOOMANYCHANNELS(user.nick, channel))
        return
      end
      channel_exists = false
      if channel =~ /[#&][A-Za-z0-9]/
        channel_object = Channel.new(channel, user.nick)
        if Server.channel_map[channel.to_s.upcase] != nil
          channel_exists = true
        end
        unless channel_exists
          Server.add_channel(channel_object)
          Server.channel_count += 1
        end
        user.add_channel(channel)
        chan = Server.channel_map[channel.to_s.upcase]
        unless chan == nil
          chan.add_user(user)
          chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} JOIN :#{channel}") }
        end
        unless channel_exists
          Network.send(user, ":#{Options.server_name} MODE #{channel} +nt")
        end
        Command.handle_names(user, channel.split)
      else
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
      end
    end
  end

  # MODE
  # args[0] = target channel or nick
  # args[1] = mode(s)
  # args[2..-1] = nick, ban mask, limit, and/or key
  # ToDo: Check if user has chanop, founder, or admin privs before setting channel modes
  #       Also allow more than one 'b' and/or 'o' mode at once up to MAXPARAMS (3?) and limit the rest
  #       Add flag prefixes somewhere upon setting the appropriate modes
  #       Handle bans, limit, and key
  #       Handle umodes
  def self.handle_mode(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "MODE"))
      return
    end
    target = args[0]
    if args.length >= 2
      mode_string = args[1]
      modes_to_add = ""
      modes_to_remove = ""
      was_add = true
      args[1].each_char do |char|
        if char == '+'
          was_add = true
          next unless char == nil
        end
        if char == '-'
          was_add = false
          next unless char == nil
        end
        if was_add
          modes_to_add << char
        else
          modes_to_remove << char
        end
      end
      final_add_modes = ""
      final_remove_modes = ""
    end
    if target[0] == '#' || target[0] == '&'
      channel = Server.channel_map[target.to_s.upcase]
      unless channel == nil
        if args.length == 1
          Network.send(user, Numeric.RPL_CHANNELMODEIS(user.nick, channel.name, channel.modes.join("")))
          Network.send(user, Numeric.RPL_CREATIONTIME(user.nick, channel))
          return
        end
        if modes_to_add.length == 0 && modes_to_remove.length == 0
          return
        end
        if modes_to_add.length == 1 && modes_to_add == 'b'
          channel.bans.each do |ban|
            Network.send(user, Numeric.RPL_BANLIST(user.nick, channel.name, ban.creator, ban.create_timestamp))
          end
          Network.send(user, Numeric.RPL_ENDOFBANLIST(user.nick, channel.name))
          return
        end
        user.channels.each do |c|
          unless channel.name.casecmp(c) == 0
            Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, target[0]))
            return
          end
        end
        unless modes_to_add == nil
          modes_to_add.each_char do |mode|
            if Channel::CHANNEL_MODES.include?(mode)
              unless channel.modes.include?(mode)
                final_add_modes << mode
              end
            else
              Network.send(user, Numeric.ERR_UNKNOWNMODE(user.nick, mode))
            end
          end
        end
        unless modes_to_remove == nil
          modes_to_remove.each_char do |mode|
            if Channel::CHANNEL_MODES.include?(mode)
              if channel.modes.include?(mode)
                final_remove_modes << mode
              end
            else
              Network.send(user, Numeric.ERR_UNKNOWNMODE(user.nick, mode))
            end
          end
        end
        unless final_add_modes.length == 0
          # Remove duplicate modes that take no arguments
          # Also remove modes that are given when no arguments to them are provided
          modelist = ""
          final_add_modes.each_char do |mode|
            unless modelist.include?(mode)
              modelist << mode
            end
            if modelist =~ /[filkmnprst]/
              final_add_modes.delete(mode)
            end
            if args[2] == nil
              if modelist =~ /[abflkov]/
                final_add_modes.delete(mode)
              end
            end
          end
          final_add_modes = modelist
          final_add_modes.each_char do |mode|
            channel.add_mode(mode)
          end
        end
        unless final_remove_modes.length == 0
          modelist = ""
          final_remove_modes.each_char do |mode|
            unless modelist.include?(mode)
              modelist << mode
            end
            if modelist =~ /[filkmnprst]/
              final_remove_modes.delete(mode)
            end
            if args[2] == nil
              if modelist =~ /[abflkov]/
                final_remove_modes.delete(mode)
              end
            end
          end
          final_remove_modes = modelist
          final_remove_modes.each_char do |mode|
            channel.add_mode(mode)
          end
        end
        channel.users.each do |u|
          if final_add_modes.length == 0 && final_remove_modes.length == 0
            return
          elsif final_add_modes.length > 0 && final_remove_modes.length > 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} +#{final_add_modes}-#{final_remove_modes}")
          elsif final_add_modes.length > 0 && final_remove_modes.length == 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} +#{final_add_modes}")
          elsif final_add_modes.length == 0 && final_remove_modes.length > 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} -#{final_remove_modes}")
          end
        end
      else
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, target[0]))
        return
      end
    end
  end

  # MODLIST
  # args[0] = optional server (ToDo: Add ability to specify server to get its modules)
  def self.handle_modlist(user, args)
    # ToDo: if check for admin privileges
    if Mod.modules == nil
      Mod.modules = {}
    end
    if Mod.modules.length < 1
      Network.send(user, "No modules are currently loaded.")
      return
    end
    Mod.modules.each { |key, mod| Network.send(user, "#{mod.command_name} (#{mod})") }
  end

  # MODLOAD
  # args[0] = module
  def self.handle_modload(user, args)
    # ToDo: if check for admin privileges
    if args == nil
      return
    end
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "MODLOAD"))
      return
    end
    if Mod.modules == nil
      Mod.modules = {}
    end
    if args.is_a? String
      mod_name = args
    else
      mod_name = args[0]
    end
    if mod_name.length >= 4
      if mod_name[-3, 3] == ".rb"
        mod_name = mod_name[0..-4] # remove .rb extension if the user included it in the module name
      end
    end  
    begin
      new_module = eval(File.read("modules/#{mod_name}.rb"))
      new_module.plugin_init(Command)
    rescue Errno::ENOENT => e
      unless user == nil # called during startup for module autoload, so don't send message down the socket
        Network.send(user, "Failed to load module: #{mod_name}")
      end
      Log.write("Failed to load module: #{mod_name}")
      Log.write(e)
    rescue LoadError => e
      unless user == nil # called during startup for module autoload, so don't send message down the socket
        Network.send(user, "Failed to load module: #{mod_name}")
      end
      Log.write("Failed to load module: #{mod_name}")
      Log.write(e)
    else
      mod_exists = Mod.modules[mod_name.to_s.upcase]
      unless mod_exists == nil
        unless user == nil # called during startup for module autoload, so don't send message down the socket
          Network.send(user, "Module already loaded: #{mod_name} (#{mod_exists})")
          return
        end
      end
      Mod.add(new_module)
      unless user == nil # called during startup for module autoload, so don't send message down the socket
        Network.send(user, "Successfully loaded module: #{mod_name} (#{new_module})")
      end
      Log.write("Successfully loaded module: #{mod_name} (#{new_module})")
    end
  end

  # MODUNLOAD
  # args[0] = module
  def self.handle_modunload(user, args)
    # ToDo: if check for admin privileges
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "MODUNLOAD"))
      return
    end
    if Mod.modules == nil || Mod.modules.length < 1
      Network.send(user, "No modules are currently loaded.")
      return
    end
    mod = Mod.modules[args[0].to_s.upcase]
    unless mod == nil
      begin
        mod_name = args[0]
        mod.plugin_finish(Command)
      rescue NameError => e
        Network.send(user, "Invalid class name for module: #{args[0]}")
        Log.write(e)
        return
      else
        Mod.modules.delete(args[0].to_s.upcase)
        Network.send(user, "Successfully unloaded module: #{args[0]} (#{mod})")
        Log.write("Successfully unloaded module: #{args[0]} (#{mod})")
      end
    else
      Network.send(user, "Module does not exist: #{args[0]}")
    end
  end

  # MOTD
  # args[0] = optional server name
  def self.handle_motd(user, args)
    if args.length < 1 || args[0] =~ /^#{Options.server_name}$/i
      if Server.motd.length == 0
        Network.send(user, Numeric.ERR_NOMOTD(user.nick))
      else
        Network.send(user, Numeric.RPL_MOTDSTART(user.nick))
        Server.motd.each do |line|
          if line.length > Limits::MOTDLINELEN
            line = line[0..Limits::MOTDLINELEN-1]
          end
          line = line.to_s.delete("\n")
          line = line.delete("\r")
          Network.send(user, Numeric.RPL_MOTD(user.nick, line))
        end
        Network.send(user, Numeric.RPL_ENDOFMOTD(user.nick))
      end
    #elsif to handle arbitrary servers when others are linked
    else
      Network.send(user, Numeric.ERR_NOSUCHSERVER(user.nick, args[0]))
    end
  end

  # NAMES
  # args[0] = channel
  def self.handle_names(user, args)
    if args.length < 1
      Network.send(user, Numeric.RPL_ENDOFNAMES(user.nick, "*"))
      return
    end
    userlist = []
    channel = Server.channel_map[args[0].to_s.upcase]
    unless channel == nil
      # ToDo: Add flag prefixes to nicks later
      channel.users.each { |u| userlist << u.nick }
    end
    userlist = userlist[0..-1].join(" ")
    Network.send(user, Numeric.RPL_NAMREPLY(user.nick, args[0], userlist))
    Network.send(user, Numeric.RPL_ENDOFNAMES(user.nick, args[0]))
  end

  # NICK
  # args[0] = new nick
  def self.handle_nick(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NONICKNAMEGIVEN(user.nick))
      return
    end
    if args.length > 1
      Network.send(user, Numeric.ERR_ERRONEOUSNICKNAME(user.nick, args[0..-1].join(" ")))
      return
    end
    nickname = args[0..-1].join(" ")
    if nickname[0] == ':'
      nickname = nickname[1..-1] # remove leading ':' (fix for Pidgin and possibly other clients)
    end
    # We must have exactly 2 tokens so ensure the nick is valid
    if nickname =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i && nickname.length >=1 && nickname.length <= Limits::NICKLEN
      Server.users.each do |u|
        if u.nick.casecmp(nickname) == 0 && user != u
          Network.send(user, Numeric.ERR_NICKNAMEINUSE("*", nickname))
          return
        end
      end
      if user.is_registered && user.nick != nickname
        if user.channels.length > 0
          user.channels.each do |c|
            chan = Server.channel_map[c.to_s.upcase]
            chan.users.each do |u|
              if user.nick != u.nick
                Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} NICK :#{nickname}")
              end
            end
          end
        end
        Network.send(user, ":#{user.nick}!#{user.ident}@#{user.hostname} NICK :#{nickname}")
      end
      user.change_nick(nickname)
      return
    else
      Network.send(user, Numeric.ERR_ERRONEOUSNICKNAME(user.nick, nickname))
      return
    end
  end

  # NOTICE
  # args[0] = target channel or nick
  # args[1..-1] = message
  def self.handle_notice(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NORECIPIENT(user.nick, "NOTICE"))
      return
    end
    if args.length < 2
      Network.send(user, Numeric.ERR_NOTEXTTOSEND(user.nick))
      return
    end
    message = args[1..-1].join(" ")
    message = message[1..-1] # remove leading ':'
    if args[0] =~ /[#&+][A-Za-z0-9]/
      channel = Server.channel_map[args[0].to_s.upcase]
      unless channel == nil
        channel.users.each do |u|
          if u.nick != user.nick
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} NOTICE #{args[0]} :#{message}")
          end
        end
      end
      return
    end
    Server.users.each do |u|
      if u.nick.casecmp(args[0]) == 0
        Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} NOTICE #{u.nick} :#{message}")
        return
      end
    end
    if args[0] == '#'
      Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
    else
      Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, args[0]))
    end
  end

  # OPER
  # args[0] = nick
  # args[1] = password
  def self.handle_oper(user, args)
    if args.length < 2
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "OPER"))
      return
    end
    admin_nick = nil
    oper_nick = nil
    Server.admins.each do |admin|
      if admin.nick.casecmp(args[0]) == 0
        admin_nick = admin.nick
      end
    end
    Server.opers.each do |oper|
      if oper.nick.casecmp(args[0]) == 0
        oper_nick = oper.nick
      end
    end
    if admin_nick == nil && oper_nick == nil
      Network.send(user, Numeric.ERR_NOOPERHOST(user.nick))
      return
    end
    hash = Digest::SHA2.new(256) << args[1]
    unless admin_nick == nil
      Server.admins.each do |admin|
        if admin.nick == admin_nick && admin.hash == hash.to_s
          if admin.host == nil || admin.host == "" || admin.host == '*'
            Network.send(user, Numeric.RPL_YOUAREOPER(user.nick))
            user.set_admin()
            return
          end
          hostmask = admin.host.to_s.gsub('\*', '.*?')
          regx = Regexp.new("^#{hostmask}$", Regexp::IGNORECASE)
          if user.hostname =~ regx
            Network.send(user, Numeric.RPL_YOUAREOPER(user.nick))
            user.set_admin()
            return
          else
            Network.send(user, Numeric.ERR_NOOPERHOST(user.nick))
            return
          end
        else
          Network.send(user, Numeric.ERR_NOOPERHOST(user.nick))
          return
        end
      end
    end
    unless oper_nick == nil
      Server.opers.each do |oper|
        if oper.nick == oper_nick && oper.hash == hash.to_s
          if oper.host == nil || oper.host == "" || oper.host == '*'
            Network.send(user, Numeric.RPL_YOUAREOPER(user.nick))
            user.set_operator()
            return
          end
          hostmask = oper.host.to_s.gsub('\*', '.*?')
          regx = Regexp.new("^#{hostmask}$", Regexp::IGNORECASE)
          if user.hostname =~ regx
            Network.send(user, Numeric.RPL_YOUAREOPER(user.nick))
            user.set_operator()
            return
          else
            Network.send(user, Numeric.ERR_NOOPERHOST(user.nick))
            return
          end
        else
          Network.send(user, Numeric.ERR_NOOPERHOST(user.nick))
        end
      end
    end
  end

  # PART
  # args[0] = channel
  # args[1..-1] = optional part message
  def self.handle_part(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "PART"))
      return
    end
    part_message = ""
    if args.length > 1
      part_message = args[1..-1].join(" ") # 0 may contain ':' and we already supply it
      if part_message[0] == ':'
        part_message = part_message[1..-1]
      end
      if part_message.length > Limits::MAXPART
        part_message = part_message[0..Limits::MAXPART]
      end
    end
    channels = args[0].split(',')
    channels.each do |channel|
      if channel =~ /[#&+][A-Za-z0-9]/
        if user.channels.any? { |c| c.casecmp(channel) == 0 }
          chan = Server.channel_map[channel.to_s.upcase]
          unless chan == nil
            if part_message.length < 1
              chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PART #{channel}") }
            else
              chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PART #{channel} :#{part_message}") }
            end
            chan.remove_user(user)
            if chan.users.length < 1
              Server.remove_channel(channel.upcase)
            end
            user.remove_channel(channel)
          end
        else
          Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, channel))
        end
      else
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
      end
    end
  end

  # PING
  # args[0] = message
  def self.handle_ping(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "PING"))
      return
    end
    # ToDo: Handle ERR_NOORIGIN (409)?
    Network.send(user, ":#{Options.server_name} PONG #{Options.server_name} :#{args[0]}")
  end

  # QUIT
  # args[0..-1] = optional quit message
  def self.handle_quit(user, args)
    quit_message = ""
    unless args.length < 1
      quit_message = args[0..-1].join(" ") # 0 may contain ':' and we already supply it
      if quit_message[0] == ':'
        quit_message = quit_message[1..-1]
      end
      if quit_message.length > Limits::MAXQUIT
        quit_message = quit_message[0..Limits::MAXQUIT]
      end
    end
    if user.channels.length > 0
      user.channels.each do |c|
        chan = Server.channel_map[c.to_s.upcase]
        chan.users.each do |u|
          if args.length < 1 && user.nick != u.nick
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} QUIT :#{user.nick}")
          elsif user.nick != u.nick
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} QUIT :#{quit_message}")
          end
        end
      end
    end
    if user.nick == '*'
      Network.send(user, "ERROR :Closing Link: #{user.hostname} (Quit: Client exited)")
    elsif args.length < 1
      Network.send(user, "ERROR :Closing Link: #{user.hostname} (Quit: #{user.nick})")
    else
      Network.send(user, "ERROR :Closing Link: #{user.hostname} (Quit: #{quit_message})")
    end
    begin
      user.socket.close()
    rescue
      if Server.remove_user(user)
        Server.decrement_clients()
      end
      if user.thread != nil
        Thread.kill(user.thread)
      end
    end
  end

  # PRIVMSG
  # args[0] = target channel or nick
  # args[1..-1] = message
  def self.handle_privmsg(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NORECIPIENT(user.nick, "PRIVMSG"))
      return
    end
    if args.length < 2
      Network.send(user, Numeric.ERR_NOTEXTTOSEND(user.nick))
      return
    end
    message = args[1..-1].join(" ")
    message = message[1..-1] # remove leading ':'
    if args[0] =~ /[#&+][A-Za-z0-9]/
      channel = Server.channel_map[args[0].to_s.upcase]
      unless channel == nil
        channel.users.each do |u|
          if u.nick != user.nick
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PRIVMSG #{args[0]} :#{message}")
          end
        end
      end
      return
    end
    Server.users.each do |u|
      if u.nick.casecmp(args[0]) == 0
        Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PRIVMSG #{u.nick} :#{message}")
        return
      end
    end
    if args[0] == '#'
      Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
    else
      Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, args[0]))
    end
  end

  # TIME
  # args[0] = optional server
  def self.handle_time(user, args)
    if args.length < 1 || args[0] =~ /^#{Options.server_name}$/i
      Network.send(user, Numeric.RPL_TIME(user.nick, Options.server_name))
    #elsif to handle arbitrary servers when others are linked
    else
      Network.send(user, Numeric.ERR_NOSUCHSERVER(user.nick, args[0]))
    end
  end

  # TOPIC
  # args[0] = channel
  # args[1..-1] = topic
  def self.handle_topic(user, args)
    topic = ""
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "TOPIC"))
      return
    end
    # ToDo: Check if this user is a chanop to avoid extra processing every time TOPIC is issued by regular nicks
    if args.length > 1
      topic = args[1..-1].join(" ")
      if topic[0] == ':' && topic.length > 1
        topic = topic[1..-1]
      elsif topic[0] == ':' && topic.length == 1
        topic = ""
      end
      if topic.length >= Limits::TOPICLEN
        topic = topic[0..Limits::TOPICLEN]
      end
    end
    if args[0] =~ /[#&+][A-Za-z0-9]/ && args.length == 1
      chan = Server.channel_map[args[0].to_s.upcase]
      unless chan == nil
        # ToDo: Add if check for channel modes +p and +s
        if chan.topic.length == 0
          Network.send(user, Numeric.RPL_NOTOPIC(user.nick, args[0]))
          return
        else
          Network.send(user, Numeric.RPL_TOPIC(user.nick, args[0], chan.topic))
          unless chan.topic.length == 0
            Network.send(user, Numeric.RPL_TOPICTIME(user.nick, chan))
          end
          return
        end
      # ToDo: else to send numeric here if +p and/or +s are set
      end
      Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
      return
    end
    if args[0] =~ /[#&+][A-Za-z0-9]/ && args.length > 1
      if user.channels.any? { |c| c.casecmp(args[0]) == 0 }
        chan = Server.channel_map[args[0].to_s.upcase]
        unless chan == nil
          # ToDo: Verify chanop status
          if topic.length == 0
            chan.clear_topic()
          else
            chan.set_topic(user, topic)
          end
          chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} TOPIC #{args[0]} :#{topic}") }
        end
      else
        Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, args[0]))
      end
    else
      Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
    end
  end

  # USER
  # args[0] = ident/username
  # args[1] = sometimes ident or hostname (can be spoofed... so we ignore this arg)
  # args[2] = server name (can also be spoofed... so we ignore this arg too)
  # args[3..-1] = gecos/real name
  def self.handle_user(user, args)
    if args.length < 4
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "USER"))
      return
    end
    if user.is_registered
      Network.send(user, Numeric.ERR_ALREADYREGISTERED(user.nick))
      return
    end
    ident = args[0]
    # We don't care about the 2nd and 3rd fields since they are supposed to be hostname and server (these can be spoofed for users)
    # The 2nd field also matches the 1st (ident string) for certain clients (FYI)
    if ident.length > Limits::IDENTLEN
      ident = ident[0..Limits::IDENTLEN-1] # truncate ident if it is too long
    end
    if ident =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
      user.change_ident(ident)
      gecos = args[3..-1].join(" ")
      if gecos[0] == ':'
        gecos = gecos[1..-1] # remove leading ':'
      end
      if gecos.length > Limits::GECOSLEN
        gecos = gecos[0..Limits::GECOSLEN-1] # truncate gecos if it is too long
      end
      user.change_gecos(gecos)
    else
      Network.send(user, Numeric.ERR_INVALIDUSERNAME(user.nick, ident)) # invalid ident
    end
  end

  # VERSION
  # args[0] = optional server
  def self.handle_version(user, args)
    if args.length < 1 || args[0] =~ /^#{Options.server_name}$/i
      Network.send(user, Numeric.RPL_VERSION(user.nick, Options.server_name))
      Network.send(user, Numeric.RPL_ISUPPORT1(user.nick, Options.server_name))
      Network.send(user, Numeric.RPL_ISUPPORT2(user.nick, Options.server_name))
    #elsif to handle arbitrary servers when others are linked
    else
      Network.send(user, Numeric.ERR_NOSUCHSERVER(user.nick, args[0]))
    end
  end

  # WHO
  # args[0] = target pattern to match
  # args[1] = optional 'o' to check for administrators and operators
  def self.handle_who(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "WHO"))
      return
    end
    target = args[0]
    if target[0] == '#' || target[0] == '&'
      channel = Server.channel_map[target.to_s.upcase]
      if channel != nil
        # ToDo: Once MODE is implemented, weed out users who are +i unless they are in the same channel
        # ToDo: Also calculate hops once server linking support is added
        if args[1] == 'o'
          channel.users.each do |u|
            if u.is_admin || u.is_operator
              Network.send(user, Numeric.RPL_WHOREPLY(user.nick, target, u, 0))
            end
          end
        else
          channel.users.each { |u| Network.send(user, Numeric.RPL_WHOREPLY(user.nick, target, u, 0)) } # target here is the channel
        end
        Network.send(user, Numeric.RPL_ENDOFWHO(user.nick, target))
        return
      else
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, target))
        return
      end
    else
      # Target is not a channel, so check nick, gecos, hostname, and server of all users below...
      # ToDo: Again, need to wait for MODE support to weed out +i users not in the same channel
      userlist = Array.new
      pattern = Regexp.escape(target).gsub('\?', '.')
      pattern = pattern.gsub('\*', '.*?')
      regx = Regexp.new("^#{pattern}$", Regexp::IGNORECASE)
      Server.users.each do |u|
        if u.nick =~ regx
          userlist.push(u)
          next unless u == nil
        elsif u.gecos =~ regx
          userlist.push(u)
          next unless u == nil
        elsif u.hostname =~ regx
          userlist.push(u)
          next unless u == nil
        elsif u.server =~ regx
          userlist.push(u)
          next unless u == nil
        end
      end
      same_channel = false
      userlist.each do |u|
        same_channel == false
        if args[1] == 'o'
          if u.is_admin || u.is_operator
            user.channels.each do |my_channel|
              if u.channels.any? { |c| c.casecmp(my_channel) == 0 }
                Network.send(user, Numeric.RPL_WHOREPLY(user.nick, my_channel, u, 0))
                same_channel = true
                break
              end
            end
            unless same_channel
              Network.send(user, Numeric.RPL_WHOREPLY(user.nick, '*', u, 0))
            end
          end
        else
          user.channels.each do |my_channel|
            if u.channels.any? { |c| c.casecmp(my_channel) == 0 }
              Network.send(user, Numeric.RPL_WHOREPLY(user.nick, my_channel, u, 0))
              same_channel = true
              break
            end
          end
          unless same_channel
            Network.send(user, Numeric.RPL_WHOREPLY(user.nick, '*', u, 0))
          end
        end
      end
      Network.send(user, Numeric.RPL_ENDOFWHO(user.nick, target))
    end
  end

  # WHOIS
  # args[0] = nick
  # ToDo: Support wildcards per RFC 1459
  def self.handle_whois(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "WHOIS"))
      return
    end
    Server.users.each do |u|
      if u.nick.casecmp(args[0]) == 0
        Network.send(user, Numeric.RPL_WHOISUSER(user.nick, u))
        if u.channels.length > 0
          Network.send(user, Numeric.RPL_WHOISCHANNELS(user.nick, u))
        end
        Network.send(user, Numeric.RPL_WHOISSERVER(user.nick, u))
        if u.is_operator && !u.is_admin
          Network.send(user, Numeric.RPL_WHOISOPERATOR(user.nick, u))
        end
        if u.is_admin && !u.is_operator
          Network.send(user, Numeric.RPL_WHOISADMIN(user.nick, u))
        end
        # ToDo: Add is_bot and is_service check later
        if u.nick_registered
          Network.send(user, Numeric.RPL_WHOISREGNICK(user.nick, u))
        end
        if u.away_message.length > 0
          Network.send(user, Numeric.RPL_AWAY(user.nick, u))
        end
        # ToDo: If hostname cloaking is enabled for this user, do not send this numeric
        Network.send(user, Numeric.RPL_WHOISACTUALLY(user.nick, u))
        Network.send(user, Numeric.RPL_WHOISIDLE(user.nick, u))
        Network.send(user, Numeric.RPL_ENDOFWHOIS(user.nick, u))
        return
      end
    end
    Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, args[0]))
  end

  # Standard commands remaining to be implemented:
  # away
  # connect
  # error
  # invite
  # ison
  # kick
  # kill
  # kline
  # links
  # list
  # operwall
  # pass
  # pong
  # rehash
  # restart
  # server
  # shutdown
  # squit
  # stats
  # summon
  # trace
  # userhost
  # users
  # whowas

  # Custom commands that may get implemented:
  # broadcast <message> (administrative command to alert users of anything significant such as an upcoming server outage)
  # fjoin <channel> <nick> (administrative force join)
  # fpart <channel> <nick> (administrative force part)
  # fnick <current_nick> <new_nick> (administrative force nick change -- also useful for future services and registered nickname protection)
  # vhost <nick> <new_hostname> (administrative command to change a user's hostname)

  def self.command_map
    @@command_map
  end
end # class

class Mod
  @@modules = {}

  def self.init_locks()
    @@modules_lock = Mutex.new
  end

  def self.modules
    @@modules
  end

  def self.add(mod)
    if Options.io_type.to_s == "thread"
      @@modules_lock.synchronize { @@modules[mod.command_name.upcase] = mod }
    else
      @@modules[mod.command_name.upcase] = mod
    end
  end
end
