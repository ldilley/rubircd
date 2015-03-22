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
  # Sends a message to all voiced users in a specified channel
  class Wallvoices
    def initialize
      @command_name = 'wallvoices'
      @command_proc = proc { |user, args| on_wallvoices(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = channel
    # args[1] = message
    def on_wallvoices(user, args)
      args = args.join.split(' ', 2)
      if args.length < 1
        Network.send(user, Numeric.ERR_NORECIPIENT(user.nick, 'WALLVOICES'))
        return
      end
      if args.length < 2
        Network.send(user, Numeric.ERR_NOTEXTTOSEND(user.nick))
        return
      end
      args[1] = args[1][1..-1] if args[1][0] == ':' # remove leading ':'
      unless Channel.is_valid_channel_name?(args[0])
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
        return
      end
      chan = Server.channel_map[args[0].to_s.upcase]
      if chan.nil?
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
        return
      end
      if user.is_on_channel?(args[0]) || !chan.modes.include?('n')
        chan.users.each do |u|
          if u.is_voiced?(args[0]) && u.nick.casecmp(user.nick) != 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} NOTICE +#{args[0]} :#{args[1]}")
          end
        end
      else
        Network.send(user, Numeric.ERR_CANNOTSENDTOCHAN(user.nick, args[0], 'no external messages'))
      end
    end
  end
end
Optional::Wallvoices.new
