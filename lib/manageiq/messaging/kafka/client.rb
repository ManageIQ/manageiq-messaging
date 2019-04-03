module ManageIQ
  module Messaging
    module Kafka
      # Messaging client implementation with Kafka being the underlying supporting system.
      # Do not directly instantiate an instance from this class. Use
      # +ManageIQ::Messaging::Client.open+ method.
      #
      # Kafka specific connection options accepted by +open+ method:
      # * :client_ref (A reference string to identify the client)
      # * :hosts (Array of Kafka cluster hosts, or)
      # * :host (Single host name)
      # * :port (host port number)
      # * :ssl_ca_cert (security options)
      # * :ssl_client_cert
      # * :ssl_client_cert_key
      # * :sasl_gssapi_principal
      # * :sasl_gssapi_keytab
      # * :sasl_plain_username
      # * :sasl_plain_password
      # * :sasl_scram_username
      # * :sasl_scram_password
      # * :sasl_scram_mechanism
      #
      # Kafka specific +publish_message+ options:
      # * :group_name (Used as Kafka partition_key)
      #
      # Kafka specific +subscribe_topic+ options:
      # * :persist_ref (Used as Kafka group_id)
      # * :session_timeout (Max time in seconds allowed to process a message, default is 30)
      #
      # Kafka specific +subscribe_messages+ options:
      # * :max_bytes (Max batch size to read, default is 10Mb)
      # * :session_timeout (Max time in seconds allowed to process a message, default is 30)
      #
      # Without +:persist_ref+ every topic subscriber receives a copy of each message
      # only when they are active. If multiple topic subscribers join with the same
      # +:persist_ref+, each message is consumed by only one of the subscribers. This
      # allows a load balancing among the subscribers. Also any messages sent when
      # all members of the +:persist_ref+ group are offline will be persisted and delivered
      # when any member in the group is back online. Each message is still copied and
      # delivered to other subscribers that belongs to other +:persist_ref+ groups or no group.
      #
      # +subscribe_background_job+ is currently not implemented.
      class Client < ManageIQ::Messaging::Client
        require 'kafka'
        require 'manageiq/messaging/kafka/common'
        require 'manageiq/messaging/kafka/queue'
        require 'manageiq/messaging/kafka/background_job'
        require 'manageiq/messaging/kafka/topic'

        include Common
        include Queue
        include BackgroundJob
        include Topic

        private *delegate(:subscribe, :unsubscribe, :publish, :to => :kafka_client)
        delegate :close, :to => :kafka_client

        attr_accessor :encoding

        def ack(ack_ref)
          @queue_consumer.try(:mark_message_as_processed, ack_ref)
          @topic_consumer.try(:mark_message_as_processed, ack_ref)
        end

        def close
          @topic_consumer.try(:stop)
          @topic_consumer = nil
          @queue_consumer.try(:stop)
          @queue_consumer = nil

          @producer.try(:shutdown)
          @producer = nil

          kafka_client.close
          @kafka_client = nil
        end

        private

        attr_reader :kafka_client

        def initialize(options)
          hosts = Array(options[:hosts] || options[:host])
          hosts.collect! { |host| "#{host}:#{options[:port]}" }

          @encoding = options[:encoding] || 'yaml'
          require "json" if @encoding == "json"

          connection_opts = {}
          connection_opts[:client_id] = options[:client_ref] if options[:client_ref]

          connection_opts.merge!(options.slice(:ssl_ca_cert, :ssl_client_cert, :ssl_client_cert_key, :sasl_gssapi_principal, :sasl_gssapi_keytab, :sasl_plain_username, :sasl_plain_password, :sasl_scram_username, :sasl_scram_password, :sasl_scram_mechanism))

          @kafka_client = ::Kafka.new(hosts, connection_opts)
        end
      end
    end
  end
end
