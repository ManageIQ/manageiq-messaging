module ManageIQ
  module Messaging
    module Stomp
      class Client < ManageIQ::Messaging::Client
        require 'stomp'
        require 'manageiq/messaging/stomp/common'
        require 'manageiq/messaging/stomp/queue'
        require 'manageiq/messaging/stomp/background_job'
        require 'manageiq/messaging/stomp/topic'

        include Common
        include Queue
        include BackgroundJob
        include Topic

        private *delegate(:subscribe, :unsubscribe, :publish, :to => :stomp_client)
        delegate :ack, :close, :to => :stomp_client

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
          host = options.slice(:host, :port)
          host[:passcode] = options[:password] if options[:password]
          host[:login] = options[:username] if options[:username]

          headers = {}
          if options[:heartbeat].nil? || options[:heartbeat]
            headers.merge!(
              :host             => options[:host],
              :"accept-version" => "1.2",
              :"heart-beat"     => "2000,0"
            )
          end
          headers[:"client-id"] = options[:client_ref] if options[:client_ref]

          @stomp_client = ::Stomp::Client.new(:hosts => [host], :connect_headers => headers)
        end
      end
    end
  end
end
