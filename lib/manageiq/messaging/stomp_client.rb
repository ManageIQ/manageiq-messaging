module ManageIQ
  module Messaging
    class StompClient < Client
      delegate :subscribe, :to => :stomp_client
      delegate :publish,   :to => :stomp_client
      delegate :close,     :to => :stomp_client
      delegate :ack,       :to => :stomp_client

      private
      attr_reader :stomp_client

      # options
      #   :hosts (array of)
      #     :host
      #     :login
      #     :passcode
      #     :port
      #   :client_id (optional)
      #   :heartbeat  (default to true)
      def initialize(options)
        hosts = options[:hosts]
        headers = {}
        headers.merge!(:host => hosts[0][:host], :"accept-version" => "1.2", :"heart-beat" => "2000,0") if options[:heartbeat]
        headers.merge!(:"client-id" => options[:client_id]) if options[:client_id]

        @stomp_client = Stomp::Client.new(:hosts => hosts, :connect_headers => headers)
      end
    end
  end
end
