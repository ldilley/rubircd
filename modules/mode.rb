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
  # Displays the modes set on the specified channel, displays the umodes set
  # on yourself, sets the modes for the channel, or sets the umodes for yourself
  class Mode
    def initialize
      @command_name = 'mode'
      @command_proc = proc { |user, args| on_mode(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = target channel or nick
    # args[1] = mode(s)
    # args[2..-1] = nick, ban mask, limit, and/or key
    def on_mode(user, args)
      # TODO: Check if user has chanop, founder, or admin privs before setting channel modes (not implemented for testing purposes at the moment)
      #       Also allow more than one 'b' and/or 'o' mode at once up to Limits::MODES (6) and limit the rest
      #       Add flag prefixes somewhere upon setting the appropriate modes or channel modes for each user
      #       Handle ban additional and removal
      args = args.join.split
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'MODE'))
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
      modes_to_add = ''
      modes_to_remove = ''
      was_add = true
      modes.each_char do |char|
        if char == '+'
          was_add = true
          next unless char.nil?
        end
        if char == '-'
          was_add = false
          next unless char.nil?
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
      final_add_modes = ''
      final_remove_modes = ''
      channel = Server.channel_map[target.to_s.upcase]
      if !channel.nil?
        if args.length == 1
          if channel.limit.nil? && channel.key.nil?
            Network.send(user, Numeric.rpl_channelmodeis(user.nick, channel.name, channel.modes.join(''), nil, ''))
          elsif !channel.limit.nil? && channel.key.nil?
            Network.send(user, Numeric.rpl_channelmodeis(user.nick, channel.name, channel.modes.join(''), channel.limit, ''))
          elsif channel.limit.nil? && !channel.key.nil?
            Network.send(user, Numeric.rpl_channelmodeis(user.nick, channel.name, channel.modes.join(''), nil, channel.key))
          else
            Network.send(user, Numeric.rpl_channelmodeis(user.nick, channel.name, channel.modes.join(''), channel.limit, channel.key))
          end
          Network.send(user, Numeric.rpl_creationtime(user.nick, channel))
          return
        end
        return if modes_to_add.length == 0 && modes_to_remove.length == 0
        if modes_to_add.length == 1 && modes_to_add == 'b'
          channel.bans.each { |ban| Network.send(user, Numeric.rpl_banlist(user.nick, channel.name, ban.creator, ban.create_timestamp)) }
          Network.send(user, Numeric.rpl_endofbanlist(user.nick, channel.name))
          return
        end
        unless user.on_channel?(channel.name)
          Network.send(user, Numeric.err_notonchannel(user.nick, target))
          return
        end
        unless user.chanop?(channel.name) || user.admin
          Network.send(user, Numeric.err_chanoprivsneeded(user.nick, channel.name))
          return
        end
        unless modes_to_add.nil?
          modes_to_add.each_char do |mode|
            if Channel::CHANNEL_MODES.include?(mode)
              # Allow resetting of channel key or send numeric 467 (ERR_KEYSET)?
              if mode == 'k' || mode == 'l'
                final_add_modes << mode
              elsif !channel.modes.include?(mode)
                final_add_modes << mode
              end
            else
              Network.send(user, Numeric.err_unknownmode(user.nick, mode))
            end
          end
        end
        unless modes_to_remove.nil?
          modes_to_remove.each_char do |mode|
            if Channel::CHANNEL_MODES.include?(mode)
              if mode == 'h' || mode == 'o' || mode == 'v'
                final_remove_modes << mode
              elsif channel.modes.include?(mode)
                final_remove_modes << mode
              end
            else
              Network.send(user, Numeric.err_unknownmode(user.nick, mode))
            end
          end
        end
        unless final_add_modes.length == 0
          # Remove modes that are given when no arguments to them are provided
          modelist = ''
          final_add_modes.each_char do |mode|
            if args[2].nil? && mode =~ /[abfhlkov]/
              final_add_modes.delete(mode)
              next unless mode.nil?
            end
            if modelist.include?(mode) && mode =~ /[filkmnprst]/
              final_add_modes.delete(mode)
              next unless mode.nil?
            end
            modelist << mode
          end
          # Match up modes that take arguments with their corresponding argument
          if args.length >= 3
            was_deleted = false
            mode_index = 0
            modelist.each_char do |mode|
              # TODO: Handle if mode == 'b' and ban mask in regex
              if mode == 'k'
                if mode_args[arg_index] =~ /[[:punct:]A-Za-z0-9]/
                  channel.remove_mode(mode) if channel.modes.include?(mode)
                  channel.key = mode_args[arg_index]
                else
                  # Invalid key provided
                  modelist = modelist.delete(mode)
                  mode_args.delete_at(arg_index)
                  was_deleted = true
                  channel.key = nil unless channel.key.nil?
                end
                arg_index += 1 unless arg_index >= mode_args.length
              elsif mode == 'l'
                if mode_args[arg_index] =~ /\d/ && mode_args[arg_index].to_i >= 0
                  channel.remove_mode(mode) if channel.modes.include?(mode)
                  channel.limit = mode_args[arg_index]
                else
                  # Invalid limit provided (not an integer)
                  modelist = modelist.delete(mode)
                  mode_args.delete_at(arg_index)
                  was_deleted = true
                  channel.limit = nil unless channel.limit.nil?
                end
                arg_index += 1 unless arg_index >= mode_args.length
              elsif mode == 'a' || mode == 'f' || mode == 'r' # TODO: Allow servers and services to set these later
                Network.send(user, Numeric.err_noprivileges(user.nick))
                modelist = modelist.delete(mode)
              elsif mode == 'o'
                nick_exists = false
                channel.users.each do |u|
                  next unless !mode_args[arg_index].nil? && u.nick.casecmp(mode_args[arg_index]) == 0
                  # Make nick argument match actual nickname if the case differs
                  mode_args[arg_index] = u.nick
                  nick_exists = true
                  if u.chanop?(channel.name)
                    modelist = modelist.split
                    modelist = modelist.delete_at(mode_index)
                    mode_args.delete_at(arg_index)
                    was_deleted = true
                  elsif mode_targets >= Limits::MODES
                    Network.send(user, Numeric.err_toomanytargets(user.nick, u.nick))
                    modelist = modelist.delete(mode)
                    mode_args.delete_at(arg_index)
                    was_deleted = true
                  else
                    u.add_channel_mode(channel.name, 'o')
                    mode_targets += 1 # only ban/unban, kick, and op/deop have limits
                  end
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.err_nosuchnick(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                  was_deleted = true
                end
                arg_index += 1 if arg_index < mode_args.length && was_deleted == false
              elsif mode == 'h'
                nick_exists = false
                channel.users.each do |u|
                  nick_exists = true
                  next unless !mode_args[arg_index].nil? && u.nick.casecmp(mode_args[arg_index]) == 0
                  mode_args[arg_index] = u.nick
                  if u.halfop?(channel.name)
                    mode_args.delete_at(arg_index)
                    was_deleted = true
                    arg_index += 1 unless arg_index >= mode_args.length
                    next unless u.nil?
                  end
                  u.add_channel_mode(channel.name, 'h')
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.err_nosuchnick(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                arg_index += 1 unless arg_index >= mode_args.length
              elsif mode == 'v'
                nick_exists = false
                channel.users.each do |u|
                  nick_exists = true
                  next unless !mode_args[arg_index].nil? && u.nick.casecmp(mode_args[arg_index]) == 0
                  mode_args[arg_index] = u.nick
                  if u.voiced?(channel.name)
                    mode_args.delete_at(arg_index)
                    was_deleted = true
                    arg_index += 1 unless arg_index >= mode_args.length
                    next unless u.nil?
                  end
                  u.add_channel_mode(channel.name, 'v')
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.err_nosuchnick(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                arg_index += 1 unless arg_index >= mode_args.length
              end
            end
          end
          final_add_modes = modelist
          unless final_add_modes.nil?
            final_add_modes.each_char do |mode|
              channel.add_mode(mode) unless mode =~ /[abfhov]/
            end
          end
        end
        unless final_remove_modes.length == 0
          modelist = ''
          final_remove_modes.each_char do |mode|
            if args[2].nil? && mode =~ /[abfhlkov]/
              final_remove_modes.delete(mode)
              next unless mode.nil?
            end
            if modelist.include?(mode) && mode =~ /[filkmnprst]/
              final_remove_modes.delete(mode)
              next unless mode.nil?
            end
            modelist << mode
          end
          if args.length >= 3
            modelist.each_char do |mode|
              if mode == 'o'
                nick_exists = false
                channel.users.each do |u|
                  next unless !mode_args[arg_index].nil? && u.nick.casecmp(mode_args[arg_index]) == 0
                  mode_args[arg_index] = u.nick
                  nick_exists = true
                  if mode_targets >= Limits::MODES
                    Network.send(user, Numeric.err_toomanytargets(user.nick, u.nick))
                    mode_args.delete_at(arg_index)
                    arg_index += 1 unless arg_index >= mode_args.length
                    next unless u.nil?
                  end
                  u.remove_channel_mode(channel.name, 'o')
                  mode_targets += 1 # only ban/unban, kick, and op/deop have limits
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.err_nosuchnick(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                arg_index += 1 unless arg_index >= mode_args.length
              elsif mode == 'h'
                nick_exists = false
                channel.users.each do |u|
                  next unless !mode_args[arg_index].nil? && u.nick.casecmp(mode_args[arg_index]) == 0
                  mode_args[arg_index] = u.nick
                  u.remove_channel_mode(channel.name, 'h')
                  nick_exists = true
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.err_nosuchnick(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                arg_index += 1 unless arg_index >= mode_args.length
              elsif mode == 'v'
                nick_exists = false
                channel.users.each do |u|
                  next unless !mode_args[arg_index].nil? && u.nick.casecmp(mode_args[arg_index]) == 0
                  mode_args[arg_index] = u.nick
                  u.remove_channel_mode(channel.name, 'v')
                  nick_exists = true
                end
                unless nick_exists
                  modelist = modelist.delete(mode)
                  Network.send(user, Numeric.err_nosuchnick(user.nick, mode_args[arg_index]))
                  mode_args.delete_at(arg_index)
                end
                arg_index += 1 unless arg_index >= mode_args.length
              end
            end
          end
          final_remove_modes = modelist
          final_remove_modes.each_char do |mode|
            next if mode =~ /[abfhov]/
            channel.key = nil if mode == 'k'
            channel.limit = nil if mode == 'l'
            channel.remove_mode(mode)
          end
        end
        channel.users.each do |u|
          # FIXME: Check if final_add/remove_modes is nil
          if final_add_modes.length == 0 && final_remove_modes.length == 0
            return
          elsif final_add_modes.length > 0 && final_remove_modes.length > 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} +#{final_add_modes}-#{final_remove_modes} #{mode_args.join(' ')}")
          elsif final_add_modes.length > 0 && final_remove_modes.length == 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} +#{final_add_modes} #{mode_args.join(' ')}")
          elsif final_add_modes.length == 0 && final_remove_modes.length > 0
            Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} MODE #{channel.name} -#{final_remove_modes} #{mode_args.join(' ')}")
          end
        end
      else
        Network.send(user, Numeric.err_nosuchchannel(user.nick, target))
        return
      end
    end

    def handle_nick_modes(user, args, modes_to_add, modes_to_remove, _mode_args)
      final_add_modes = ''
      final_remove_modes = ''
      if args[0] == user.nick && args[1].nil?
        Network.send(user, Numeric.rpl_umodeis(user.nick, user.umodes.join('')))
        return
      end
      if args[0] == user.nick && !args[1].nil?
        unless modes_to_add.nil?
          modes_to_add.each_char do |mode|
            if Server::USER_MODES.include?(mode)
              final_add_modes << mode unless user.umodes.include?(mode)
            else
              Network.send(user, Numeric.err_unknownmode(user.nick, mode))
            end
          end
        end
        unless modes_to_remove.nil?
          modes_to_remove.each_char do |mode|
            if Server::USER_MODES.include?(mode)
              final_remove_modes << mode if user.umodes.include?(mode)
            else
              Network.send(user, Numeric.err_unknownmode(user.nick, mode))
            end
          end
        end
        # Remove duplicate + umodes
        unless final_add_modes.length == 0
          modelist = ''
          final_add_modes.each_char do |mode|
            modelist << mode unless modelist.include?(mode)
            if modelist =~ /[#{Server::USER_MODES}]/
              final_add_modes.delete(mode)
            end
          end
          if modelist.include?('a')
            modelist = modelist.delete('a')
            Network.send(user, Numeric.err_noprivileges(user.nick))
          end
          if modelist.include?('o')
            modelist = modelist.delete('o')
            Network.send(user, Numeric.err_noprivileges(user.nick))
          end
          if modelist.include?('v') && !user.umodes.include?('a')
            modelist = modelist.delete('v')
            Network.send(user, Numeric.err_noprivileges(user.nick))
          end
          user.virtual_hostname = Options.cloak_host if modelist.include?('x')
          final_add_modes = modelist
          final_add_modes.each_char { |mode| user.add_umode(mode) }
        end
        # Remove duplicate - umodes
        unless final_remove_modes.length == 0
          modelist = ''
          final_remove_modes.each_char do |mode|
            modelist << mode unless modelist.include?(mode)
            if modelist =~ /[#{Server::USER_MODES}]/
              final_remove_modes.delete(mode)
            end
          end
          user.virtual_hostname = nil if modelist.include?('x')
          final_remove_modes = modelist
          final_remove_modes.each_char do |mode|
            user.remove_umode(mode)
          end
        end
        # FIXME: Check if final_add/remove_modes is nil
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
      return unless args[0] != user.nick
      Server.users.each do |u|
        if u.nick.casecmp(args[0]) == 0 && args[1].nil?
          Network.send(user, Numeric.err_usersdontmatch1(user.nick))
        elsif u.nick.casecmp(args[0]) == 0 && !args[1].nil?
          Network.send(user, Numeric.err_usersdontmatch2(user.nick))
        end
      end
      Network.send(user, Numeric.err_nosuchnick(user.nick, args[0]))
    end
  end
end
Standard::Mode.new
