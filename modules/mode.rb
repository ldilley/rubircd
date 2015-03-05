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
  class Mode
    def initialize()
      @command_name = "mode"
      @command_proc = Proc.new() { |user, args| on_mode(user, args) }
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

    # args[0] = target channel or nick
    # args[1] = mode(s)
    # args[2..-1] = nick, ban mask, limit, and/or key
    def on_mode(user, args)
      # ToDo: Check if user has chanop, founder, or admin privs before setting channel modes (not implemented for testing purposes at the moment)
      #       Also allow more than one 'b' and/or 'o' mode at once up to Limits::MODES (6) and limit the rest
      #       Add flag prefixes somewhere upon setting the appropriate modes or channel modes for each user
      #       Handle ban additional and removal
      args = args.join.split
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "MODE"))
        return
      end
      target = args[0]
      if args.length >= 2
        modes_to_add, modes_to_remove = get_modes(args[1]) # check what modes are to be added and/or removed
      end
      if args.length >= 3
        mode_args = args[2..-1]                            # this should be the starting ban mask/key/limit/nick
      else
        mode_args = []
      end
      if target[0] == '#' || target[0] == '&'
        handle_channel_modes(user, args, target, modes_to_add, modes_to_remove, mode_args)
        return
      else # target is a nick
        handle_nick_modes(user, args, modes_to_add, modes_to_remove, mode_args)
        return
      end
    end

    def get_modes(modes)
      modes_to_add = ""
      modes_to_remove = ""
      was_add = true
      modes.each_char do |char|
        if char == '+'
          was_add = true
          next unless char == nil
        end
        if char == '-'
          was_add = false
          next unless char == nil
        end
        if was_add
          modes_to_add << char
        else
          modes_to_remove << char
        end
      end
      return modes_to_add, modes_to_remove
    end

    def handle_channel_modes(user, args, target, modes_to_add, modes_to_remove, mode_args)
      arg_index = 0
      mode_targets = 0
      final_add_modes = ""
      final_remove_modes = ""
      channel = Server.channel_map[target.to_s.upcase]
      unless channel == nil
        if args.length == 1
          if channel.limit == nil && channel.key == nil
            Network.send(user, Numeric.RPL_CHANNELMODEIS(user.nick, channel.name, channel.modes.join(""), nil, ""))
          elsif channel.limit != nil && channel.key == nil
            Network.send(user, Numeric.RPL_CHANNELMODEIS(user.nick, channel.name, channel.modes.join(""), channel.limit, ""))
          elsif channel.limit == nil && channel.key != nil
            Network.send(user, Numeric.RPL_CHANNELMODEIS(user.nick, channel.name, channel.modes.join(""), nil, channel.key))
          else
            Network.send(user, Numeric.RPL_CHANNELMODEIS(user.nick, channel.name, channel.modes.join(""), channel.limit, channel.key))
          end
          Network.send(user, Numeric.RPL_CREATIONTIME(user.nick, channel))
          return
        end
        if modes_to_add.length == 0 && modes_to_remove.length == 0
          return
        end
        if modes_to_add.length == 1 && modes_to_add == 'b'
          channel.bans.each { |ban| Network.send(user, Numeric.RPL_BANLIST(user.nick, channel.name, ban.creator, ban.create_timestamp)) }
          Network.send(user, Numeric.RPL_ENDOFBANLIST(user.nick, channel.name))
          return
        end
        user_on_channel = false
        user.channels.each_key do |c|
          if channel.name.casecmp(c) == 0
            user_on_channel = true
          end
        end
        unless user_on_channel
          Network.send(user, Numeric.ERR_NOTONCHANNEL(user.nick, target))
          return
        end
        unless user.is_chanop(channel.name)
          Network.send(user, Numeric.ERR_CHANOPRIVSNEEDED(user.nick, channel.name))
          return
        end
        unless modes_to_add == nil
          modes_to_add.each_char do |mode|
            if Channel::CHANNEL_MODES.include?(mode)
              # Allow resetting of channel key or send numeric 467 (ERR_KEYSET)?
              if mode == 'k' || mode == 'l'
                final_add_modes << mode
              elsif !channel.modes.include?(mode)
                final_add_modes << mode
              end
            else
              Network.send(user, Numeric.ERR_UNKNOWNMODE(user.nick, mode))
            end
          end
        end
        unless modes_to_remove == nil
          modes_to_remove.each_char do |mode|
            if Channel::CHANNEL_MODES.include?(mode)
              if mode == 'o' || mode == 'v'
                final_remove_modes << mode
              elsif channel.modes.include?(mode)
                final_remove_modes << mode
              end
            else
              Network.send(user, Numeric.ERR_UNKNOWNMODE(user.nick, mode))
            end
          end
        end
        unless final_add_modes.length == 0
          # Remove modes that are given when no arguments to them are provided
          modelist = ""
          final_add_modes.each_char do |mode|
            if args[2] == nil && mode =~ /[abflkov]/
              final_add_modes.delete(mode)
              next unless mode == nil
            end
            if modelist.include?(mode) && mode =~ /[filkmnprst]/
              final_add_modes.delete(mode)
              next unless mode == nil
            end
            modelist << mode
          end
          # Match up modes that take arguments with their corresponding argument
          if args.length >= 3
            was_deleted = false
            mode_index = 0
            modelist.each_char do |mode|
              #if mode == 'b'
                # ToDo: Handle ban mask in regex
              if mode == 'k'
                if mode_args[arg_index] =~ /[[:punct:]A-Za-z0-9]/
                  if channel.modes.include?(mode)
                    channel.remove_mode(mode)
                  end
                  channel.set_key(mode_args[arg_index])
                else
                  # Invalid key provided
                  modelist = modelist.delete(mode)
                  mode_args.delete_at(arg_index)
                  was_deleted = true
                  unless channel.key == nil
                    channel.set_key(nil)
                  end
                end
                unless arg_index >= mode_args.length
                  arg_index += 1
                end
              elsif mode == 'l'
                if mode_args[arg_index] =~ /\d/ && mode_args[arg_index].to_i >= 0
                  if channel.modes.include?(mode)
                    channel.remove_mode(mode)
                  end
                  channel.set_limit(mode_args[arg_index])
                else
                  # Invalid limit provided (not an integer)
                  modelist = modelist.delete(mode)
                  mode_args.delete_at(arg_index)
                  was_deleted = true
                  unless channel.limit == nil
                    channel.set_limit(nil)
                  end
                end
                unless arg_index >= mode_args.length
                  arg_index += 1
                end
              elsif mode == 'a' || mode == 'f' || mode == 'r' # ToDo: Allow servers and services to set these later
                Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
                modelist = modelist.delete(mode)
              elsif mode == 'o'
                nick_exists = false
                channel.users.each do |u|
                  if u.nick == mode_args[arg_index]
                    nick_exists = true
                    if u.is_chanop(channel.name)
                      modelist = modelist.split
                      modelist = modelist.delete_at(mode_index)
                      mode_args.delete_at(arg_index)
                      was_deleted = true
                    elsif mode_targets >= Limits::MODES
                      Network.send(user, Numeric.ERR_TOOMANYTARGETS(user.nick, u.nick))
                      modelist = modelist.delete(mode)
                      mode_args.delete_at(arg_index)
                      was_deleted = true
                    else
                      u.add_channel_mode(channel.name, 'o')
                      mode_targets += 1 # only ban/unban, kick, and op/deop have limits
                    end
                  end
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                  was_deleted = true
                end
                if arg_index < mode_args.length && was_deleted == false
                  arg_index += 1
                end
              elsif mode == 'v'
                nick_exists = false
                channel.users.each do |u|
                  nick_exists = true
                  if u.nick == mode_args[arg_index]
                    if u.is_voiced(channel.name)
                      mode_args.delete_at(arg_index)
                      was_deleted = true
                      unless arg_index >= mode_args.length
                        arg_index += 1
                      end
                      next unless u == nil
                    end
                    u.add_channel_mode(channel.name, 'v')
                  end
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                unless arg_index >= mode_args.length
                  arg_index += 1
                end
              end
            end
          end
          final_add_modes = modelist
          unless final_add_modes == nil
            final_add_modes.each_char do |mode|
              unless mode =~ /[abfov]/
                channel.add_mode(mode)
              end
            end
          end
        end
        unless final_remove_modes.length == 0
          modelist = ""
          final_remove_modes.each_char do |mode|
            if args[2] == nil && mode =~ /[abflkov]/
              final_remove_modes.delete(mode)
              next unless mode == nil
            end
            if modelist.include?(mode) && mode =~ /[filkmnprst]/
              final_remove_modes.delete(mode)
              next unless mode == nil
            end
            modelist << mode
          end
          if args.length >= 3
            modelist.each_char do |mode|
              if mode == 'o'
                nick_exists = false
                channel.users.each do |u|
                  if u.nick == mode_args[arg_index]
                    nick_exists = true
                    if mode_targets >= Limits::MODES
                      Network.send(user, Numeric.ERR_TOOMANYTARGETS(user.nick, u.nick))
                      mode_args.delete_at(arg_index)
                      unless arg_index >= mode_args.length
                        arg_index += 1
                      end
                      next unless u == nil
                    end
                    u.remove_channel_mode(channel.name, 'o')
                    mode_targets += 1 # only ban/unban, kick, and op/deop have limits
                  end
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                unless arg_index >= mode_args.length
                  arg_index += 1
                end
              elsif mode == 'v'
                nick_exists = false
                channel.users.each do |u|
                  if u.nick == mode_args[arg_index]
                    u.remove_channel_mode(channel.name, 'v')
                    nick_exists = true
                  end
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                unless arg_index >= mode_args.length
                  arg_index += 1
                end
              end
            end
          end
          final_remove_modes = modelist
          final_remove_modes.each_char do |mode|
            unless mode =~ /[abfov]/
              if mode == 'k'
                channel.set_key(nil)
              end
              if mode == 'l'
                channel.set_limit(nil)
              end
              channel.remove_mode(mode)
            end
          end
        end
        channel.users.each do |u|
          # FixMe: Check if final_add/remove_modes is nil
          if final_add_modes.length == 0 && final_remove_modes.length == 0
            return
          elsif final_add_modes.length > 0 && final_remove_modes.length > 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} +#{final_add_modes}-#{final_remove_modes} #{mode_args.join(" ")}")
          elsif final_add_modes.length > 0 && final_remove_modes.length == 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} +#{final_add_modes} #{mode_args.join(" ")}")
          elsif final_add_modes.length == 0 && final_remove_modes.length > 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} -#{final_remove_modes} #{mode_args.join(" ")}")
          end
        end
      else
        Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, target))
        return
      end
    end

    def handle_nick_modes(user, args, modes_to_add, modes_to_remove, mode_args)
      final_add_modes = ""
      final_remove_modes = ""
      if args[0] == user.nick && args[1] == nil
        Network.send(user, Numeric.RPL_UMODEIS(user.nick, user.umodes.join("")))
        return
      end
      if args[0] == user.nick && args[1] != nil
        unless modes_to_add == nil
          modes_to_add.each_char do |mode|
            if Server::USER_MODES.include?(mode)
              unless user.umodes.include?(mode)
                final_add_modes << mode
              end
            else
              Network.send(user, Numeric.ERR_UNKNOWNMODE(user.nick, mode))
            end
          end
        end
        unless modes_to_remove == nil
          modes_to_remove.each_char do |mode|
            if Server::USER_MODES.include?(mode)
              if user.umodes.include?(mode)
                final_remove_modes << mode
              end
            else
              Network.send(user, Numeric.ERR_UNKNOWNMODE(user.nick, mode))
            end
          end
        end
        # Remove duplicate + umodes
        unless final_add_modes.length == 0
          modelist = ""
          final_add_modes.each_char do |mode|
            unless modelist.include?(mode)
              modelist << mode
            end
            if modelist =~ /[#{Server::USER_MODES}]/
              final_add_modes.delete(mode)
            end
          end
          if modelist.include?('a')
            modelist = modelist.delete('a')
            Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
          end
          if modelist.include?('o')
            modelist = modelist.delete('o')
            Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
          end
          if modelist.include?('v') && !user.umodes.include?('a')
            modelist = modelist.delete('v')
            Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
          end
          final_add_modes = modelist
          final_add_modes.each_char { |mode| user.add_umode(mode) }
        end
        # Remove duplicate - umodes
        unless final_remove_modes.length == 0
          modelist = ""
          final_remove_modes.each_char do |mode|
            unless modelist.include?(mode)
              modelist << mode
            end
            if modelist =~ /[#{Server::USER_MODES}]/
              final_remove_modes.delete(mode)
            end
          end
          final_remove_modes = modelist
          final_remove_modes.each_char do |mode|
            user.remove_umode(mode)
          end
        end
        # FixMe: Check if final_add/remove_modes is nil
        if final_add_modes.length == 0 && final_remove_modes.length == 0
          return
        elsif final_add_modes.length > 0 && final_remove_modes.length > 0
          Network.send(user, ":#{user.nick} MODE #{user.nick} +#{final_add_modes}-#{final_remove_modes}")
        elsif final_add_modes.length > 0 && final_remove_modes.length == 0
          Network.send(user, ":#{user.nick} MODE #{user.nick} +#{final_add_modes}")
        elsif final_add_modes.length == 0 && final_remove_modes.length > 0
          Network.send(user, ":#{user.nick} MODE #{user.nick} -#{final_remove_modes}")
        end
        return
      end
      if args[0] != user.nick
        Server.users.each do |u|
          if u.nick.casecmp(args[0]) == 0 && args[1] == nil
            Network.send(user, Numeric.ERR_USERSDONTMATCH1(user.nick))
          elsif u.nick.casecmp(args[0]) == 0 && args[1] != nil
            Network.send(user, Numeric.ERR_USERSDONTMATCH2(user.nick))
          end
        end
        Network.send(user, Numeric.ERR_NOSUCHNICK(user.nick, args[0]))
      end
    end
  end
end
Standard::Mode.new
