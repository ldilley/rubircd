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
  # Finds users on the network with a specified pattern
  # If 'o' is specified, only administrators and IRC operators are returned
  # Invisible users (umode +i) are not returned unless the issuer is an
  # administrator or IRC operator
  class Who
    def initialize
      @command_name = 'who'
      @command_proc = proc { |user, args| on_who(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = target pattern to match
    # args[1] = optional 'o' to check for administrators and operators
    def on_who(user, args)
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'WHO'))
        return
      end
      args = args.join.split(' ', 2)
      if args[0][0] == '#' || args[0][0] == '&'
        channel = Server.channel_map[args[0].to_s.upcase]
        if !channel.nil?
          # TODO: Once MODE is implemented, weed out users who are +i unless they are in the same channel
          # TODO: Also calculate hops once server linking support is added
          if args[1] == 'o'
            channel.users.each do |u|
              next if !user.is_admin? && channel.invisible_nick_in_channel?(u.nick) # hide admins who used IJOIN
              if u.is_admin? || u.is_operator?
                Network.send(user, Numeric.rpl_whoreply(user.nick, args[0], u, 0))
              end
            end
          else
            # Target here is the channel
            channel.users.each do |u|
              next if !user.is_admin? && channel.invisible_nick_in_channel?(u.nick)
              Network.send(user, Numeric.rpl_whoreply(user.nick, args[0], u, 0))
            end
          end
          Network.send(user, Numeric.rpl_endofwho(user.nick, args[0]))
          return
        else
          Network.send(user, Numeric.err_nosuchchannel(user.nick, args[0]))
          return
        end
      else
        # Target is not a channel, so check nick, gecos, hostname, and server of all users below...
        # TODO: Again, need to wait for MODE support to weed out +i users not in the same channel
        userlist = []
        pattern = Regexp.escape(args[0]).gsub('\?', '.')
        pattern = pattern.gsub('\*', '.*?')
        regx = Regexp.new("^#{pattern}$", Regexp::IGNORECASE)
        Server.users.each do |u|
          if u.nick =~ regx
            userlist.push(u)
            next unless u.nil?
          elsif u.gecos =~ regx
            userlist.push(u)
            next unless u.nil?
          elsif u.hostname =~ regx
            userlist.push(u)
            next unless u.nil?
          elsif u.server =~ regx
            userlist.push(u)
            next unless u.nil?
          end
        end
        same_channel = false
        userlist.each do |u|
          same_channel = false
          if args[1] == 'o'
            if u.is_admin? || u.is_operator?
              user_channels = user.get_channels_array
              u_channels = u.get_channels_array
              user_channels.each do |my_channel|
                u_channels.each do |c|
                  next unless c.casecmp(my_channel) == 0
                  channel = Server.channel_map[c.upcase]
                  unless channel.nil?
                    next if !user.is_admin? && channel.invisible_nick_in_channel?(u.nick)
                  end
                  Network.send(user, Numeric.rpl_whoreply(user.nick, my_channel, u, 0))
                  same_channel = true
                  break
                end
              end
              unless same_channel
                Network.send(user, Numeric.rpl_whoreply(user.nick, '*', u, 0))
              end
            end
          else
            user_channels = user.get_channels_array
            u_channels = u.get_channels_array
            user_channels.each do |my_channel|
              u_channels.each do |c|
                next unless c.casecmp(my_channel) == 0
                channel = Server.channel_map[c.upcase]
                unless channel.nil?
                  next if !user.is_admin? && channel.invisible_nick_in_channel?(u.nick)
                end
                Network.send(user, Numeric.rpl_whoreply(user.nick, my_channel, u, 0))
                same_channel = true
                break
              end
            end
            unless same_channel
              Network.send(user, Numeric.rpl_whoreply(user.nick, '*', u, 0))
            end
          end
        end
        Network.send(user, Numeric.rpl_endofwho(user.nick, args[0]))
      end
    end
  end
end
Standard::Who.new
