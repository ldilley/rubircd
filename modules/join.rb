# $Id$
# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details) 
# http://www.rubircd.org/
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
  class Join
    def initialize()
      @command_name = "join"
      @command_proc = Proc.new() { |user, args| on_join(user, args) }
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

    # args[0] = channel or comma-separated channels
    # args[1] = optional key or comma-separated keys
    def on_join(user, args)
      args = args.join.split(' ', 2)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "JOIN"))
        return
      end
      channels = args[0].split(',')
      if args.length == 2
        keys = args[1].split(',')
      end
      key_index = 0
      user_on_channel = false
      channels.each do |channel|
        user.channels.each_key do |uc|
          if uc.casecmp(channel) == 0
            user_on_channel = true
          end
        end
        if user_on_channel
          Network.send(user, Numeric.ERR_USERONCHANNEL(user.nick, user.nick, channel))
          unless keys.nil?
            if keys.length > key_index
              key_index += 1
            end
          end
          next unless channel == nil
        end
        if user.channels.length >= Limits::MAXCHANNELS
          Network.send(user, Numeric.ERR_TOOMANYCHANNELS(user.nick, channel))
          unless keys.nil?
            if keys.length > key_index
              key_index += 1
            end
          end
          next unless channel == nil
        end
        unless channel =~ /[#&][A-Za-z0-9_!-]/
          Network.send(user, Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
          unless keys.nil?
            if keys.length > key_index
              key_index += 1
            end
          end
          next unless channel == nil
        end
        chan = Server.channel_map[channel.to_s.upcase]
        channel_existed = true
        if chan == nil
          channel_existed = false
        end
        unless chan == nil
          # ToDo: Check for bans against user here
          if chan.modes.include?('l') && chan.users.length >= chan.limit.to_i && !user.is_admin
            Network.send(user, Numeric.ERR_CHANNELISFULL(user.nick, channel))
            unless keys.nil?
              if keys.length > key_index
                key_index += 1
              end
            end
            next unless channel == nil
          end
          if chan.modes.include?('k') && !user.is_admin
            if keys.nil? || keys[key_index] != chan.key
              Network.send(user, Numeric.ERR_BADCHANNELKEY(user.nick, channel))
              unless keys.nil?
                if keys.length > key_index
                  key_index += 1
                end
              end
              next unless channel == nil
            end
          end
          if chan.modes.include?('i') && !user.invites.any? { |channel_invite| channel_invite.casecmp(channel) == 0 } && !user.is_admin
            Network.send(user, Numeric.ERR_INVITEONLYCHAN(user.nick, channel))
            unless keys.nil?
              if keys.length > key_index
                key_index += 1
              end
            end
            next unless channel == nil
          end
        end
        if chan == nil
          channel_object = Channel.new(channel, user.nick)
          Server.add_channel(channel_object)
          chan = Server.channel_map[channel.to_s.upcase]
          user.add_channel(channel)
          user.add_channel_mode(channel, 'o')
        else
          user.add_channel(channel)
        end
        chan.add_user(user)
        if user.invites.length > 0
          user.invites.each do |channel_invite|
            if channel_invite.casecmp(channel) == 0
              user.remove_invite(channel_invite)
            end
          end
        end
        chan.users.each { |u| Network.send(u, ":#{user.nick}!#{user.ident}@#{user.hostname} JOIN :#{channel}") }
        unless channel_existed
          # ToDo: Make user chanop if they are the first user on the channel and channel is not +r
          Network.send(user, ":#{Options.server_name} MODE #{channel} +nt")
        end
        names_cmd = Command.command_map["NAMES"]
        unless names_cmd == nil
          names_cmd.call(user, channel.split)
        end
        unless keys.nil?
          if keys.length > key_index
            key_index += 1
          end
        end
      end
    end
  end
end
Standard::Join.new
