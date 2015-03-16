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

module Optional
  class Fpart
    def initialize()
      @command_name = "fpart"
      @command_proc = Proc.new() { |user, args| on_fpart(user, args) }
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

    # args[0] = nick
    # args[1] = channel
    # args[2] = optional part message
    def on_fpart(user, args)
      args = args.join.split(' ', 3)
      unless user.is_admin?
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 2
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "FPART"))
        return
      end
      unless Channel.is_valid_channel_name?(args[1])
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[1]))
        return
      end
      target_user = Server.get_user_by_nick(args[0])
      if target_user == nil
        Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, args[0]))
        return
      end
      unless target_user.is_on_channel?(args[1])
        Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, args[1]))
        return
      end
      chan = Server.channel_map[args[1].to_s.upcase]
      unless chan == nil
        if args[2] == nil
          chan.users.each { |u| Network.send(u, ":#{target_user.nick}!#{target_user.ident}@#{target_user.hostname} PART #{args[1]}") }
        else
          chan.users.each { |u| Network.send(u, ":#{target_user.nick}!#{target_user.ident}@#{target_user.hostname} PART #{args[1]} :#{args[2]}") }
        end
        chan.remove_user(target_user)
        if chan.users.length < 1
          Server.remove_channel(args[1].upcase)
        end
        target_user.remove_channel(args[1])
      end
      Server.users.each do |u|
        if u.is_admin? || u.is_operator?
          if args[2] == nil
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued FPART for #{args[0]} parting from: #{args[1]}")
          else
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued FPART for #{args[0]} parting from #{args[1]} with message: #{args[2]}")
          end
        end
      end
      if args[2] == nil
        Log.write(2, "FPART issued by #{user.nick}!#{user.ident}@#{user.hostname} for #{target_user.nick}!#{target_user.ident}@#{target_user.hostname} parting from: #{args[1]}")
      else
        Log.write(2, "FPART issued by #{user.nick}!#{user.ident}@#{user.hostname} for #{target_user.nick}!#{target_user.ident}@#{target_user.hostname} parting from #{args[1]} with message: #{args[2]}")
      end
    end
  end
end
Optional::Fpart.new
