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

require 'options'

module Standard
  # Returns the history for a given nick
  class Whowas
    def initialize
      @whowas_data = []
      @whowas_data_lock = Mutex.new if Options.io_type.to_s == 'thread'
      @command_name = 'whowas'
      @command_proc = proc { |user, args| on_whowas(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
      Server.init_whowas
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = nick
    def on_whowas(user, args)
      args = args.join.split
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, 'WHOWAS'))
        return
      end
      nick_found = false
      @whowas_data.each do |entry|
        next unless entry.nick.casecmp(args[0]) == 0
        Network.send(user, Numeric.RPL_WHOWASUSER(user.nick, entry))
        Network.send(user, Numeric.RPL_WHOISSERVER(user.nick, entry, false))
        nick_found = true
      end
      unless nick_found
        Network.send(user, Numeric.ERR_WASNOSUCHNICK(user.nick, args[0]))
      end
      Network.send(user, Numeric.RPL_ENDOFWHOWAS(user.nick))
    end

    def add_entry(user, signoff_time)
      entry = Entry.new(user.nick, user.ident, user.hostname, user.gecos, user.server, signoff_time)
      # Purge older entries below to stop this data from growing out of control
      if @whowas_data.length >= Limits::WHOWASMAX
        nick_count = 0
        first_occurrence = 0
        first_occurrence_set = false
        @whowas_data.each_with_index do |ent, idx|
          next unless ent.nick.casecmp(user.nick) == 0
          nick_count += 1
          unless first_occurrence_set
            first_occurrence = idx
            first_occurrence_set = true
          end
          next unless nick_count >= Limits::WHOWASMAX
          if Options.io_type.to_s == 'thread'
            @whowas_data_lock.synchronize { @whowas_data.delete_at(first_occurrence) }
          else
            @whowas_data.delete_at(first_occurrence)
          end
        end
      end
      if Options.io_type.to_s == 'thread'
        @whowas_data_lock.synchronize { @whowas_data.push(entry) }
      else
        @whowas_data << entry
      end
    end
  end

  # Represents a historical record for a nick
  class Entry
    def initialize(nick, ident, hostname, gecos, server, signoff_time)
      @nick = nick
      @ident = ident
      @hostname = hostname
      @gecos = gecos
      @server = server
      @signoff_time = signoff_time
    end

    attr_reader :nick, :ident, :hostname, :gecos, :server, :signoff_time
  end
end
Standard::Whowas.new
