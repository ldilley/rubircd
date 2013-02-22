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
    # args[1..-1] = optional part message
    def on_part(user, args)
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
        if channel =~ /[#&+][A-Za-z0-9_!-]/
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
  end
end
Standard::Part.new
