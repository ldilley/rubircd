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
  # Joins a channel or group of channels if a comma-separated list of channels is provided
  # An optional key or comma-separated keys can also be provided for keyed (+k) channels
  class Join
    def initialize
      @command_name = 'join'
      @command_proc = proc { |user, args| on_join(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = channel or comma-separated channels
    # args[1] = optional key or comma-separated keys
    def on_join(user, args)
      args = args.join.split(' ', 2)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, 'JOIN'))
        return
      end
      channels = args[0].split(',')
      keys = args[1].split(',') if args.length == 2
      key_index = 0
      user_on_channel = false
      channels.each do |channel|
        user_on_channel = user.is_on_channel?(channel)
        if user_on_channel
          Network.send(user, Numeric.ERR_USERONCHANNEL(user.nick, user.nick, channel))
          key_index += 1 if !keys.nil? && keys.length > key_index
          next unless channel.nil?
        end
        if user.get_channels_length >= Limits::MAXCHANNELS
          Network.send(user, Numeric.ERR_TOOMANYCHANNELS(user.nick, channel))
          key_index += 1 if !keys.nil? && keys.length > key_index
          next unless channel.nil?
        end
        unless Channel.is_valid_channel_name?(channel)
          Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
          key_index += 1 if !keys.nil? && keys.length > key_index
          next unless channel.nil?
        end
        chan = Server.channel_map[channel.to_s.upcase]
        channel_existed = true
        channel_existed = false if chan.nil?
        unless chan.nil?
          # TODO: Check for bans against user here
          if chan.modes.include?('l') && chan.users.length >= chan.limit.to_i && !user.is_admin?
            Network.send(user, Numeric.ERR_CHANNELISFULL(user.nick, channel))
            key_index += 1 if !keys.nil? && keys.length > key_index
            next unless channel.nil?
          end
          if chan.modes.include?('k') && !user.is_admin?
            if keys.nil? || keys[key_index] != chan.key
              Network.send(user, Numeric.ERR_BADCHANNELKEY(user.nick, channel))
              key_index += 1 if !keys.nil? && keys.length > key_index
              next unless channel.nil?
            end
          end
          if chan.modes.include?('i') && !user.invites.any? { |channel_invite| channel_invite.casecmp(channel) == 0 } && !user.is_admin?
            Network.send(user, Numeric.ERR_INVITEONLYCHAN(user.nick, channel))
            key_index += 1 if !keys.nil? && keys.length > key_index
            next unless channel.nil?
          end
        end
        if chan.nil?
          channel_object = Channel.new(channel, user.nick)
          Server.add_channel(channel_object)
          chan = Server.channel_map[channel.to_s.upcase]
          user.add_channel(channel)
          user.add_channel_mode(channel, 'o')
        else
          user.add_channel(channel)
        end
        user.add_channel_mode(channel, 'a') if user.is_admin?
        user.add_channel_mode(channel, 'z') if user.is_operator?
        chan.add_user(user)
        if user.invites.length > 0
          user.invites.each do |channel_invite|
            if channel_invite.casecmp(channel) == 0
              user.remove_invite(channel_invite)
            end
          end
        end
        chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} JOIN :#{channel}") }
        # There is only one non-invisible user in the channel, so give them chanop
        if chan.users.length - chan.invisible_users.length == 1
          user.add_channel_mode(channel, 'o')
          # Hack to update user list to make new user appear as a chanop for the invisible admins
          chan.invisible_users.each { |iu| Network.send(iu, ":#{Options.server_name} MODE #{channel} +o #{user.nick}") }
        end
        unless channel_existed
          # TODO: Make user chanop if they are the first user on the channel and channel is not +r
          Network.send(user, ":#{Options.server_name} MODE #{channel} +nt")
        end
        if channel_existed && chan.users.length - chan.invisible_users.length == 1
          # There is only one non-invisible user in the channel, so reset default modes to make them think the channel is being created
          Network.send(user, ":#{Options.server_name} MODE #{channel} +nt")
        end
        names_cmd = Command.command_map['NAMES']
        names_cmd.call(user, channel.split) unless names_cmd.nil?
        key_index += 1 if !keys.nil? && keys.length > key_index
      end
    end
  end
end
Standard::Join.new
