# $Id$
# jrIRC    
# Copyright (c) 2013 (see authors.txt for details) 
# http://www.devux.org/projects/jrirc/
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
  MAXMSG = 510              # max message length per RFC is 512, but we need 2 bytes to append carriage return and newline
  MODES = 6
  NICKLEN = 32
  TOPICLEN = 308
  IDENTLEN = 10
  GECOSLEN = 150
  REGISTRATION_TIMEOUT = 20 # allow enough time for hostname lookup timeout
end
