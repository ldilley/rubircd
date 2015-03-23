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
  # Allows users to become IRC operators or administrators by specifying the
  # appropriate nick and corresponding password
  class Oper
    def initialize
      @command_name = 'oper'
      @command_proc = proc { |user, args| on_oper(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = nick
    # args[1] = password
    def on_oper(user, args)
      args = args.join.split(' ', 2)
      if args.length < 2
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'OPER'))
        return
      end
      admin_nick = nil
      oper_nick = nil
      Server.admins.each { |admin| admin_nick = admin.nick if admin.nick.casecmp(args[0]) == 0 }
      Server.opers.each { |oper| oper_nick = oper.nick if oper.nick.casecmp(args[0]) == 0 }
      if admin_nick.nil? && oper_nick.nil?
        Network.send(user, Numeric.err_nooperhost(user.nick))
        return
      end
      hash = Digest::SHA2.new(256) << args[1].strip
      unless admin_nick.nil?
        Server.admins.each do |admin|
          if admin.nick == admin_nick && admin.hash == hash.to_s
            if admin.host.nil? || admin.host == '' || admin.host == '*'
              user.set_admin
              Network.send(user, Numeric.rpl_youareoper(user))
              Server.users.each do |u|
                if u.is_admin? || u.is_operator?
                  Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is now an IRC Server Administrator.")
                end
              end
              Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} is now an IRC Server Administrator.")
              update_channel_prefix(user, 'a')
              return
            end
            hostmask = admin.host.to_s.gsub('\*', '.*?')
            regx = Regexp.new("^#{hostmask}$", Regexp::IGNORECASE)
            if user.hostname =~ regx
              user.set_admin
              Network.send(user, Numeric.rpl_youareoper(user.nick))
              Server.users.each do |u|
                if u.is_admin? || u.is_operator?
                  Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is now an IRC Server Administrator.")
                end
              end
              Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} is now an IRC Server Administrator.")
              update_channel_prefix(user, 'a')
              return
            else
              Server.users.each do |u|
                if u.is_admin? || u.is_operator?
                  Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} failed an OPER attempt: Host mismatch")
                end
              end
              Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} failed an OPER attempt: Host mismatch")
              Network.send(user, Numeric.err_nooperhost(user.nick))
              return
            end
          else
            Server.users.each do |u|
              if u.is_admin? || u.is_operator?
                Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} failed an OPER attempt: Password mismatch")
              end
            end
            Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} failed an OPER attempt: Password mismatch")
            Network.send(user, Numeric.err_nooperhost(user.nick))
            return
          end
        end
      end
      return if oper_nick.nil?
      Server.opers.each do |oper|
        if oper.nick == oper_nick && oper.hash == hash.to_s
          if oper.host.nil? || oper.host == '' || oper.host == '*'
            user.set_operator
            Network.send(user, Numeric.rpl_youareoper(user))
            Server.users.each do |u|
              if u.is_admin? || u.is_operator?
                Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is now an IRC Operator.")
              end
            end
            Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} is now an IRC Operator.")
            update_channel_prefix(user, 'z')
            return
          end
          hostmask = oper.host.to_s.gsub('\*', '.*?')
          regx = Regexp.new("^#{hostmask}$", Regexp::IGNORECASE)
          if user.hostname =~ regx
            user.set_operator
            Network.send(user, Numeric.rpl_youareoper(user.nick))
            Server.users.each do |u|
              if u.is_admin? || u.is_operator?
                Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is now an IRC Operator.")
              end
            end
            Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} is now an IRC Operator.")
            update_channel_prefix(user, 'z')
            return
          else
            Server.users.each do |u|
              if u.is_admin? || u.is_operator?
                Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} failed an OPER attempt: Host mismatch")
              end
            end
            Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} failed an OPER attempt: Host mismatch")
            Network.send(user, Numeric.err_nooperhost(user.nick))
            return
          end
        else
          Server.users.each do |u|
            if u.is_admin? || u.is_operator?
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} failed an OPER attempt: Password mismatch")
            end
          end
          Log.write(1, "#{user.nick}!#{user.ident}@#{user.hostname} failed an OPER attempt: Password mismatch")
          Network.send(user, Numeric.err_nooperhost(user.nick))
        end
      end
    end

    def update_channel_prefix(user, mode)
      # Add oper prefix to each channel the user is in
      user_channels = user.get_channels_array
      user_channels.each do |channel|
        user.add_channel_mode(channel, mode)
        chan = Server.channel_map[channel.to_s.upcase]
        unless chan.nil?
          chan.users.each { |cu| Network.send(cu, ":#{Options.server_name} MODE #{channel} +#{mode} #{user.nick}") }
        end
      end
    end
  end
end
Standard::Oper.new
