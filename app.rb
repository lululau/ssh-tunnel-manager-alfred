$LOAD_PATH << 'lib'

require 'alfred_workflow'
require 'tunnel'

class App
  def list(args)
    print Tunnel.select_by_name(args[0]).each_with_object(Alfred::Workflow.new) { |tunnel, workflow|
      workflow.result
        .uid(tunnel.name)
        .title(tunnel.name)
        .subtitle(tunnel.alfred_subtitle)
        .icon(tunnel.icon)
        .arg(tunnel.alfred_arg)
    }.output
  end

  def start(args)
    puts Tunnel.find_by_name(args[0]).start!
  end

  def stop(args)
    puts Tunnel.find_by_name(args[0]).stop!
  end

  class << self
    def run(command, *args)
      App.new.send(command, args)
    end
  end
end

App.run(*ARGV)
