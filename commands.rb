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
    @@command_map["ADMIN"] = Proc.new() {|user, args| handle_admin(user, args)}
    @@command_map["CAP"] = Proc.new() {|user, args| handle_cap(user, args)}
    @@command_map["JOIN"] = Proc.new() {|user, args| handle_join(user, args)}
    @@command_map["NICK"] = Proc.new() {|user, args| handle_nick(user, args)}
    @@command_map["PING"] = Proc.new() {|user, args| handle_ping(user, args)}
    @@command_map["QUIT"] = Proc.new() {|user, args| handle_quit(user, args)}
    @@command_map["USER"] = Proc.new() {|user, args| handle_user(user, args)}
    @@command_map["VERSION"] = Proc.new() {|user, args| handle_version(user, args)}
  end

  def self.handle_admin(user, args)
    if args.length < 1 || args[0] == Options.server_name
      Network.send(user, Numeric.RPL_ADMINME(user.nick))
      Network.send(user, Numeric.RPL_ADMINLOC1(user.nick))
      Network.send(user, Numeric.RPL_ADMINLOC2(user.nick))
      Network.send(user, Numeric.RPL_ADMINEMAIL(user.nick))
    end
  end

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

  def self.handle_join(user, args)
  # ToDo: Handle conditions such as invite only and keys later once channels support those modes
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "JOIN"))
      return
    end
    channel = args[0]
    if channel[0] != '#'
      Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
      return
    end
  end

  def self.handle_nick(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NONICKNAMEGIVEN(user.nick))
      return
    end
    if args.length > 1
      Network.send(user, Numeric.ERR_ERRONEOUSNICKNAME(user.nick, args[0..args.length].join(" ")))
      return
    end
    # We must have exactly 2 tokens so ensure the nick is valid
    if args[0] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i && args[0].length >=1 && args[0].length <= Limits::NICKLEN
      Server.users.each do |u|
        if u.nick.casecmp(args[0]) == 0
          Network.send(user, Numeric.ERR_NICKNAMEINUSE("*", args[0]))
          return
        end
      end
      if user.is_registered
        Network.send(user, ":#{user.nick}!#{user.ident}@#{user.hostname} NICK :#{args[0]}")
      end
      user.change_nick(args[0])
      return
    else
      Network.send(user, Numeric.ERR_ERRONEOUSNICKNAME(user.nick, args[0]))
      return
    end
  end

  def self.handle_ping(user, args)
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "PING"))
      return
    end
    # ToDo: Handle ERR_NOORIGIN (409)?
    Network.send(user, ":#{Options.server_name} PONG #{Options.server_name} :#{args[0]}")
  end

  def self.handle_quit(user, args)
    begin
      user.socket.close()
    rescue
      Thread.kill(user.thread)
    ensure
      Server.client_count -= 1
      Server.remove_user(user)
    end
  end

  def self.handle_user(user, args)
    if args.length < 4
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "USER"))
      return
    end
    if user.is_registered
      Network.send(user, Numeric.ERR_ALREADYREGISTERED(user.nick))
      return
    end
    gecos = args[3]
    # We don't care about the 2nd and 3rd fields since they are supposed to be hostname and server (these can be spoofed for users)
    # The 2nd field also matches the 1st (ident string) for certain clients (FYI)
    if args[0].length <= Limits::IDENTLEN && gecos[0] == ':'
      if args[0] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
        user.change_ident(args[0])
        gecos = args[3..args.length].join(" ")
        gecos = gecos[1..gecos.length] # remove leading ':'
        # Truncate gecos field if too long
        if gecos.length > Limits::GECOSLEN
          gecos = gecos[0..Limits::GECOSLEN-1]
        end
        user.change_gecos(gecos)
        return
      else
        Network.send(user, Numeric.ERR_INVALIDUSERNAME(user.nick, args[0])) # invalid ident
        return
      end
    else
      # If we arrive here, just truncate the ident and add the gecos anyway? ToDo: ensure ident is still valid...
      return # ident too long or invalid gecos
    end
  end

  def self.handle_version(user, args)
    if args.length < 1 || args[0] == Options.server_name
      Network.send(user, Numeric.RPL_VERSION(user.nick))
      Network.send(user, Numeric.RPL_ISUPPORT1(user.nick))
      Network.send(user, Numeric.RPL_ISUPPORT2(user.nick))
    end
  end

  # admin
  # away
  # connect
  # error
  # info
  # invite
  # ison
  # kick
  # kill
  # links
  # list
  # mode
  # motd
  # names
  # notice
  # oper
  # operwall
  # part
  # pass
  # pong
  # privmsg
  # rehash
  # restart
  # server
  # shutdown
  # squit
  # stats
  # summon
  # time
  # topic
  # trace
  # userhost
  # users
  # version
  # who
  # whois
  # whowas

end # class
