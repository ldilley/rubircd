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
  class Ijoin
    def initialize()
      @command_name = "ijoin"
      @command_proc = Proc.new() { |user, args| on_ijoin(user, args) }
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

    # args[0] = channel
    def on_ijoin(user, args)
      unless user.is_admin?
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "IJOIN"))
        return
      end
      unless Channel.is_valid_channel_name?(args[0])
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
        return
      end
      if user.is_on_channel?(args[0])
        Network.send(user, Numeric.ERR_USERONCHANNEL(user.nick, user.nick, args[0]))
        return
      end
      # Allow administrators to bypass channel cap
      #if user.get_channels_length() >= Limits::MAXCHANNELS
      #  Network.send(user, Numeric.ERR_TOOMANYCHANNELS(user.nick, args[0]))
      #  return
      #end
      channel_existed = false
      chan = Server.channel_map[args[0].to_s.upcase]
      if chan == nil
        channel_object = Channel.new(args[0], user.nick)
        Server.add_channel(channel_object)
        chan = Server.channel_map[args[0].to_s.upcase]
        user.add_channel(args[0])
        user.add_channel_mode(args[0], 'o')
      else
        channel_existed = true
        user.add_channel(args[0])
      end
      chan.add_user(user)
      chan.add_invisible_user(user)
      # Only show IJOIN to other administrators in the channel
      chan.users.each do |u|
        if u.is_admin?
          Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} JOIN :#{args[0]}")
        end
      end
      unless channel_existed
        # ToDo: Make user chanop if they are the first user on the channel and channel is not +r
        Network.send(user, ":#{Options.server_name} MODE #{args[1]} +nt")
      end
      names_cmd = Command.command_map["NAMES"]
      unless names_cmd == nil
        names_cmd.call(user, args[0])
      end
      Server.users.each do |u|
        if u.is_admin? || u.is_operator?
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued IJOIN for: #{args[0]}")
        end
      end
      Log.write(2, "IJOIN issued by #{user.nick}!#{user.ident}@#{user.hostname} for: #{args[0]}")
    end
  end
end
Optional::Ijoin.new
