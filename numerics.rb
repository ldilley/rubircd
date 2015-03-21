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

require_relative 'channel'
require_relative 'limits'
require_relative 'options'
require_relative 'server'

class Numeric
  # Do not be alarmed by gaps between numeric IDs. Some are reserved and many are unused.

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
    return sprintf(":%s 003 %s :This server was created on %s", Options.server_name, nick, Server.friendly_start_date)
  end

  # 004
  def self.RPL_MYINFO(nick)
    return sprintf(":%s 004 %s %s %s %s %s", Options.server_name, nick, Options.server_name, Server::VERSION, Server::USER_MODES, Channel::CHANNEL_MODES)
  end

  # Need to break ISUPPORT up to possibly avoid hitting the message length ceiling
  # 005.1
  def self.RPL_ISUPPORT1(nick, server)
    unless Mod.find("FNICK").nil?
      fnc = "FNC " # forced nick changes
    end
    return sprintf(":%s 005 %s AWAYLEN=%i CASEMAPPING=rfc1459 CHANMODES=%s CHANTYPES=# CHARSET=ascii %sKICKLEN=%i MAXBANS=%i MAXCHANNELS=%i :are supported by this server",
                   server, nick, Limits::AWAYLEN, Channel::ISUPPORT_CHANNEL_MODES, fnc, Limits::KICKLEN, Limits::MAXBANS, Limits::MAXCHANNELS)
  end
  # 005.2
  def self.RPL_ISUPPORT2(nick, server)
    unless Options.ssl_port.nil?
      ssl_info = "SSL=#{Network.listen_address}:#{Options.ssl_port} "
    end
    unless Mod.find("PROTOCTL").nil?
      namesx = "NAMESX "
      uhnames = " UHNAMES"
    end
    unless Mod.find("USERIP").nil?
      userip = " USERIP"
    end
    return sprintf(":%s 005 %s MAXTARGETS=%s MODES=%s %sNETWORK=%s NICKLEN=%i OPERLOG PREFIX=%s %sSTARTTLS STATUSMSG=%s TOPICLEN=%i%s%s :are supported by this server",
                   server, nick, Limits::MAXTARGETS, Limits::MODES, namesx, Options.network_name, Limits::NICKLEN, Channel::ISUPPORT_PREFIX, ssl_info, Server::STATUS_PREFIXES,
                   Limits::TOPICLEN, uhnames, userip)
  end
  # 005.3
  def self.RPL_ISUPPORT3(nick, server)
    unless Mod.find("WALLCHOPS").nil?
      wallchops = " WALLCHOPS"
    end
    unless Mod.find("WALLVOICES").nil?
      wallvoices = " WALLVOICES"
    end
    return sprintf(":%s 005 %s%s%s :are supported by this server", server, nick, wallchops, wallvoices)
  end

  # 211
  def self.RPL_STATSLINKINFO(nick, user)
    return sprintf(":%s 211 %s %s[%s@%s] %i bytes received/%i bytes sent", Options.server_name, nick, user.nick, user.ident, user.hostname, user.data_recv, user.data_sent)
  end

  # 212
  def self.RPL_STATSCOMMANDS(nick, command, count, recv_bytes)
    return sprintf(":%s 212 %s %s %i %i", Options.server_name, nick, command, count, recv_bytes)
  end

  # 216
  def self.RPL_STATSKLINE(nick, address, create_time, duration, creator, reason)
    return sprintf(":%s 216 %s %s %i %i %s :%s", Options.server_name, nick, address, create_time, duration, creator, reason)
  end

  # 217
  def self.RPL_STATSQLINE(nick, quarantined_nick, create_time, duration, creator, reason)
    return sprintf(":%s 217 %s %s %i %i %s :%s", Options.server_name, nick, quarantined_nick, create_time, duration, creator, reason)
  end

  # 219
  def self.RPL_ENDOFSTATS(nick, symbol)
    return sprintf(":%s 219 %s %c :End of /STATS report", Options.server_name, nick, symbol)
  end

  # 221
  def self.RPL_UMODEIS(nick, mode)
    return sprintf(":%s 221 %s +%s", Options.server_name, nick, mode)
  end

  # 225
  def self.RPL_STATSZLINE(nick, address, create_time, duration, creator, reason)
    return sprintf(":%s 225 %s %s %i %i %s :%s", Options.server_name, nick, address, create_time, duration, creator, reason)
  end

  # 242
  def self.RPL_STATSUPTIME(nick, days, hours, minutes, seconds)
    return sprintf(":%s 242 %s :Server up %i days %.2i:%.2i:%.2i", Options.server_name, nick, days, hours, minutes, seconds)
  end

  # 243
  def self.RPL_STATSOLINE(nick, oper_host, oper_nick, oper_type)
    return sprintf(":%s 243 %s O %s * %s %s", Options.server_name, nick, oper_host, oper_nick, oper_type)
  end

  # 249
  def self.RPL_STATSDEBUG(nick, message)
    return sprintf(":%s 249 %s :%s", Options.server_name, nick, message)
  end

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

  # 302
  # Also used for USERIP module if loaded
  def self.RPL_USERHOST(nick, userhost_list)
    return sprintf(":%s 302 %s :%s", Options.server_name, nick, userhost_list.join(" "))
  end

  # 303
  def self.RPL_ISON(nick, nicks)
    return sprintf(":%s 303 %s :%s", Options.server_name, nick, nicks.join(" "))
  end

  # 305
  def self.RPL_UNAWAY(nick)
    return sprintf(":%s 305 %s :You are no longer marked as being away", Options.server_name, nick)
  end

  # 306
  def self.RPL_NOWAWAY(nick)
    return sprintf(":%s 306 %s :You have been marked as being away", Options.server_name, nick)
  end

  # 307
  def self.RPL_WHOISREGNICK(nick, user)
    return sprintf(":%s 307 %s %s is a registered nick", Options.server_name, nick, user.nick)
  end

  # 308
  # ToDo: Add server name in reply?
  def self.RPL_WHOISADMIN(nick, user)
    return sprintf(":%s 308 %s %s is an IRC Server Administrator", Options.server_name, nick, user.nick)
  end

  # 310
  def self.RPL_WHOISSERVICE(nick, user)
    return sprintf(":%s 310 %s %s is a Network Service", Options.server_name, nick, user.nick)
  end

  # 311
  def self.RPL_WHOISUSER(nick, user)
    return sprintf(":%s 311 %s %s %s %s * :%s", Options.server_name, nick, user.nick, user.ident, user.hostname, user.gecos)
  end

  # 313
  def self.RPL_WHOISOPERATOR(nick, user)
    return sprintf(":%s 313 %s %s is an IRC Operator", Options.server_name, nick, user.nick)
  end

  # 312
  def self.RPL_WHOISSERVER(nick, user, called_from_whois)
    if called_from_whois
      return sprintf(":%s 312 %s %s %s :%s", Options.server_name, nick, user.nick, Options.server_name, Options.server_description)
    else
      return sprintf(":%s 312 %s %s %s :%s", Options.server_name, nick, user.nick, Options.server_name, user.signoff_time)
    end
  end

  # 314
  def self.RPL_WHOWASUSER(nick, user)
    return sprintf(":%s 314 %s %s %s %s * :%s", Options.server_name, nick, user.nick, user.ident, user.hostname, user.gecos)
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
  def self.RPL_WHOISCHANNELS(nick, user, channels)
    return sprintf(":%s 319 %s %s :%s", Options.server_name, nick, user.nick, channels.join(" "))
  end

  # 321 - deprecated
  def self.RPL_LISTSTART(nick)
    return sprintf(":%s 321 %s Channel :Users Name", Options.server_name, nick)
  end

  # 322
  # Returning modes is not standard, but more informative (InspIRCd does this)
  def self.RPL_LIST(nick, channel, is_admin)
    if is_admin # show administrators the actual client count
      return sprintf(":%s 322 %s %s %i :[+%s] %s", Options.server_name, nick, channel.name, channel.users.length, channel.modes.join(""), channel.topic)
    else        # hide invisible administrators in user count from everyone else and do not list the channel if only invisible administrators occupy it
      if channel.users.length - channel.invisible_users.length >= 1
        return sprintf(":%s 322 %s %s %i :[+%s] %s", Options.server_name, nick, channel.name, channel.users.length - channel.invisible_users.length, channel.modes.join(""), channel.topic)
      else
        return nil
      end
    end
  end

  # 323
  def self.RPL_LISTEND(nick)
    return sprintf(":%s 323 %s :End of /LIST", Options.server_name, nick)
  end

  # 324
  def self.RPL_CHANNELMODEIS(nick, channel, modes, limit, key)
    if limit == nil && key != nil
      return sprintf(":%s 324 %s %s +%s %s", Options.server_name, nick, channel, modes, key)
    elsif key != nil && key == nil
      return sprintf(":%s 324 %s %s +%s %i", Options.server_name, nick, channel, modes, limit)
    else
      return sprintf(":%s 324 %s %s +%s %i %s", Options.server_name, nick, channel, modes, limit, key)
    end
  end

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

  # 341
  def self.RPL_INVITING(nick, given_nick, channel)
    return sprintf(":%s 341 %s %s %s", Options.server_name, nick, given_nick, channel)
  end

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

  # 367
  def self.RPL_BANLIST(nick, channel, ban_mask, create_timestamp)
    return sprintf(":%s 367 %s %s %s :%s", Options.server_name, nick, channel, ban_mask, create_timestamp)
  end

  # 368
  def self.RPL_ENDOFBANLIST(nick, channel)
    return sprintf(":%s 368 %s %s :End of channel ban list", Options.server_name, nick, channel)
  end

  # 369
  def self.RPL_ENDOFWHOWAS(nick)
    return sprintf(":%s 369 %s :End of WHOWAS", Options.server_name, nick)
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

  # 381
  def self.RPL_YOUAREOPER(user)
    if user.is_admin?
      return sprintf(":%s 381 %s :You are now an IRC Server Administrator", Options.server_name, user.nick)
    else
      return sprintf(":%s 381 %s :You are now an IRC Operator", Options.server_name, user.nick)
    end
  end

  # 382
  def self.RPL_REHASHING(nick, config_file)
    return sprintf(":%s 382 %s %s :Rehashing", Options.server_name, nick, config_file)
  end

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

  # 404
  def self.ERR_CANNOTSENDTOCHAN(nick, channel, reason)
    return sprintf(":%s 404 %s %s :Cannot send to channel (%s)", Options.server_name, nick, channel, reason)
  end

  # 405
  def self.ERR_TOOMANYCHANNELS(nick, channel)
    return sprintf(":%s 405 %s %s :You have joined too many channels", Options.server_name, nick, channel)
  end

  # 406
  def self.ERR_WASNOSUCHNICK(nick, given_nick)
    return sprintf(":%s 406 %s %s :There was no such nickname", Options.server_name, nick, given_nick)
  end

  # 407
  def self.ERR_TOOMANYTARGETS(nick, target)
    return sprintf(":%s 407 %s %s :Too many targets", Options.server_name, nick, target)
  end

  # 409
  def self.ERR_NOORIGIN(nick)
    return sprintf(":%s 409 %s :No origin specified", Options.server_name, nick)
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

  # 424
  def self.ERR_FILEERROR(nick, reason)
    return sprintf(":%s 424 %s :%s", Options.server_name, nick, reason)
  end

  # 431
  def self.ERR_NONICKNAMEGIVEN(nick)
    return sprintf(":%s 431 %s :No nickname given", Options.server_name, nick)
  end

  # 432
  def self.ERR_ERRONEOUSNICKNAME(nick, given_nick, reason)
    return sprintf(":%s 432 %s %s :Erroneous Nickname: %s", Options.server_name, nick, given_nick, reason)
  end

  # 433
  def self.ERR_NICKNAMEINUSE(nick, given_nick)
    return sprintf(":%s 433 %s %s :Nickname is already in use.", Options.server_name, nick, given_nick)
  end

  # 441
  def self.ERR_USERNOTINCHANNEL(nick, given_nick, channel)
    return sprintf(":%s 441 %s %s %s :They aren't on that channel", Options.server_name, nick, given_nick, channel)
  end

  # 442
  def self.ERR_NOTONCHANNEL(nick, channel)
    return sprintf(":%s 442 %s %s :Not on that channel", Options.server_name, nick, channel)
  end

  # 443
  def self.ERR_USERONCHANNEL(nick, given_nick, channel)
    return sprintf(":%s 443 %s %s %s :is already on channel", Options.server_name, nick, given_nick, channel)
  end

  # 445
  def self.ERR_SUMMONDISABLED(nick)
    return sprintf(":%s 445 %s :SUMMON is not implemented.", Options.server_name, nick)
  end

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

  # 464
  def self.ERR_PASSWDMISMATCH(nick)
    return sprintf(":%s 464 %s :Password incorrect", Options.server_name, nick)
  end

  # 467
  def self.ERR_KEYSET(nick, channel)
    return sprintf(":%s 467 %s %s :Channel key already set", Options.server_name, nick, channel)
  end

  # 468
  def self.ERR_INVALIDUSERNAME(nick, username)
    return sprintf(":%s 468 %s %s :Invalid username", Options.server_name, nick, username)
  end

  # 471
  def self.ERR_CHANNELISFULL(nick, channel)
    return sprintf(":%s 471 %s %s :Cannot join channel (+l)", Options.server_name, nick, channel)
  end

  # 472
  def self.ERR_UNKNOWNMODE(nick, mode)
    return sprintf(":%s 472 %s %c :is unknown mode char to me", Options.server_name, nick, mode)
  end

  # 473
  def self.ERR_INVITEONLYCHAN(nick, channel)
    return sprintf(":%s 473 %s %s :Cannot join channel (+i)", Options.server_name, nick, channel)
  end

  # 474
  def self.ERR_BANNEDFROMCHAN(nick, channel)
    return sprintf(":%s 474 %s %s :Cannot join channel (+b)", Options.server_name, nick, channel)
  end

  # 475
  def self.ERR_BADCHANNELKEY(nick, channel)
    return sprintf(":%s 475 %s %s :Cannot join channel (+k)", Options.server_name, nick, channel)
  end

  # 481
  def self.ERR_NOPRIVILEGES(nick)
    return sprintf(":%s 481 %s :You do not have the required privileges", Options.server_name, nick)
  end

  # 482
  def self.ERR_CHANOPRIVSNEEDED(nick, channel)
    return sprintf(":%s 482 %s %s :You're not channel operator", Options.server_name, nick, channel)
  end

  # 485
  def self.ERR_ATTACKDENY(nick, given_nick)
    return sprintf(":%s 485 %s :Cannot ban, kick, kill, or deop %s. %s is an IRC Administrator or Service.", Options.server_name, nick, given_nick, given_nick)
  end

  # 491
  def self.ERR_NOOPERHOST(nick)
    return sprintf(":%s 491 %s :Invalid credentials", Options.server_name, nick)
  end

  # 502.1
  def self.ERR_USERSDONTMATCH1(nick) 
    return sprintf(":%s 502 %s :Can't view modes for other users", Options.server_name, nick)
  end

  # 502.2
  def self.ERR_USERSDONTMATCH2(nick)
    return sprintf(":%s 502 %s :Can't change mode for other users", Options.server_name, nick)
  end


  # Below are non-standard numerics (following the lead from InspIRCd)

  # 670
  def self.RPL_STARTTLS(nick)
    return sprintf(":%s 670 %s :STARTTLS successful, go ahead with TLS handshake", Options.server_name, nick)
  end

  # 691
  def self.ERR_STARTTLSFAILURE(nick)
    return sprintf(":%s 691 %s :STARTTLS failure", Options.server_name, nick)
  end

  # 700
  def self.RPL_MODLIST(nick, module_name, module_address)
    return sprintf(":%s 700 %s :%s \(%s\)", Options.server_name, nick, module_name, module_address)
  end

  # 703
  def self.RPL_ENDOFMODLIST(nick)
    return sprintf(":%s 703 %s :End of MODLIST command", Options.server_name, nick)
  end

  # Generic debug messages
  # 750
  def self.RPL_DEBUGMSG(nick, message)
    return sprintf(":%s 750 %s :%s", Options.server_name, nick, message)
  end
  # 751
  def self.RPL_ENDOFDEBUGMSG(nick)
    return sprintf(":%s 751 %s :End of debug message", Options.server_name, nick)
  end

  # 972
  def self.ERR_CANTUNLOADMODULE(nick, module_name, reason)
    return sprintf(":%s 972 %s %s :Failed to unload module: %s", Options.server_name, nick, module_name, reason)
  end

  # 973
  def self.RPL_UNLOADEDMODULE(nick, module_name, module_address)
    return sprintf(":%s 973 %s %s :Module successfully unloaded @ %s", Options.server_name, nick, module_name, module_address)
  end

  # 974
  def self.ERR_CANTLOADMODULE(nick, module_name, reason)
    return sprintf(":%s 974 %s %s :Failed to load module: %s", Options.server_name, nick, module_name, reason)
  end

  # 975
  def self.RPL_LOADEDMODULE(nick, module_name, module_address)
    return sprintf(":%s 975 %s %s :Module successfully loaded @ %s", Options.server_name, nick, module_name, module_address)
  end
end
