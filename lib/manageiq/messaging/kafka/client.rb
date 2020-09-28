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
          @producer&.close
          @producer = nil

          @consumer&.close
          @consumer = nil
        end

        # list all topics
        def topics
          native_kafka = producer.instance_variable_get(:@native_kafka)
          Rdkafka::Metadata.new(native_kafka).topics.collect { |topic| topic[:topic_name] }
        end

        private

        attr_reader :kafka_client

        def initialize(options)
          hosts = Array(options[:hosts] || options[:host])
          hosts.collect! { |host| "#{host}:#{options[:port]}" }

          @encoding = options[:encoding] || 'yaml'
          require "json" if @encoding == "json"

          connection_opts = {:"bootstrap.servers" => hosts.join(',')}
          connection_opts[:"client.id"] = options[:client_ref] if options[:client_ref]

          ::Rdkafka::Config.logger = logger
          @kafka_client = ::Rdkafka::Config.new(connection_opts)
        end
      end
    end
  end
end
