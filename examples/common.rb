require 'optparse'

class Common
  def initialize
    @options = {}
  end

  def parse
    options = {}

    OptionParser.new do |opt|
      opt.on("--hostname HOSTNAME", String,  "Hostname") { |v| options[:hostname]  = v }
      opt.on("--port PORT",         Integer, "Port"    ) { |v| options[:port]      = v }
      opt.on("--username USERNAME", String,  "Username") { |v| options[:user]      = v }
      opt.on("--password PASSWORD", String,  "Password") { |v| options[:password]  = v }
      opt.on("--debug") { ManageIQ::Messaging.logger = Logger.new(STDOUT) }
      opt.parse!
    end

    options[:hostname]   ||= ENV["QUEUE_HOSTNAME"] || "localhost"
    options[:port]       ||= ENV["QUEUE_PORT"]     || 61616
    options[:user]       ||= ENV["QUEUE_USER"]     || "admin"
    options[:password]   ||= ENV["QUEUE_PASSWORD"] || "smartvm"

    options[:port] = options[:port].to_i

    @options = options
    self
  end

  def q_options
    {
      :host       => @options[:hostname],
      :port       => @options[:port].to_i,
      :username   => @options[:user],
      :password   => @options[:password],
      :client_ref => "background_example",
    }
  end
end
