require_relative 'channel'
require_relative 'config'
require_relative 'limits'
require_relative 'server'

class Numeric
  # ToDo: Add more when not exhausted
  RPL_WELCOME = "Welcome to the #{Config.network_name} IRC Network, [ToDo: populate nick here with sprintf]!"       # 001
  RPL_YOURHOST = "Your host is #{Config.server_name}, running version #{Server.VERSION}.               # 002
  RPL_CREATED = "This server was created on #{Server.start_timestamp}."                                # 003
  RPL_MYINFO = "#{Config.server_name} #{Server.VERSION} #{Server.USER_MODES} #{Channel.CHANNEL_MODES}" # 004
  # Need to break ISUPPORT up to possibly avoid hitting the message length ceiling
  RPL_ISUPPORT1 = "AWAYLEN=#{Limits.AWAYLEN} CASEMAPPING=rfc1459 CHANMODES=#{Channel.ISUPPORT_CHANNEL_MODES} KICKLEN=#{Limits.KICKLEN} MAXBANS=#{Limits.MAXBANS}" + # 005
                 "MAXCHANNELS=#{Limits.MAXCHANNELS} :are supported by this server."
  RPL_ISUPPORT2 = "MODES=#{Limits.MODES} NETWORK=#{Config.network_name} NICKLEN=#{Limits.NICKLEN} PREFIX=#{Channel.ISUPPORT_PREFIX} TOPICLEN=#{Limits.TOPICLEN}" +  # 005
                  " :are supported by this server."
  RPL_MOTDSTART = "message of the day:"   # 375
  RPL_ENDOFMOTD = "End of MOTD."          # 376
end
