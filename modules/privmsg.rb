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

module Standard
  class Privmsg
    def initialize()
      @command_name = "privmsg"
      @command_proc = Proc.new() { |user, args| on_privmsg(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    def command_name
      @command_name
    end

    # args[0] = target channel or nick
    # args[1..-1] = message
    def on_privmsg(user, args)
      if args.length < 1
        Network.send(user, Numeric.ERR_NORECIPIENT(user.nick, "PRIVMSG"))
        return
      end
      if args.length < 2
        Network.send(user, Numeric.ERR_NOTEXTTOSEND(user.nick))
        return
      end
      message = args[1..-1].join(" ")
      #message = message[1..-1] # remove leading ':'
      if args[0] =~ /[#&+][A-Za-z0-9_!-]/
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
  end
end
Standard::Privmsg.new
