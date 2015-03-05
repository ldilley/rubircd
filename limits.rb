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

class Limits
  AWAYLEN = 201
  KICKLEN = 256
  MAXBANS = 50
  MAXCHANNELS = 10
  MAXMSG = 510              # maximum message length per RFC is 512, but we need 2 bytes to append carriage return and newline
  MAXPART = 255
  MAXQUIT = 255
  MAXINVITES = 5
  MAXTARGETS = 6
  MODES = 6
  NICKLEN = 32
  TOPICLEN = 308
  IDENTLEN = 10
  GECOSLEN = 150
  WHOWASMAX = 5             # maximum number of whowas entries for a nick
  MOTDLINELEN = 80
  PING_STRIKES = 3          # number of times a connection can fail to respond to a ping request before it should be dropped
  PING_INTERVAL = 90        # interval to ping all connections in seconds (do not set this value too low!)
  REGISTRATION_TIMEOUT = 20 # seconds a new connection has to register -- be sure to allow enough time for hostname lookups to fail
end
