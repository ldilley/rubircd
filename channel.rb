class Ban
  @creator
  @mask
  @reason
  @create_timestamp

  def initialize(creator, mask, reason)
    @creator = creator
    @mask = mask
    @reason = reason
    @create_timestamp = Time.now
  end

  # This method is used to locate the unique mask for ban removal
  def mask
    @mask
  end
end

class Channel
  @bans
  @name
  @modes
  @topic
  @users
  @founder
  @create_timestamp

  def initialize(name, founder)
    @bans = Array.new
    @name = name
    @modes = Array.new
    @modes.push('n')
    @modes.push('t')
    @topic = ""
    @users = Array.new
    @founder = founder 
    @create_timestamp = Time.now
  end

  def add_ban(creator, mask, reason)
    ban = Ban.new(creator, mask, reason)
    @bans.push(ban)
  end

  def remove_ban(mask)
    @bans.each do |ban|
      if ban.mask == mask
        @bans.delete(ban)
      # else
      # ToDo: send appropriate RPL
      end
    end
  end

  def add_mode(mode)
    @modes.push(mode)
  end

  def remove_mode(mode)
    @modes.delete(mode)
  end

  def clear_modes
    @modes.clear
  end

  def set_topic(new_topic)
    @topic = new_topic
  end

  def add_user(user)
    @users.push(user)
  end

  def remove_user(user)
    @users.delete(user)
  end
end
