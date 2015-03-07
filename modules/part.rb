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

module Standard
  class Part
    def initialize()
      @command_name = "part"
      @command_proc = Proc.new() { |user, args| on_part(user, args) }
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
    # args[1] = optional part message
    def on_part(user, args)
      args = args.join.split(' ', 2)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "PART"))
        return
      end
      if args.length > 1
        if args[1][0] == ':'
          args[1] = args[1][1..-1] # remove leading ':'
        end
        if args[1].length > Limits::MAXPART
          args[1] = args[1][0..Limits::MAXPART-1]
        end
      end
      channels = args[0].split(',')
      channels.each do |channel|
        user_on_channel = false
        if channel =~ /[#&+][A-Za-z0-9_!-]/
          if Options.io_type.to_s == "thread"
            user.channels_lock.synchronize do
          end
          user.channels.each_key do |c|
            if c.casecmp(channel) == 0
              user_on_channel = true
              chan = Server.channel_map[channel.to_s.upcase]
              unless chan == nil
                if args[1] == nil
                  chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PART #{channel}") }
                else
                  chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PART #{channel} :#{args[1]}") }
                end
                chan.remove_user(user)
                if chan.users.length < 1
                  Server.remove_channel(channel.upcase)
                end
                user.remove_channel(channel)
              end
            end
          end
          if Options.io_type.to_s == "thread"
            end
          end
          unless user_on_channel
            Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, channel))
          end
        else
          Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
        end
      end
    end
  end
end
Standard::Part.new
