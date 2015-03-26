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
  # Forces a given nick to join a given channel
  # This command is limited to administrators and services
  class Fjoin
    def initialize
      @command_name = 'fjoin'
      @command_proc = proc { |user, args| on_fjoin(user, args) }
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
    def on_fjoin(user, args)
      args = args.join.split(' ', 2)
      unless user == Options.server_name || user.admin
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 2 && user != Options.server_name
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'FJOIN'))
        return
      end
      if user != Options.server_name && !Channel.valid_channel_name?(args[1])
        Network.send(user, Numeric.err_nosuchchannel(user.nick, args[1]))
        return
      end
      target_user = Server.get_user_by_nick(args[0])
      if target_user.nil? && user != Options.server_name
        Network.send(user, Numeric.err_nosuchnick(user.nick, args[0]))
        return
      end
      if user != Options.server_name && target_user.on_channel?(args[1])
        Network.send(user, Numeric.err_useronchannel(user.nick, target_user.nick, args[1]))
        return
      end
      if user != Options.server_name && target_user.channels_length >= Limits::MAXCHANNELS
        Network.send(user, Numeric.err_toomanychannels(user.nick, args[1]))
        return
      end
      channel_existed = false
      chan = Server.channel_map[args[1].to_s.upcase]
      if chan.nil?
        channel_object = Channel.new(args[1], target_user.nick)
        Server.add_channel(channel_object)
        chan = Server.channel_map[args[1].to_s.upcase]
        target_user.add_channel(args[1])
        target_user.add_channel_mode(args[1], 'o')
      else
        channel_existed = true
        target_user.add_channel(args[1])
      end
      chan.add_user(target_user)
      chan.users.each { |u| Network.send(u, ":#{target_user.nick}!#{target_user.ident}@#{target_user.hostname} JOIN :#{args[1]}") }
      unless channel_existed
        # TODO: Make user chanop if they are the first user on the channel and channel is not +r
        Network.send(target_user, ":#{Options.server_name} MODE #{args[1]} +nt")
      end
      names_cmd = Command.command_map['NAMES']
      names_cmd.call(target_user, args[1]) unless names_cmd.nil?
      return if user == Options.server_name
      Server.users.each do |u|
        if u.admin || u.operator
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued FJOIN for #{args[0]} joining to: #{args[1]}")
        end
      end
      Log.write(2, "FJOIN issued by #{user.nick}!#{user.ident}@#{user.hostname} for #{target_user.nick}!#{target_user.ident}@#{target_user.hostname} joining to: #{args[1]}")
    end
  end
end
Optional::Fjoin.new
