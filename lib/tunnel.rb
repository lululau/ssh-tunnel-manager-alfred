require 'ostruct'
require 'yaml'

class Tunnel
  attr_accessor :config, :name, :remote_ssh_host, :options

  def initialize(config_hash)
    @config = OpenStruct.new(config_hash)
    @name = @config.name
    @remote_ssh_host = @config.remote_ssh_host
    @options = @config.tunnel_options
  end

  def status
    @status ||= get_status
  end

  def icon
    "#{status}.png"
  end

  def alfred_arg
    if status == 'on'
      "stop #{name}"
    else
      "start #{name}"
    end
  end

  def alfred_subtitle
    "Type: #{type}, Options: #{options}"
  end

  def type
    if options =~ /-L/
      'Local'
    elsif options =~ /-R/
      'Remote'
    elsif options =~ /D/
      'Socks'
    else
      'Unknown'
    end
  end

  def pidfile
    "/tmp/autossh-ssh-tunnel-manager-alfred.#{name}.pid"
  end

  def pid
    if File.exist?(pidfile)
      IO.read(pidfile).chomp
    end
  end

  def get_status
    return 'off' unless pid
    if `ps -ef | awk '$3 == #{pid} {print 1}'`.chomp == '1'
      'on'
    else
      'off'
    end
  end

  def start!
    system({'AUTOSSH_PIDFILE' => pidfile}, <<-EOF)
    /usr/local/bin/autossh -M 0 -f -q -N -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=yes #{@options} #{remote_ssh_host}
    EOF

    sleep 0.1

    if get_status == 'on'
      "#{name} On"
    else
      "Failed to turn on #{name}!"
    end
  end

  def stop!
    system <<-EOF
    kill #{pid}
    EOF

    sleep 0.1

    if get_status == 'off'
      "#{name} Off"
    else
      "Failed to turn off #{name}"
    end
  end

  class << self
    def all
      @all ||= YAML.load(IO.read(File.expand_path('~/.ssh/tunnels.yml'))).map do |config_hash|
        new(config_hash)
      end
    end

    def find_by_name(name)
      all.find { |t| t.name == name }
    end

    def select_by_name(name)
      if name.nil? || name.empty?
        all
      else
        all.select { |t| t.name.include?(name) }
      end
    end
  end
end
