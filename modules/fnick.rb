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
  # Forces a nick change to a given new nick
  # This command is limited to administrators and services
  class Fnick
    def initialize
      @command_name = 'fnick'
      @command_proc = proc { |user, args| on_fnick(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = nick
    # args[1] = new nick
    def on_fnick(user, args)
      args = args.join.split(' ', 2)
      unless user.admin
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 2
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'FNICK'))
        return
      end
      if args[1].length < 1 || args[1].length > Limits::NICKLEN
        Network.send(user, Numeric.err_erroneousnickname(user.nick, args[1], 'Nickname does not meet length requirements.'))
        return
      end
      unless args[1] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
        Network.send(user, Numeric.err_erroneousnickname(user.nick, args[1], 'Nickname contains invalid characters.'))
        return
      end
      target_user = Server.get_user_by_nick(args[0])
      if target_user.nil?
        Network.send(user, Numeric.err_nosuchnick(user.nick, args[0]))
        return
      end
      if target_user.nick == args[1]
        Network.send(user, Numeric.err_erroneousnickname(user.nick, args[1], 'Nickname matches new nick.'))
        return
      end
      if Server.nick_exists?(args[1]) && args[0].casecmp(args[1]) != 0
        Network.send(user, Numeric.err_nicknameinuse(user.nick, args[1]))
        return
      end
      unless Server.qline_mod.nil?
        Server.qline_mod.list_qlines.each do |reserved_nick|
          if reserved_nick.target.casecmp(args[1]) == 0
            Network.send(user, Numeric.err_erroneousnickname(user.nick, args[1], reserved_nick.reason))
            return
          end
        end
      end
      if target_user.registered
        if target_user.channels_length > 0
          user_channels = target_user.channels_array
          user_channels.each do |c|
            chan = Server.channel_map[c.to_s.upcase]
            chan.users.each do |u|
              if target_user.nick != u.nick && u.nick.casecmp(args[1]) != 0
                Network.send(u, ":#{target_user.nick}!#{target_user.ident}@#{target_user.hostname} NICK :#{args[1]}")
              end
            end
          end
        end
        Network.send(target_user, ":#{target_user.nick}!#{target_user.ident}@#{target_user.hostname} NICK :#{args[1]}")
      end
      whowas_loaded = Command.command_map['WHOWAS']
      Server.whowas_mod.add_entry(target_user, ::Time.now.asctime) unless whowas_loaded.nil?
      target_user.nick = args[1]
      Server.users.each do |u|
        if u.admin || u.operator
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued FNICK for #{args[0]} changing nick to: #{args[1]}")
        end
      end
      Log.write(2, "FNICK issued by #{user.nick}!#{user.ident}@#{user.hostname} for #{target_user.nick}!#{target_user.ident}@#{target_user.hostname} changing nick to: #{args[1]}")
    end
  end
end
Optional::Fnick.new
