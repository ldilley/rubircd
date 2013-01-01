require 'yaml'

module JRIRC
  class Config
    @@server_name = nil
    @@listen_port = nil

    def initialize
      config_file=YAML.load_file("config.yml")
      @@server_name = config_file["server_name"]
      @@listen_port = config_file["listen_port"]

      if @@server_name == nil
        puts("\nUnable to read server_name option from config.yml file!")
        exit!
      end

      if @@listen_port == nil
        puts("\nUnable to read listen_port option from config.yml file!")
        exit!
      end

      if @@listen_port <= 0 || @@listen_port >=65536
        puts("\nlisten_port value is out of range!")
        exit!
      end
    end

    def server_name
      return @@server_name
    end

    def listen_port
      return @@listen_port
    end
  end # class
end # module
