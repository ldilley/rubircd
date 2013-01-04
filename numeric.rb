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

require_relative 'channel'
require_relative 'config'
require_relative 'limits'
require_relative 'server'

class Numeric
  # Do not be alarmed by gaps between numeric IDs. Some are reserved, many are unused,
  # and others are defined in separate classes.
  RPL_WELCOME = "Welcome to the #{Config.network_name} IRC Network, [ToDo: populate nick here with sprintf or handle in a method]!" # 001
  RPL_YOURHOST = "Your host is #{Config.server_name}, running version #{Server.VERSION}                       # 002
  RPL_CREATED = "This server was created on #{Server.start_timestamp}"                                        # 003
  RPL_MYINFO = "#{Config.server_name} #{Server.VERSION} #{Server.USER_MODES} #{Channel.CHANNEL_MODES}"        # 004
  # Need to break ISUPPORT up to possibly avoid hitting the message length ceiling
  RPL_ISUPPORT1 = "AWAYLEN=#{Limits.AWAYLEN} CASEMAPPING=rfc1459 CHANMODES=#{Channel.ISUPPORT_CHANNEL_MODES} KICKLEN=#{Limits.KICKLEN} MAXBANS=#{Limits.MAXBANS}" + # 005
                 "MAXCHANNELS=#{Limits.MAXCHANNELS} :are supported by this server"
  RPL_ISUPPORT2 = "MODES=#{Limits.MODES} NETWORK=#{Config.network_name} NICKLEN=#{Limits.NICKLEN} PREFIX=#{Channel.ISUPPORT_PREFIX} TOPICLEN=#{Limits.TOPICLEN}" +  # 005
                  " :are supported by this server"
  RPL_UMODEIS = "" # 221 -- handle in Command class later
  RPL_ADMINME = "Administrative info about #{Config.server_name}:"           # 256
  RPL_ADMINLOC1 = "Name:     #{Config.admin_name}"                           # 257
  RPL_ADMINLOC2 = "Nickname: #{Config.admin_nick}"                           # 258
  RPL_ADMINEMAIL = "E-mail:   #{Config.admin_email}"                         # 259
  RPL_UNAWAY = "You are no longer marked as being away"                      # 305
  RPL_NOWAWAY = "You have been marked as being away"                         # 306
  RPL_CHANNELMODEIS = ""  # 324 -- handle in Command class later
  RPL_CHANNELCREATED = "" # 329 -- handle in Command class later
  RPL_NOTOPIC = "No topic is set."                                           # 331
  RPL_TOPIC = "" # 332 -- handle in Command class later
  RPL_TOPICTIME = "" # 333 -- handle in Command class later
  RPL_INVITING = "" # 341 -- handle in Command class later
  RPL_VERSION = "#{Server.VERSION} #{Config.server_name} :#{Server.RELEASE}" # 351
  RPL_NAMREPLY = "" # 353 -- handle in Command class later
  RPL_ENDOFNAMES = "End of names list."                                      # 366
  RPL_INFO = "#{Server.VERSION}\nhttp://www.devux.org/projects/jrirc/"       # 371
  RPL_ENDOFINFO = "End of info list."                                        # 374
  RPL_MOTDSTART = "Message of the day:"                                      # 375
  RPL_ENDOFMOTD = "End of MOTD"                                              # 376
  RPL_YOUAREOPER = "You are now an IRC Operator"                             # 381
  RPL_REHASHING = "Rehashing"                                                # 382
  RPL_TIME = "#{Time.now.asctime}"                                           # 391
  ERR_NOSUCHNICK = "No such nick"                                            # 401
  ERR_NOSUCHSERVER = "No such server"                                        # 402
  ERR_NOSUCHCHANNEL = "No such channel"                                      # 403
  ERR_CANNOTSENDTOCHAN = "Cannot send to channel"                            # 404
  ERR_TOOMANYCHANNELS = "You have joined too many channels"                  # 405
  ERR_UNKNOWNCOMMAND = "Unknown command"                                     # 421
  ERR_NOMOTD = "MOTD file is missing"                                        # 422
  ERR_USERNOTINCHANNEL = "They aren't on that channel"                       # 441
  ERR_NOTONCHANNEL = "You're not on that channel"                            # 442
  ERR_USERONCHANNEL = "is already on channel"                                # 443
  ERR_NOTREGISTERED = "Register first."                                      # 451
  ERR_NEEDMOREPARAMS = "Not enough parameters"                               # 461
  ERR_ALREADYREGISTERED = "You may not reregister"                           # 462
  ERR_CHANNELISFULL = "Cannot join channel (+l)"                             # 471
  ERR_INVITEONLYCHAN = "Cannot join channel (+i)"                            # 473
  ERR_BANNEDFROMCHAN = "Cannot join channel (+b)"                            # 474
  ERR_BADCHANNELKEY = "Cannot join channel (+k)"                             # 475
  ERR_NOPRIVILEGES = "Permission Denied- You're not an IRC operator"         # 481
  ERR_CHANOPRIVSNEEDED = "You're not channel operator"                       # 482
end
