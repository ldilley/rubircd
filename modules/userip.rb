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
  # Returns the IP address of a specified nick or IP addresses for a group of
  # space-separated nicks
  # This command is limited to operators and administrators
  class Userip
    def initialize
      @command_name = 'userip'
      @command_proc = proc { |user, args| on_userip(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0..-1] = nick or space-separated nicks
    def on_userip(user, args)
      # Unlike USERHOST, USERIP exposes the actual IP address of the user. As a
      # result, it requires elevated privileges in case host cloaking is enabled.
      unless user.operator || user.admin || user.service
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'USERIP'))
        return
      end
      args = args.join.split
      userip_list = []
      args.each do |a|
        break if userip_list.length >= Limits::MAXTARGETS
        Server.users.each do |u|
          next unless u.nick.casecmp(a) == 0
          if u.admin || u.operator
            userip_list << "#{u.nick}*=+#{u.ident}@#{u.ip_address}"
          else
            userip_list << "#{u.nick}=+#{u.ident}@#{u.ip_address}"
          end
        end
      end
      Network.send(user, Numeric.rpl_userhost(user.nick, userip_list))
    end
  end
end
Optional::Userip.new
