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
  class Topic
    def initialize()
      @command_name = "topic"
      @command_proc = Proc.new() { |user, args| on_topic(user, args) }
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
    # args[1] = topic
    def on_topic(user, args)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "TOPIC"))
        return
      end
      args = args.join.split(' ', 2)
      # ToDo: Check if this user is a chanop to avoid extra processing every time TOPIC is issued by regular nicks
      if args.length > 1
        if args[1][0] == ':'
          args[1] = args[1][1..-1] # remove leading ':'
        end
        if args[1].length >= Limits::TOPICLEN
          args[1] = args[1][0..Limits::TOPICLEN]
        end
      end
      if args[0] =~ /[#&+][A-Za-z0-9_!-]/ && args.length == 1
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
      if args[0] =~ /[#&+][A-Za-z0-9_!-]/ && args.length > 1
        user_on_channel = false
        if Options.io_type.to_s == "thread"
          user.channels_lock.synchronize do
        end
        user.channels.each_key do |c|
          if c.casecmp(args[0]) == 0
            user_on_channel = true
            chan = Server.channel_map[args[0].to_s.upcase]
            unless chan == nil
              # ToDo: Verify chanop status
              if args[1] == nil || args[1].length == 0
                chan.clear_topic()
              else
                chan.set_topic(user, args[1])
              end
              chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} TOPIC #{args[0]} :#{args[1]}") }
            end
          end
        end
        if Options.io_type.to_s == "thread"
          end
        end
        unless user_on_channel
          Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, args[0]))
        end
      else
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
      end
    end
  end
end
Standard::Topic.new
