module ManageIQ
  module Messaging
    class StompClient < Client
      delegate :subscribe,   :to => :stomp_client
      delegate :unsubscribe, :to => :stomp_client
      delegate :publish,     :to => :stomp_client
      delegate :close,       :to => :stomp_client
      delegate :ack,         :to => :stomp_client

      private
      attr_reader :stomp_client

      # options
      #   :host
      #   :username
      #   :password
      #   :port
      #   :client_ref (optional)
      #   :heartbeat  (optional, default to true)
      def initialize(options)
        host = {:host => options[:host], :port => options[:port]}
        host[:passcode] = options[:password] if options[:password]
        host[:login] = options[:username] if options[:username]
        headers = {}
        headers.merge!(:host => options[:host], :"accept-version" => "1.2", :"heart-beat" => "2000,0") unless options[:heartbeat] == false
        headers.merge!(:"client-id" => options[:client_ref]) if options[:client_ref]

        @stomp_client = Stomp::Client.new(:hosts => [host], :connect_headers => headers)
      end
    end
  end
end
