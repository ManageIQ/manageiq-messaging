module ManageIQ
  module Messaging
    module Stomp
      # Messaging client implementation using Stomp protocol with ActiveMQ Artemis being
      # the underlying supporting system.
      # Do not directly instantiate an instance from this class. Use
      # +ManageIQ::Messaging::Client.open+ method.
      #
      # Artemis specific connection options accepted by +open+ method:
      # * :client_ref (A reference string to identify the client)
      # * :host (Single host name)
      # * :port (host port number)
      # * :username
      # * :password
      # * :heartbeat (Whether the client should do heart-beating. Default to true)
      #
      # Artemis specific +publish_message+ options:
      # * :expires_on
      # * :deliver_on
      # * :priority
      # * :group_name
      #
      # Artemis specific +publish_topic+ options:
      # * :expires_on
      # * :deliver_on
      # * :priority
      #
      # Artemis specific +subscribe_topic+ options:
      # * :persist_ref
      #
      # +:persist_ref+ must be paired with +:client_ref+ option in +Client.open+ method.
      # They jointly create a unique group name. Without such group every topic subscriber
      # receives a copy of each message only when they are active. This is the default.
      # If multiple topic subscribers join with the same group each message is consumed
      # by only one of the subscribers. This allows a load balancing among the subscribers.
      # Also any messages sent when all members of the group are offline will be persisted
      # and delivered when any member in the group is back online. Each message is still
      # copied and delivered to other subscribes belongs to other groups or no group.
      #
      # Artemis specific +subscribe_messages+ options:
      # * :limit ()
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

        attr_accessor :encoding

        private

        attr_reader :stomp_client

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

          @encoding = options[:encoding] || 'yaml'
          require "json" if @encoding == "json"
          @stomp_client = ::Stomp::Client.new(:hosts => [host], :connect_headers => headers)
        end
      end
    end
  end
end
