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
      #
      # For additional security options, please refer to
      # https://github.com/edenhill/librdkafka/wiki/Using-SSL-with-librdkafka and
      # https://github.com/edenhill/librdkafka/wiki/Using-SASL-with-librdkafka
      #
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
        require 'rdkafka'
        require 'manageiq/messaging/kafka/common'
        require 'manageiq/messaging/kafka/queue'
        require 'manageiq/messaging/kafka/background_job'
        require 'manageiq/messaging/kafka/topic'

        include Common
        include Queue
        include BackgroundJob
        include Topic

        attr_accessor :encoding

        def ack(ack_ref)
          ack_ref.commit
        rescue Rdkafka::RdkafkaError => e
          logger.warn("ack failed with error #{e.message}")
          raise unless e.message =~ /no_offset/
        end

        def close
          @admin&.close
          @admin = nil

          @producer&.close
          @producer = nil

          @consumer&.close
          @consumer = nil
        end

        # list all topics
        def topics
          admin.metadata.topics.map { |topic| topic[:topic_name] }
        end

        private

        attr_reader :kafka_client

        def initialize(options)
          @encoding = options[:encoding] || 'yaml'
          require "json" if @encoding == "json"

          ::Rdkafka::Config.logger = logger
          @kafka_client = ::Rdkafka::Config.new(rdkafka_connection_opts(options))
        end

        def rdkafka_connection_opts(options)
          hosts = Array(options[:hosts] || options[:host])
          hosts.collect! { |host| "#{host}:#{options[:port]}" }

          result = {:"bootstrap.servers" => hosts.join(',')}
          result[:"client.id"] = options[:client_ref] if options[:client_ref]

          result[:"sasl.mechanism"]    = options[:sasl_mechanism] || "PLAIN"
          result[:"sasl.username"]     = options[:username] if options[:username]
          result[:"sasl.password"]     = options[:password] if options[:password]
          result[:"security.protocol"] = !!options[:ssl] ? "SASL_SSL" : "PLAINTEXT"
          result[:"ssl.ca.location"]   = options[:ca_file] if options[:ca_file]
          result[:"ssl.keystore.location"] = options[:keystore_location] if options[:keystore_location]
          result[:"ssl.keystore.password"] = options[:keystore_password] if options[:keystore_password]

          result.merge(options.except(:port, :host, :hosts, :encoding, :protocol, :client_ref, :sasl_mechanism, :username, :password, :ssl, :ca_file, :keystore_location, :keystore_password))
        end
      end
    end
  end
end
