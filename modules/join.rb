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
  class Join
    def initialize()
      @command_name = "join"
      @command_proc = Proc.new() { |user, args| on_join(user, args) }
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

    # args[0] = channel or channels that are comma separated
    # args[1] = optional key or keys that are comma separated
    def on_join(user, args)
      args = args.join.split(' ', 2)
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
        if user.channels.any? { |uc| uc.casecmp(channel) == 0 }
          return # user is already on channel
        end
        if user.channels.length >= Limits::MAXCHANNELS
          Network.send(user, Numeric.ERR_TOOMANYCHANNELS(user.nick, channel))
          return
        end
        channel_exists = false
        if channel =~ /[#&][A-Za-z0-9_!-]/
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
            # ToDo: Also give chanop status to first user on channel unless it is +r
            Network.send(user, ":#{Options.server_name} MODE #{channel} +nt")
          end
          names_cmd = Command.command_map["NAMES"]
          unless names_cmd == nil
            names_cmd.call(user, channel.split)
          end
        else
          Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
        end
      end
    end
  end
end
Standard::Join.new
