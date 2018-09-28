module ManageIQ
  module Messaging
    module Kafka
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

        def ack(*_args)
        end

        def close
          @consumer.try(:stop)
          @consumer = nil

          @producer.try(:shutdown)
          @producer = nil

          kafka_client.close
          @kafka_client = nil
        end

        private

        attr_reader :kafka_client

        # @options options :host
        # @options options :hosts (array)
        # @options options :port
        # @options options :group_ref
        # @options options :client_ref (optional)
        # @options options :encoding (default to 'yaml')
        def initialize(options)
          hosts = Array(options[:hosts] || options[:host])
          hosts.collect! { |host| "#{host}:#{options[:port]}" }

          @encoding = options[:encoding] || 'yaml'
          require "json" if @encoding == "json"

          connection_opts = {}
          connection_opts[:client_id] = options[:client_ref] if options[:client_ref]

          @kafka_client = ::Kafka.new(hosts, connection_opts)
        end
      end
    end
  end
end
