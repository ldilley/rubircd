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
  class Kick
    def initialize()
      @command_name = "kick"
      @command_proc = Proc.new() { |user, args| on_kick(user, args) }
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
    # args[1] = user or comma-separated users
    # args[2] = optional reason
    def on_kick(user, args)
      args = args.join.split(' ', 3)
      if args.length < 2
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "KICK"))
        return
      end
      chan = Server.channel_map[args[0].to_s.upcase]
      if chan == nil
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, args[0]))
        return
      end
      unless user.is_on_channel?(chan.name)
        Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, args[0]))
        return
      end
      if !user.is_chanop?(chan.name) && !user.is_admin? && !user.is_service?
        Network.send(user, Numeric.ERR_CHANOPRIVSNEEDED(user.nick, chan.name))
        return
      end
      nicks = args[1].split(',')
      if args.length == 3
        if args[2][0] == ':'
          args[2] = args[2][1..-1] # remove leading ':'
        end
        if args[2].length > Limits::KICKLEN
          args[2] = args[2][0..Limits::KICKLEN-1]
        end
      end
      good_nicks = []
      kick_count = 0
      nicks.each do |n|
        if Server.users.any? { |u| u.nick.casecmp(n) == 0 }
          good_nicks << n
        else
          Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, n))
        end
      end
      good_nicks.each do |n|
        Server.users.each do |u|
          if u.nick.casecmp(n) == 0
            if !u.is_on_channel?(chan.name)
              Network.send(user, Numeric.ERR_USERNOTINCHANNEL(user.nick, u.nick, chan.name))
            elsif (u.is_admin? && !user.is_admin?) || u.is_service?
              Network.send(user, Numeric.ERR_ATTACKDENY(user.nick, u.nick))
              if u.is_admin?
                Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :#{user.nick} attempted to kick you from #{chan.name}")
              end
            elsif kick_count >= Limits::MODES
              Network.send(user, Numeric.ERR_TOOMANYTARGETS(user.nick, u.nick))
              next unless u == nil
            else
              if args[2] != nil
                chan.users.each { |cu| Network.send(cu, ":#{user.nick}!#{user.ident}@#{user.hostname} KICK #{chan.name} #{u.nick} :#{args[2]}") }
              else
                chan.users.each { |cu| Network.send(cu, ":#{user.nick}!#{user.ident}@#{user.hostname} KICK #{chan.name} #{u.nick}") }
              end
              kick_count += 1
              chan.remove_user(u)
              u.remove_channel(chan.name)
              unless chan.users.length > 0 || chan.is_registered?
                Server.remove_channel(chan)
              end
            end
          end
        end
      end
    end
  end
end
Standard::Kick.new
