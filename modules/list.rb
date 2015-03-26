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
  # Lists channels available on the network along with the number of users,
  # current mode(s), and the topic for each channel
  class List
    def initialize
      @command_name = 'list'
      @command_proc = proc { |user, args| on_list(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0..-1] = optional space-separated channels
    def on_list(user, args)
      args = args.join.split
      Network.send(user, Numeric.rpl_liststart(user.nick))
      if args.length >= 1
        chan = nil
        args.each do |a|
          chan = Server.channel_map[a.to_s.upcase]
          next if chan.nil?
          if chan.modes.include?('s') && user.on_channel?(chan.name) == false # do not list secret channels unless user is a member
            next unless chan.nil?
          elsif user.admin
            Network.send(user, Numeric.rpl_list(user.nick, chan, true))
          else
            numeric_output = Numeric.rpl_list(user.nick, chan, false) # need to check for nils before sending
            Network.send(user, numeric_output) unless numeric_output.nil?
          end
        end
      else
        Server.channel_map.values.each do |c|
          if c.modes.include?('s') && user.on_channel?(c.name) == false # do not list secret channels unless user is a member
            next unless c.nil?
          elsif user.admin
            Network.send(user, Numeric.rpl_list(user.nick, c, true))
          else
            numeric_output = Numeric.rpl_list(user.nick, c, false) # need to check for nils before sending
            Network.send(user, numeric_output) unless numeric_output.nil?
          end
        end
      end
      Network.send(user, Numeric.rpl_listend(user.nick))
    end
  end
end
Standard::List.new
