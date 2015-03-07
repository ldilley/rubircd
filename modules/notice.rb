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
  class Notice
    def initialize()
      @command_name = "notice"
      @command_proc = Proc.new() { |user, args| on_notice(user, args) }
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

    # args[0] = target channel or nick or comma-separated channels and nicks
    # args[1] = message
    def on_notice(user, args)
      args = args.join.split(' ', 2)
      if args.length < 1
        Network.send(user, Numeric.ERR_NORECIPIENT(user.nick, "NOTICE"))
        return
      end
      if args.length < 2
        Network.send(user, Numeric.ERR_NOTEXTTOSEND(user.nick))
        return
      end
      if args[1][0] == ':'
        args[1] = args[1][1..-1] # remove leading ':'
      end
      good_targets = 0
      targets = args[0].split(',')
      targets.each do |target|
        if good_targets >= Limits::MAXTARGETS
          Network.send(user, Numeric.ERR_TOOMANYTARGETS(user.nick, target))
          next unless target == nil
        end
        if target =~ /[#&+][A-Za-z0-9_!-]/
          channel = Server.channel_map[target.to_s.upcase]
          unless channel == nil
            good_targets += 1
            user_on_channel = false
            if Options.io_type.to_s == "thread"
              user.channels_lock.synchronize do
            end
            user.channels.each_key do |uc|
              if uc.casecmp(target) == 0
                user_on_channel = true
              end
            end
            if Options.io_type.to_s == "thread"
              end
            end
            if user_on_channel || !channel.modes.include?('n')
              channel.users.each do |u|
                if u.nick != user.nick
                  Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} NOTICE #{target} :#{args[1]}")
                end
              end
            else
              Network.send(user, Numeric.ERR_CANNOTSENDTOCHAN(user.nick, channel.name, "no external messages"))
            end
          else
            Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, target))
          end
        else
          good_nick = false
          Server.users.each do |u|
            if u.nick.casecmp(target) == 0
              Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} NOTICE #{u.nick} :#{args[1]}")
              good_nick = true
              good_targets += 1
            end
          end
          unless good_nick
            Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, target))
          end
        end
      end
    end
  end
end
Standard::Notice.new
