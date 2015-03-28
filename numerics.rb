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

# Defines numeric errors and replies
class Numeric
  # Do not be alarmed by gaps between numeric IDs. Some are reserved and many are unused.

  # 001
  def self.rpl_welcome(nick)
    format(':%s 001 %s :Welcome to the %s IRC Network, %s!', Options.server_name, nick, Options.network_name, nick)
  end

  # 002
  def self.rpl_yourhost(nick)
    format(':%s 002 %s :Your host is %s, running version %s', Options.server_name, nick, Options.server_name, Server::VERSION)
  end

  # 003
  def self.rpl_created(nick)
    format(':%s 003 %s :This server was created on %s', Options.server_name, nick, Server.friendly_start_date)
  end

  # 004
  def self.rpl_myinfo(nick)
    format(':%s 004 %s %s %s %s %s', Options.server_name, nick, Options.server_name, Server::VERSION, Server::USER_MODES, Channel::CHANNEL_MODES)
  end

  # Need to break ISUPPORT up to possibly avoid hitting the message length ceiling
  # 005.1
  def self.rpl_isupport1(nick, server)
    fnc = 'FNC ' unless Mod.find('FNICK').nil? # forced nick changes
    format(':%s 005 %s AWAYLEN=%i CASEMAPPING=rfc1459 CHANMODES=%s CHANTYPES=# CHARSET=ascii %sKICKLEN=%i MAXBANS=%i MAXCHANNELS=%i :are supported by this server',
           server, nick, Limits::AWAYLEN, Channel::ISUPPORT_CHANNEL_MODES, fnc, Limits::KICKLEN, Limits::MAXBANS, Limits::MAXCHANNELS)
  end
  # 005.2
  def self.rpl_isupport2(nick, server)
    unless Options.ssl_port.nil?
      ssl_info = " SSL=#{Network.listen_address}:#{Options.ssl_port}"
    end
    starttls = 'STARTTLS ' if Options.enable_starttls.to_s == 'true' && !Mod.find('CAP').nil?
    unless Mod.find('PROTOCTL').nil?
      namesx = 'NAMESX '
      uhnames = ' UHNAMES'
    end
    userip = ' USERIP' unless Mod.find('USERIP').nil?
    format(':%s 005 %s MAXTARGETS=%s MODES=%s %sNETWORK=%s NICKLEN=%i OPERLOG PREFIX=%s%s %sSTATUSMSG=%s TOPICLEN=%i%s%s :are supported by this server',
           server, nick, Limits::MAXTARGETS, Limits::MODES, namesx, Options.network_name, Limits::NICKLEN, Channel::ISUPPORT_PREFIX, ssl_info, starttls,
           Server::STATUS_PREFIXES, Limits::TOPICLEN, uhnames, userip)
  end
  # 005.3
  def self.rpl_isupport3(nick, server)
    wallchops = ' WALLCHOPS' unless Mod.find('WALLCHOPS').nil?
    wallvoices = ' WALLVOICES' unless Mod.find('WALLVOICES').nil?
    format(':%s 005 %s%s%s :are supported by this server', server, nick, wallchops, wallvoices)
  end

  # 211
  def self.rpl_statslinkinfo(nick, user)
    format(':%s 211 %s %s[%s@%s] %i bytes received/%i bytes sent', Options.server_name, nick, user.nick, user.ident, user.hostname, user.data_recv, user.data_sent)
  end

  # 212
  def self.rpl_statscommands(nick, command, count, recv_bytes)
    format(':%s 212 %s %s %i %i', Options.server_name, nick, command, count, recv_bytes)
  end

  # 216
  def self.rpl_statskline(nick, address, create_time, duration, creator, reason)
    format(':%s 216 %s %s %i %i %s :%s', Options.server_name, nick, address, create_time, duration, creator, reason)
  end

  # 217
  def self.rpl_statsqline(nick, quarantined_nick, create_time, duration, creator, reason)
    format(':%s 217 %s %s %i %i %s :%s', Options.server_name, nick, quarantined_nick, create_time, duration, creator, reason)
  end

  # 219
  def self.rpl_endofstats(nick, symbol)
    format(':%s 219 %s %c :End of /STATS report', Options.server_name, nick, symbol)
  end

  # 221
  def self.rpl_umodeis(nick, mode)
    format(':%s 221 %s +%s', Options.server_name, nick, mode)
  end

  # 225
  def self.rpl_statszline(nick, address, create_time, duration, creator, reason)
    format(':%s 225 %s %s %i %i %s :%s', Options.server_name, nick, address, create_time, duration, creator, reason)
  end

  # 242
  def self.rpl_statsuptime(nick, days, hours, minutes, seconds)
    format(':%s 242 %s :Server up %i days %.2i:%.2i:%.2i', Options.server_name, nick, days, hours, minutes, seconds)
  end

  # 243
  def self.rpl_statsoline(nick, oper_host, oper_nick, oper_type)
    format(':%s 243 %s O %s * %s %s', Options.server_name, nick, oper_host, oper_nick, oper_type)
  end

  # 249
  def self.rpl_statsdebug(nick, message)
    format(':%s 249 %s :%s', Options.server_name, nick, message)
  end

  # 251
  def self.rpl_luserclient(nick)
    format(':%s 251 %s :There are %i users and %i invisible on %i servers', Options.server_name, nick, Server.visible_count, Server.invisible_count, Server.link_count + 1)
  end

  # 252
  def self.rpl_luserop(nick)
    format(':%s 252 %s %i :IRC Operators online', Options.server_name, nick, Server.oper_count)
  end

  # 253
  # For unregistered connections
  def self.rpl_luserunknown(nick)
    format(':%s 253 %s %i :unknown connection(s)', Options.server_name, nick, Server.unknown_clients)
  end

  # 254
  def self.rpl_luserchannels(nick)
    format(':%s 254 %s %i :channels formed', Options.server_name, nick, Server.channel_count)
  end

  # 255
  def self.rpl_luserme(nick)
    format(':%s 255 %s :I have %i clients and %i servers', Options.server_name, nick, Server.client_count, Server.link_count + 1)
  end

  # 256
  def self.rpl_adminme(nick, server)
    format(':%s 256 %s :Administrative info for %s:', server, nick, server)
  end

  # 257
  def self.rpl_adminloc1(nick, server)
    format(':%s 257 %s :Name:     %s', server, nick, Options.admin_name)
  end

  # 258
  def self.rpl_adminloc2(nick, server)
    format(':%s 258 %s :Nickname: %s', server, nick, Options.admin_nick)
  end

  # 259
  def self.rpl_adminemail(nick, server)
    format(':%s 259 %s :E-mail:   %s', server, nick, Options.admin_email)
  end

  # 265
  def self.rpl_localusers(nick)
    format(':%s 265 %s Current local users: %i Max: %i', Options.server_name, nick, Server.local_users, Server.local_users_max)
  end

  # 266
  def self.rpl_globalusers(nick)
    format(':%s 266 %s Current global users: %i Max: %i', Options.server_name, nick, Server.global_users, Server.global_users_max)
  end

  # 301
  def self.rpl_away(nick, user)
    format(':%s 301 %s %s :%s', Options.server_name, nick, user.nick, user.away_message)
  end

  # 302
  # Also used for USERIP module if loaded
  def self.rpl_userhost(nick, userhost_list)
    format(':%s 302 %s :%s', Options.server_name, nick, userhost_list.join(' '))
  end

  # 303
  def self.rpl_ison(nick, nicks)
    format(':%s 303 %s :%s', Options.server_name, nick, nicks.join(' '))
  end

  # 305
  def self.rpl_unaway(nick)
    format(':%s 305 %s :You are no longer marked as being away', Options.server_name, nick)
  end

  # 306
  def self.rpl_nowaway(nick)
    format(':%s 306 %s :You have been marked as being away', Options.server_name, nick)
  end

  # 307
  def self.rpl_whoisregnick(nick, user)
    format(':%s 307 %s %s is a registered nick', Options.server_name, nick, user.nick)
  end

  # 308
  # TODO: Add server name in reply?
  def self.rpl_whoisadmin(nick, user)
    format(':%s 308 %s %s is an IRC Server Administrator', Options.server_name, nick, user.nick)
  end

  # 310
  def self.rpl_whoisservice(nick, user)
    format(':%s 310 %s %s is a Network Service', Options.server_name, nick, user.nick)
  end

  # 311
  def self.rpl_whoisuser(nick, user)
    format(':%s 311 %s %s %s %s * :%s', Options.server_name, nick, user.nick, user.ident, user.hostname, user.gecos)
  end

  # 313
  def self.rpl_whoisoperator(nick, user)
    format(':%s 313 %s %s is an IRC Operator', Options.server_name, nick, user.nick)
  end

  # 312
  def self.rpl_whoisserver(nick, user, called_from_whois)
    if called_from_whois
      return format(':%s 312 %s %s %s :%s', Options.server_name, nick, user.nick, Options.server_name, Options.server_description)
    else
      return format(':%s 312 %s %s %s :%s', Options.server_name, nick, user.nick, Options.server_name, user.signoff_time)
    end
  end

  # 314
  def self.rpl_whowasuser(nick, user)
    format(':%s 314 %s %s %s %s * :%s', Options.server_name, nick, user.nick, user.ident, user.hostname, user.gecos)
  end

  # 315
  def self.rpl_endofwho(nick, target)
    format(':%s 315 %s %s :End of /WHO list.', Options.server_name, nick, target)
  end

  # 317
  def self.rpl_whoisidle(nick, user)
    idle_seconds = Time.now.to_i - user.last_activity
    format(':%s 317 %s %s %i %i :seconds idle, signon time', Options.server_name, nick, user.nick, idle_seconds, user.signon_time)
  end

  # 318
  def self.rpl_endofwhois(nick, user)
    format(':%s 318 %s %s :End of /WHOIS list.', Options.server_name, nick, user.nick)
  end

  # 319
  def self.rpl_whoischannels(nick, user, channels)
    format(':%s 319 %s %s :%s', Options.server_name, nick, user.nick, channels.join(' '))
  end

  # 321 - deprecated
  def self.rpl_liststart(nick)
    format(':%s 321 %s Channel :Users Name', Options.server_name, nick)
  end

  # 322
  # Returning modes is not standard, but more informative (InspIRCd does this)
  def self.rpl_list(nick, channel, admin)
    if admin # show administrators the actual client count
      return format(':%s 322 %s %s %i :[+%s] %s', Options.server_name, nick, channel.name, channel.users.length, channel.modes.join(''), channel.topic)
    else        # hide invisible administrators in user count from everyone else and do not list the channel if only invisible administrators occupy it
      if channel.users.length - channel.invisible_users.length >= 1
        return format(':%s 322 %s %s %i :[+%s] %s', Options.server_name, nick, channel.name, channel.users.length - channel.invisible_users.length, channel.modes.join(''), channel.topic)
      else
        return nil
      end
    end
  end

  # 323
  def self.rpl_listend(nick)
    format(':%s 323 %s :End of /LIST', Options.server_name, nick)
  end

  # 324
  def self.rpl_channelmodeis(nick, channel, modes, limit, key)
    if limit.nil? && !key.nil?
      return format(':%s 324 %s %s +%s %s', Options.server_name, nick, channel, modes, key)
    elsif !key.nil? && key.nil?
      return format(':%s 324 %s %s +%s %i', Options.server_name, nick, channel, modes, limit)
    else
      return format(':%s 324 %s %s +%s %i %s', Options.server_name, nick, channel, modes, limit, key)
    end
  end

  # 328
  def self.rpl_channel_url(nick, channel)
    format(':%s 328 %s %s :%s', Options.server_name, nick, channel.name, channel.url)
  end

  # 329
  def self.rpl_creationtime(nick, channel)
    format(':%s 329 %s %s %i', Options.server_name, nick, channel.name, channel.create_timestamp)
  end

  # 330 - RPL_WHOISACCOUNT
  # is logged in as <NickServ_login>

  # 331
  def self.rpl_notopic(nick, channel)
    format(':%s 331 %s %s :No topic is set.', Options.server_name, nick, channel)
  end

  # 332
  def self.rpl_topic(nick, channel, topic)
    format(':%s 332 %s %s :%s', Options.server_name, nick, channel, topic)
  end

  # 333
  def self.rpl_topictime(nick, channel)
    format(':%s 333 %s %s %s %i', Options.server_name, nick, channel.name, channel.topic_author, channel.topic_time)
  end

  # 338
  def self.rpl_whoisactually(nick, user)
    format(':%s 338 %s %s %s :actually using host', Options.server_name, nick, user.nick, user.ip_address)
  end

  # 341
  def self.rpl_inviting(nick, given_nick, channel)
    format(':%s 341 %s %s %s', Options.server_name, nick, given_nick, channel)
  end

  # 351
  def self.rpl_version(nick, server)
    format(':%s 351 %s %s %s :%s', server, nick, Server::VERSION, server, Server::RELEASE)
  end

  # 352
  def self.rpl_whoreply(nick, channel, user, hops)
    if user.away_message.length > 0
      return format(':%s 352 %s %s %s %s %s %s G :%i %s', Options.server_name, nick, channel, user.ident, user.hostname, user.server, user.nick, hops, user.gecos)
    else
      return format(':%s 352 %s %s %s %s %s %s H :%i %s', Options.server_name, nick, channel, user.ident, user.hostname, user.server, user.nick, hops, user.gecos)
    end
  end

  # 353
  def self.rpl_namreply(nick, channel, userlist)
    format(':%s 353 %s = %s :%s', Options.server_name, nick, channel, userlist)
  end

  # 366
  def self.rpl_endofnames(nick, channel)
    format(':%s 366 %s %s :End of /NAMES list.', Options.server_name, nick, channel)
  end

  # 367
  def self.rpl_banlist(nick, channel, ban_mask, create_timestamp)
    format(':%s 367 %s %s %s :%s', Options.server_name, nick, channel, ban_mask, create_timestamp)
  end

  # 368
  def self.rpl_endofbanlist(nick, channel)
    format(':%s 368 %s %s :End of channel ban list', Options.server_name, nick, channel)
  end

  # 369
  def self.rpl_endofwhowas(nick)
    format(':%s 369 %s :End of WHOWAS', Options.server_name, nick)
  end

  # 371
  def self.rpl_info(nick, text)
    format(':%s 371 %s :%s', Options.server_name, nick, text)
  end

  # 372
  def self.rpl_motd(nick, text)
    format(':%s 372 %s :- %s', Options.server_name, nick, text)
  end

  # 374
  def self.rpl_endofinfo(nick)
    format(':%s 374 %s :End of /INFO list', Options.server_name, nick)
  end

  # 375
  def self.rpl_motdstart(nick)
    format(':%s 375 %s :- %s Message of the Day -', Options.server_name, nick, Options.server_name)
  end

  # 376
  def self.rpl_endofmotd(nick)
    format(':%s 376 %s :End of /MOTD command.', Options.server_name, nick)
  end

  # 381
  def self.rpl_youareoper(user)
    if user.admin
      return format(':%s 381 %s :You are now an IRC Server Administrator', Options.server_name, user.nick)
    else
      return format(':%s 381 %s :You are now an IRC Operator', Options.server_name, user.nick)
    end
  end

  # 382
  def self.rpl_rehashing(nick, config_file)
    format(':%s 382 %s %s :Rehashing', Options.server_name, nick, config_file)
  end

  # 391
  def self.rpl_time(nick, server)
    format(':%s 391 %s %s :%s', server, nick, server, Time.now.asctime)
  end

  # 401
  def self.err_nosuchnick(nick, given_nick)
    format(':%s 401 %s %s :No such nick', Options.server_name, nick, given_nick)
  end

  # 402
  def self.err_nosuchserver(nick, server)
    format(':%s 402 %s %s :No such server', Options.server_name, nick, server)
  end

  # 403
  def self.err_nosuchchannel(nick, channel)
    format(':%s 403 %s %s :Invalid channel name', Options.server_name, nick, channel)
  end

  # 404
  def self.err_cannotsendtochan(nick, channel, reason)
    format(':%s 404 %s %s :Cannot send to channel (%s)', Options.server_name, nick, channel, reason)
  end

  # 405
  def self.err_toomanychannels(nick, channel)
    format(':%s 405 %s %s :You have joined too many channels', Options.server_name, nick, channel)
  end

  # 406
  def self.err_wasnosuchnick(nick, given_nick)
    format(':%s 406 %s %s :There was no such nickname', Options.server_name, nick, given_nick)
  end

  # 407
  def self.err_toomanytargets(nick, target)
    format(':%s 407 %s %s :Too many targets', Options.server_name, nick, target)
  end

  # 409
  def self.err_noorigin(nick)
    format(':%s 409 %s :No origin specified', Options.server_name, nick)
  end

  # 410
  def self.err_invalidcapcmd(nick, command)
    format(':%s 410 %s %s :Invalid CAP subcommand', Options.server_name, nick, command)
  end

  # 411
  def self.err_norecipient(nick, command)
    format(':%s 411 %s :No recipient given (%s)', Options.server_name, nick, command)
  end

  # 412
  def self.err_notexttosend(nick)
    format(':%s 412 %s :No text to send', Options.server_name, nick)
  end

  # 421
  def self.err_unknowncommand(nick, command)
    format(':%s 421 %s %s :Unknown command', Options.server_name, nick, command)
  end

  # 422
  def self.err_nomotd(nick)
    format(':%s 422 %s :MOTD File is missing', Options.server_name, nick)
  end

  # 424
  def self.err_fileerror(nick, reason)
    format(':%s 424 %s :%s', Options.server_name, nick, reason)
  end

  # 431
  def self.err_nonicknamegiven(nick)
    format(':%s 431 %s :No nickname given', Options.server_name, nick)
  end

  # 432
  def self.err_erroneousnickname(nick, given_nick, reason)
    format(':%s 432 %s %s :Erroneous Nickname: %s', Options.server_name, nick, given_nick, reason)
  end

  # 433
  def self.err_nicknameinuse(nick, given_nick)
    format(':%s 433 %s %s :Nickname is already in use.', Options.server_name, nick, given_nick)
  end

  # 441
  def self.err_usernotinchannel(nick, given_nick, channel)
    format(':%s 441 %s %s %s :They aren\'t on that channel', Options.server_name, nick, given_nick, channel)
  end

  # 442
  def self.err_notonchannel(nick, channel)
    format(':%s 442 %s %s :Not on that channel', Options.server_name, nick, channel)
  end

  # 443
  def self.err_useronchannel(nick, given_nick, channel)
    format(':%s 443 %s %s %s :is already on channel', Options.server_name, nick, given_nick, channel)
  end

  # 445
  def self.err_summondisabled(nick)
    format(':%s 445 %s :SUMMON is not implemented.', Options.server_name, nick)
  end

  # 451
  def self.err_notregistered(command)
    format(':%s 451 %s :Register first.', Options.server_name, command)
  end

  # 461
  def self.err_needmoreparams(nick, command)
    format(':%s 461 %s %s :Not enough parameters', Options.server_name, nick, command)
  end

  # 462
  def self.err_alreadyregistered(nick)
    format(':%s 462 %s :You may not reregister', Options.server_name, nick)
  end

  # 464
  def self.err_passwdmismatch(nick)
    format(':%s 464 %s :Password incorrect', Options.server_name, nick)
  end

  # 467
  def self.err_keyset(nick, channel)
    format(':%s 467 %s %s :Channel key already set', Options.server_name, nick, channel)
  end

  # 468
  def self.err_invalidusername(nick, username)
    format(':%s 468 %s %s :Invalid username', Options.server_name, nick, username)
  end

  # 471
  def self.err_channelisfull(nick, channel)
    format(':%s 471 %s %s :Cannot join channel (+l)', Options.server_name, nick, channel)
  end

  # 472
  def self.err_unknownmode(nick, mode)
    format(':%s 472 %s %c :is unknown mode char to me', Options.server_name, nick, mode)
  end

  # 473
  def self.err_inviteonlychan(nick, channel)
    format(':%s 473 %s %s :Cannot join channel (+i)', Options.server_name, nick, channel)
  end

  # 474
  def self.err_bannedfromchan(nick, channel)
    format(':%s 474 %s %s :Cannot join channel (+b)', Options.server_name, nick, channel)
  end

  # 475
  def self.err_badchannelkey(nick, channel)
    format(':%s 475 %s %s :Cannot join channel (+k)', Options.server_name, nick, channel)
  end

  # 481
  def self.err_noprivileges(nick)
    format(':%s 481 %s :You do not have the required privileges', Options.server_name, nick)
  end

  # 482
  def self.err_chanoprivsneeded(nick, channel)
    format(':%s 482 %s %s :You\'re not channel operator', Options.server_name, nick, channel)
  end

  # 485
  def self.err_attackdeny(nick, given_nick)
    format(':%s 485 %s :Cannot ban, kick, kill, or deop %s. %s is an IRC Administrator or Service.', Options.server_name, nick, given_nick, given_nick)
  end

  # 491
  def self.err_nooperhost(nick)
    format(':%s 491 %s :Invalid credentials', Options.server_name, nick)
  end

  # 502.1
  def self.err_usersdontmatch1(nick)
    format(':%s 502 %s :Can\'t view modes for other users', Options.server_name, nick)
  end

  # 502.2
  def self.err_usersdontmatch2(nick)
    format(':%s 502 %s :Can\'t change mode for other users', Options.server_name, nick)
  end

  # Below are non-standard numerics (following the lead from InspIRCd)
  # 670
  def self.rpl_starttls(nick)
    format(':%s 670 %s :STARTTLS successful, go ahead with TLS handshake', Options.server_name, nick)
  end

  # 691
  def self.err_starttlsfailure(nick)
    format(':%s 691 %s :STARTTLS failure', Options.server_name, nick)
  end

  # 700
  def self.rpl_modlist(nick, module_name, module_address)
    format(':%s 700 %s :%s \(%s\)', Options.server_name, nick, module_name, module_address)
  end

  # 703
  def self.rpl_endofmodlist(nick)
    format(':%s 703 %s :End of MODLIST command', Options.server_name, nick)
  end

  # Generic debug messages
  # 750
  def self.rpl_debugmsg(nick, message)
    format(':%s 750 %s :%s', Options.server_name, nick, message)
  end
  # 751
  def self.rpl_endofdebugmsg(nick)
    format(':%s 751 %s :End of debug message', Options.server_name, nick)
  end

  # 972
  def self.err_cantunloadmodule(nick, module_name, reason)
    format(':%s 972 %s %s :Failed to unload module: %s', Options.server_name, nick, module_name, reason)
  end

  # 973
  def self.rpl_unloadedmodule(nick, module_name, module_address)
    format(':%s 973 %s %s :Module successfully unloaded @ %s', Options.server_name, nick, module_name, module_address)
  end

  # 974
  def self.err_cantloadmodule(nick, module_name, reason)
    format(':%s 974 %s %s :Failed to load module: %s', Options.server_name, nick, module_name, reason)
  end

  # 975
  def self.rpl_loadedmodule(nick, module_name, module_address)
    format(':%s 975 %s %s :Module successfully loaded @ %s', Options.server_name, nick, module_name, module_address)
  end
end
