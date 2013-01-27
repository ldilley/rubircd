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

require_relative 'channel'
require_relative 'limits'
require_relative 'options'
require_relative 'server'

class Numeric
  # Do not be alarmed by gaps between numeric IDs. Some are reserved, many are unused,
  # and others are defined in separate classes.

  # 001
  def self.RPL_WELCOME(nick)
    return sprintf(":%s 001 %s :Welcome to the %s IRC Network, %s!", Options.server_name, nick, Options.network_name, nick)
  end

  # 002
  def self.RPL_YOURHOST(nick)
    return sprintf(":%s 002 %s :Your host is %s, running version %s", Options.server_name, nick, Options.server_name, Server::VERSION)
  end

  # 003
  def self.RPL_CREATED(nick)
    return sprintf(":%s 003 %s :This server was created on %s", Options.server_name, nick, Server.start_timestamp)
  end

  # 004
  def self.RPL_MYINFO(nick)
    return sprintf(":%s 004 %s %s %s %s %s", Options.server_name, nick, Options.server_name, Server::VERSION, Server::USER_MODES, Channel::CHANNEL_MODES)
  end

  # Need to break ISUPPORT up to possibly avoid hitting the message length ceiling
  # 005.1
  def self.RPL_ISUPPORT1(nick, server)
    return sprintf(":%s 005 %s AWAYLEN=%i CASEMAPPING=rfc1459 CHANMODES=%s CHANTYPES=#& CHARSET=ascii KICKLEN=%i MAXBANS=%i MAXCHANNELS=%i :are supported by this server",
                   server, nick, Limits::AWAYLEN, Channel::ISUPPORT_CHANNEL_MODES, Limits::KICKLEN, Limits::MAXBANS, Limits::MAXCHANNELS)
  end
  # 005.2
  def self.RPL_ISUPPORT2(nick, server)
    if Options.ssl_port != nil
      return sprintf(":%s 005 %s MODES=%s NETWORK=%s NICKLEN=%i PREFIX=%s SSL=%s:%i STATUSMSG=%s TOPICLEN=%i :are supported by this server", server, nick,
                     Limits::MODES, Options.network_name, Limits::NICKLEN, Channel::ISUPPORT_PREFIX, Options.server_name, Options.ssl_port, Server::STATUS_PREFIXES,
                     Limits::TOPICLEN)
    else
      return sprintf(":%s 005 %s MODES=%s NETWORK=%s NICKLEN=%i PREFIX=%s STATUSMSG=%s TOPICLEN=%i :are supported by this server", server, nick,
                     Limits::MODES, Options.network_name, Limits::NICKLEN, Channel::ISUPPORT_PREFIX, Server::STATUS_PREFIXES, Limits::TOPICLEN)
    end
  end

  RPL_UMODEIS = "" # 221 -- handle in Command class later

  # 251
  def self.RPL_LUSERCLIENT(nick)
    return sprintf(":%s 251 %s :There are %i users and %i invisible on %i servers", Options.server_name, nick, Server.visible_count, Server.invisible_count, Server.link_count + 1)
  end

  # 252
  def self.RPL_LUSEROP(nick)
    return sprintf(":%s 252 %s %i :IRC Operators online", Options.server_name, nick, Server.oper_count)
  end

  # 253
  # For unregistered connections
  def self.RPL_LUSERUNKNOWN(nick)
    return sprintf(":%s 253 %s %i :unknown connection(s)", Options.server_name, nick, Server.unknown_clients)
  end

  # 254
  def self.RPL_LUSERCHANNELS(nick)
    return sprintf(":%s 254 %s %i :channels formed", Options.server_name, nick, Server.channel_count)
  end

  # 255
  def self.RPL_LUSERME(nick)
    return sprintf(":%s 255 %s :I have %i clients and %i servers", Options.server_name, nick, Server.client_count, Server.link_count + 1)
  end

  # 256
  def self.RPL_ADMINME(nick, server)
    return sprintf(":%s 256 %s :Administrative info for %s:", server, nick, server)
  end

  # 257
  def self.RPL_ADMINLOC1(nick, server)
    return sprintf(":%s 257 %s :Name:     %s", server, nick, Options.admin_name)
  end

  # 258
  def self.RPL_ADMINLOC2(nick, server)
    return sprintf(":%s 258 %s :Nickname: %s", server, nick, Options.admin_nick)
  end

  # 259
  def self.RPL_ADMINEMAIL(nick, server)
    return sprintf(":%s 259 %s :E-mail:   %s", server, nick, Options.admin_email)
  end

  # 265
  def self.RPL_LOCALUSERS(nick)
    return sprintf(":%s 265 %s Current local users: %i Max: %i", Options.server_name, nick, Server.local_users, Server.local_users_max)
  end

  # 266
  def self.RPL_GLOBALUSERS(nick)
    return sprintf(":%s 266 %s Current global users: %i Max: %i", Options.server_name, nick, Server.global_users, Server.global_users_max)
  end

  # 301
  def self.RPL_AWAY(nick, user)
    return sprintf(":%s 301 %s %s :%s", Options.server_name, nick, user.nick, user.away_message)
  end

  RPL_UNAWAY = "You are no longer marked as being away"                               # 305
  RPL_NOWAWAY = "You have been marked as being away"                                  # 306

  # 307
  def self.RPL_WHOISREGNICK(nick, user)
    return sprintf(":%s 307 %s %s is a registered nick", Options.server_name, nick, user.nick)
  end

  # 308
  # ToDo: Add server name in reply?
  def self.RPL_WHOISADMIN(nick, user)
    return sprintf(":%s 308 %s %s is an IRC Server Administrator", Options.server_name, nick, user.nick)
  end

  RPL_WHOISSERVICE = "is a Network Service"                                           # 310

  # 311
  def self.RPL_WHOISUSER(nick, user)
    return sprintf(":%s 311 %s %s %s %s * :%s", Options.server_name, nick, user.nick, user.ident, user.hostname, user.gecos)
  end

  # 313
  def self.RPL_WHOISOPERATOR(nick, user)
    return sprintf(":%s 313 %s %s is an IRC Operator", Options.server_name, nick, user.nick)
  end

  # 312
  def self.RPL_WHOISSERVER(nick, user)
    return sprintf(":%s 312 %s %s %s :%s", Options.server_name, nick, user.nick, Options.server_name, Options.server_description)
  end

  # 315
  def self.RPL_ENDOFWHO(nick, target)
    return sprintf(":%s 315 %s %s :End of /WHO list.", Options.server_name, nick, target)
  end

  # 317
  def self.RPL_WHOISIDLE(nick, user)
    idle_seconds = Time.now.to_i - user.last_activity
    return sprintf(":%s 317 %s %s %i %i :seconds idle, signon time", Options.server_name, nick, user.nick, idle_seconds, user.signon_time)
  end

  # 318
  def self.RPL_ENDOFWHOIS(nick, user)
    return sprintf(":%s 318 %s %s :End of /WHOIS list.", Options.server_name, nick, user.nick)
  end

  # 319
  def self.RPL_WHOISCHANNELS(nick, user)
    channels = user.channels.join(" ")
    return sprintf(":%s 319 %s %s :%s", Options.server_name, nick, user.nick, channels)
  end

  RPL_CHANNELMODEIS = ""  # 324 -- handle in Command class later

  # 328
  def self.RPL_CHANNEL_URL(nick, channel)
    return sprintf(":%s 328 %s %s :%s", Options.server_name, nick, channel.name, channel.url)
  end

  # 329
  def self.RPL_CREATIONTIME(nick, channel)
    return sprintf(":%s 329 %s %s %i", Options.server_name, nick, channel.name, channel.create_timestamp)
  end

  # 330 - RPL_WHOISACCOUNT
  # "is logged in as <NickServ_login>

  # 331
  def self.RPL_NOTOPIC(nick, channel)
    return sprintf(":%s 331 %s %s :No topic is set.", Options.server_name, nick, channel)
  end

  # 332
  def self.RPL_TOPIC(nick, channel, topic)
    return sprintf(":%s 332 %s %s :%s", Options.server_name, nick, channel, topic)
  end

  # 333
  def self.RPL_TOPICTIME(nick, channel)
    return sprintf(":%s 333 %s %s %s %i", Options.server_name, nick, channel.name, channel.topic_author, channel.topic_time)
  end

  # 338
  def self.RPL_WHOISACTUALLY(nick, user)
    return sprintf(":%s 338 %s %s %s :actually using host", Options.server_name, nick, user.nick, user.ip_address)
  end

  RPL_INVITING = "" # 341 -- handle in Command class later

  # 351
  def self.RPL_VERSION(nick, server)
    return sprintf(":%s 351 %s %s %s :%s", server, nick, Server::VERSION, server, Server::RELEASE)
  end

  # 352
  def self.RPL_WHOREPLY(nick, channel, user, hops)
    if user.away_message.length > 0
      return sprintf(":%s 352 %s %s %s %s %s %s G :%i %s", Options.server_name, nick, channel, user.ident, user.hostname, user.server, user.nick, hops, user.gecos)
    else
      return sprintf(":%s 352 %s %s %s %s %s %s H :%i %s", Options.server_name, nick, channel, user.ident, user.hostname, user.server, user.nick, hops, user.gecos)
    end
  end

  # 353
  def self.RPL_NAMREPLY(nick, channel, userlist)
    return sprintf(":%s 353 %s = %s :%s", Options.server_name, nick, channel, userlist)
  end

  # 366
  def self.RPL_ENDOFNAMES(nick, channel)
   return sprintf(":%s 366 %s %s :End of /NAMES list.", Options.server_name, nick, channel)
  end

  # 371
  def self.RPL_INFO(nick, text)
    return sprintf(":%s 371 %s :%s", Options.server_name, nick, text)
  end

  # 372
  def self.RPL_MOTD(nick, text)
    return sprintf(":%s 372 %s :- %s", Options.server_name, nick, text)
  end

  # 374
  def self.RPL_ENDOFINFO(nick)
    return sprintf(":%s 374 %s :End of /INFO list", Options.server_name, nick)
  end

  # 375
  def self.RPL_MOTDSTART(nick)
    return sprintf(":%s 375 %s :- %s Message of the Day -", Options.server_name, nick, Options.server_name)
  end

  # 376
  def self.RPL_ENDOFMOTD(nick)
    return sprintf(":%s 376 %s :End of /MOTD command.", Options.server_name, nick)
  end

  RPL_YOUAREOPER = "You are now an IRC Operator"                                      # 381
  RPL_REHASHING = "Rehashing"                                                         # 382

  # 391
  def self.RPL_TIME(nick, server)
    return sprintf(":%s 391 %s %s :%s", server, nick, server, Time.now.asctime)
  end

  # 401
  def self.ERR_NOSUCHNICK(nick, given_nick)
    return sprintf(":%s 401 %s %s :No such nick", Options.server_name, nick, given_nick)
  end

  # 402
  def self.ERR_NOSUCHSERVER(nick, server)
    return sprintf(":%s 402 %s %s :No such server", Options.server_name, nick, server)
  end

  # 403
  def self.ERR_NOSUCHCHANNEL(nick, channel)
    return sprintf(":%s 403 %s %s :Invalid channel name", Options.server_name, nick, channel)
  end

  ERR_CANNOTSENDTOCHAN = "Cannot send to channel"                                     # 404

  # 405
  def self.ERR_TOOMANYCHANNELS(nick, channel)
    return sprintf(":%s 405 %s %s :You have joined too many channels", Options.server_name, nick, channel)
  end

  # 410
  def self.ERR_INVALIDCAPCMD(nick, command)
    return sprintf(":%s 410 %s %s :Invalid CAP subcommand", Options.server_name, nick, command)
  end

  # 411
  def self.ERR_NORECIPIENT(nick, command)
    return sprintf(":%s 411 %s :No recipient given (%s)", Options.server_name, nick, command)
  end

  # 412
  def self.ERR_NOTEXTTOSEND(nick)
    return sprintf(":%s 412 %s :No text to send", Options.server_name, nick)
  end

  # 421
  def self.ERR_UNKNOWNCOMMAND(nick, command)
    return sprintf(":%s 421 %s %s :Unknown command", Options.server_name, nick, command)
  end

  # 422
  def self.ERR_NOMOTD(nick)
    return sprintf(":%s 422 %s :MOTD File is missing", Options.server_name, nick)
  end

  # 431
  def self.ERR_NONICKNAMEGIVEN(nick)
    return sprintf(":%s 431 %s :No nickname given", Options.server_name, nick)
  end

  # 432
  def self.ERR_ERRONEOUSNICKNAME(nick, given_nick)
    return sprintf(":%s 432 %s %s :Erroneous Nickname", Options.server_name, nick, given_nick)
  end

  # 433
  def self.ERR_NICKNAMEINUSE(nick, given_nick)
    return sprintf(":%s 433 %s %s :Nickname is already in use.", Options.server_name, nick, given_nick)
  end

  ERR_USERNOTINCHANNEL = "They aren't on that channel"                                # 441

  # 442
  def self.ERR_NOTONCHANNEL(nick, channel)
    return sprintf(":%s 442 %s %s :You're not on that channel", Options.server_name, nick, channel)
  end

  ERR_USERONCHANNEL = "is already on channel"                                         # 443

  # 451
  def self.ERR_NOTREGISTERED(command)
    return sprintf(":%s 451 %s :Register first.", Options.server_name, command)
  end

  # 461
  def self.ERR_NEEDMOREPARAMS(nick, command)
    return sprintf(":%s 461 %s %s :Not enough parameters", Options.server_name, nick, command)
  end

  # 462
  def self.ERR_ALREADYREGISTERED(nick)
    return sprintf(":%s 462 %s :You may not reregister", Options.server_name, nick)
  end

  # 468
  def self.ERR_INVALIDUSERNAME(nick, username)
    return sprintf(":%s 468 %s %s :Invalid username", Options.server_name, nick, username)
  end

  ERR_CHANNELISFULL = "Cannot join channel (+l)"                                      # 471
  ERR_INVITEONLYCHAN = "Cannot join channel (+i)"                                     # 473
  ERR_BANNEDFROMCHAN = "Cannot join channel (+b)"                                     # 474
  ERR_BADCHANNELKEY = "Cannot join channel (+k)"                                      # 475
  ERR_NOPRIVILEGES = "Permission Denied- You're not an IRC operator"                  # 481
  ERR_CHANOPRIVSNEEDED = "You're not channel operator"                                # 482
end
