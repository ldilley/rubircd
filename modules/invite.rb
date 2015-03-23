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
  # Sends an invitation to a target nick for the specified channel and allows
  # the nick to join the channel if it is set to invite only (+i)
  class Invite
    def initialize
      @command_name = 'invite'
      @command_proc = proc { |user, args| on_invite(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = nick
    # args[1] = channel
    def on_invite(user, args)
      args = args.join.split(' ', 2)
      if args.length < 2
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'INVITE'))
        return
      end
      # TODO: Check for chanop status once a place for users' channel modes is figured out and a place to write invites
      target_user = nil
      Server.users.each do |u|
        target_user = u if u.nick.casecmp(args[0]) == 0
      end
      if target_user.nil?
        Network.send(user, Numeric.err_nosuchnick(user.nick, args[0]))
        return
      end
      unless user.is_on_channel?(args[1])
        Network.send(user, Numeric.err_notonchannel(user.nick, args[1]))
        return
      end
      if target_user.is_on_channel?(args[1])
        Network.send(user, Numeric.err_useronchannel(user.nick, args[0], args[1]))
        return
      end
      Network.send(user, Numeric.rpl_inviting(user.nick, args[0], args[1]))
      if target_user.away_message.length > 0
        Network.send(user, Numeric.rpl_away(user.nick, target_user))
      end
      target_user.add_invite(args[1])
      Network.send(target_user, ":#{user.nick}!#{user.ident}@#{user.hostname} INVITE #{args[0]} :#{args[1]}")
      chan = Server.channel_map[args[1].to_s.upcase]
      return if chan.nil?
      # TODO: Only send to chanops?
      chan.users.each { |u| Network.send(u, ":#{Options.server_name} NOTICE @#{args[1]} :#{user.nick} invited #{args[0]} into channel #{args[1]}") }
    end
  end
end
Standard::Invite.new
