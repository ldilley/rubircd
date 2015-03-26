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
  # Sends a specified message to a target channel or nick
  class Privmsg
    def initialize
      @command_name = 'privmsg'
      @command_proc = proc { |user, args| on_privmsg(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = target channel or nick or comma-separated channels and nicks
    # args[1] = message
    def on_privmsg(user, args)
      args = args.join.split(' ', 2)
      if args.length < 1
        Network.send(user, Numeric.err_norecipient(user.nick, 'PRIVMSG'))
        return
      end
      if args.length < 2
        Network.send(user, Numeric.err_notexttosend(user.nick))
        return
      end
      args[1] = args[1][1..-1] if args[1][0] == ':' # remove leading ':'
      good_targets = 0
      targets = args[0].split(',')
      targets.each do |target|
        if good_targets >= Limits::MAXTARGETS
          Network.send(user, Numeric.err_toomanytargets(user.nick, target))
          next unless target.nil?
        end
        if Channel.valid_channel_name?(target)
          channel = Server.channel_map[target.to_s.upcase]
          if channel.nil?
            Network.send(user, Numeric.err_nosuchchannel(user.nick, target))
          else
            good_targets += 1
            if user.on_channel?(target) || !channel.modes.include?('n')
              channel.users.each do |u|
                if u.nick != user.nick
                  Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PRIVMSG #{target} :#{args[1]}")
                end
              end
            else
              Network.send(user, Numeric.err_cannotsendtochan(user.nick, channel.name, 'no external messages'))
            end
          end
        else
          good_nick = false
          Server.users.each do |u|
            next unless u.nick.casecmp(target) == 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} PRIVMSG #{u.nick} :#{args[1]}")
            good_nick = true
            good_targets += 1
          end
          unless good_nick
            Network.send(user, Numeric.err_nosuchnick(user.nick, target))
          end
        end
      end
    end
  end
end
Standard::Privmsg.new
