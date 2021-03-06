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
  # Changes your nick to a specified nick
  class Nick
    def initialize
      @command_name = 'nick'
      @command_proc = proc { |user, args| on_nick(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = new nick
    def on_nick(user, args)
      args = args.join.split
      if args.length < 1
        Network.send(user, Numeric.err_nonicknamegiven(user.nick))
        return
      end
      if args.length > 1
        Network.send(user, Numeric.err_erroneousnickname(user.nick, args[0..-1].join(' '), 'Nicknames cannot contain spaces.'))
        return
      end
      # Remove leading ':' (fix for Pidgin and possibly other clients)
      args[0] = args[0][1..-1].strip if args[0][0] == ':'
      if args[0].length < 1 || args[0].length > Limits::NICKLEN
        Network.send(user, Numeric.err_erroneousnickname(user.nick, args[0], 'Nickname does not meet length requirements.'))
        return
      end
      if args[0] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
        Server.users.each do |u|
          next unless u.nick.casecmp(args[0]) == 0 && user != u
          if user.registered
            Network.send(user, Numeric.err_nicknameinuse(user.nick, args[0]))
          else
            Network.send(user, Numeric.err_nicknameinuse('*', args[0]))
          end
          return
        end
        unless Server.qline_mod.nil?
          Server.qline_mod.list_qlines.each do |reserved_nick|
            next unless reserved_nick.target.casecmp(args[0]) == 0 && user.nick != reserved_nick.target
            if user.registered
              Network.send(user, Numeric.err_erroneousnickname(user.nick, args[0], reserved_nick.reason))
            else
              Network.send(user, Numeric.err_erroneousnickname('*', args[0], reserved_nick.reason))
            end
            return
          end
        end
        if user.registered && user.nick != args[0]
          if user.channels_length > 0
            user_channels = user.channels_array
            user_channels.each do |c|
              chan = Server.channel_map[c.to_s.upcase]
              chan.users.each do |u|
                if user.nick != u.nick
                  Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} NICK :#{args[0]}")
                end
              end
            end
          end
          Network.send(user, ":#{user.nick}!#{user.ident}@#{user.hostname} NICK :#{args[0]}")
        end
        whowas_loaded = Command.command_map['WHOWAS']
        unless whowas_loaded.nil?
          unless user.nick.nil? || user.nick == '*'
            Server.whowas_mod.add_entry(user, ::Time.now.asctime)
          end
        end
        user.nick = args[0]
      else
        Network.send(user, Numeric.err_erroneousnickname(user.nick, args[0], 'Nickname contains invalid characters.'))
      end
    end
  end
end
Standard::Nick.new
