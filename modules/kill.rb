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
  class Kill
    def initialize()
      @command_name = "kill"
      @command_proc = Proc.new() { |user, args| on_kill(user, args) }
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

    # args[0] = target nick
    # args[1..-1] = message
    def on_kill(user, args)
      unless user.is_operator || user.is_admin || user.is_service
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "KILL"))
        return
      end
      if args.length >= 2
        kill_message = args[1..-1].join(" ")
        if kill_message[0] == ':'
          kill_message = kill_message[1..-1]
        end
      else
        kill_message = "No reason given"
      end
      kill_target = nil
      Server.users.each do |u|
        if u.nick.casecmp(args[0]) == 0
          kill_target = u
        end
      end
      unless kill_target == nil
        if (kill_target.is_admin && !user.is_admin) || kill_target.is_service
          Network.send(user, Numeric.ERR_ATTACKDENY(user.nick, kill_target.nick))
          if kill_target.is_admin
            Network.send(kill_target, ":#{Options.server_name} NOTICE #{kill_target.nick} :#{user.nick} attempted to kill you!")
          end
          return
        end
        # ToDo: Send server/operwall message
        Network.send(kill_target, ":#{user.nick}!#{user.ident}@#{user.hostname} KILL #{kill_target.nick} :#{Options.server_name}!#{user.hostname}!#{user.nick} (#{kill_message})")
        Network.send(kill_target, "ERROR :Closing link: #{kill_target.hostname} [Killed (#{user.nick} (#{kill_message}))]")
        Log.write("#{kill_target.nick}!#{kill_target.ident}@#{kill_target.hostname} was killed by #{user.nick}!#{user.ident}@#{user.hostname}: #{kill_message}")
        Network.close(kill_target, "Killed (#{user.nick} (#{kill_message}))")
      else
        Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, args[0]))
      end
    end
  end
end
Standard::Kill.new