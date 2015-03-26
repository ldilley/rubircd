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
  # Retrieves topic information for a target channel or sets the topic on a
  # target channel to the one specified
  class Topic
    def initialize
      @command_name = 'topic'
      @command_proc = proc { |user, args| on_topic(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = channel
    # args[1] = topic
    def on_topic(user, args)
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'TOPIC'))
        return
      end
      args = args.join.split(' ', 2)
      if args.length > 1
        args[1] = args[1][1..-1] if args[1][0] == ':' # remove leading ':'
        args[1] = args[1][0..Limits::TOPICLEN] if args[1].length >= Limits::TOPICLEN
      end
      if args[0] =~ /[#&+][A-Za-z0-9_!-]/ && args.length == 1
        chan = Server.channel_map[args[0].to_s.upcase]
        unless chan.nil?
          # TODO: Add if check for channel modes +p and +s
          if chan.topic.length == 0
            Network.send(user, Numeric.rpl_notopic(user.nick, args[0]))
            return
          else
            Network.send(user, Numeric.rpl_topic(user.nick, args[0], chan.topic))
            unless chan.topic.length == 0
              Network.send(user, Numeric.rpl_topictime(user.nick, chan))
            end
            return
          end
          # TODO: else send numeric here if +p and/or +s are set
        end
        Network.send(user, Numeric.err_nosuchchannel(user.nick, args[0]))
        return
      end
      if args[0] =~ /[#&+][A-Za-z0-9_!-]/ && args.length > 1
        user_on_channel = false
        user_channels = user.channels_array
        user_channels.each do |c|
          next unless c.casecmp(args[0]) == 0
          user_on_channel = true
          chan = Server.channel_map[args[0].to_s.upcase]
          next if chan.nil?
          if chan.mode?('t') && !user.halfop?(chan.name) && !user.chanop?(chan.name) && !user.admin && !user.service
            Network.send(user, Numeric.err_chanoprivsneeded(user.nick, chan.name))
            return
          end
          if args[1].nil? || args[1].length == 0
            chan.clear_topic
          else
            chan.set_topic(user, args[1])
          end
          chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} TOPIC #{args[0]} :#{args[1]}") }
        end
        unless user_on_channel
          Network.send(user, Numeric.err_notonchannel(user.nick, args[0]))
        end
      else
        Network.send(user, Numeric.err_nosuchchannel(user.nick, args[0]))
      end
    end
  end
end
Standard::Topic.new
