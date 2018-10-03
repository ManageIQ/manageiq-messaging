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
        # @options options :client_ref (optional)
        # @options options :encoding (default to 'yaml')
        # @options options :ssl_ca_cert, :ssl_client_cert, :ssl_client_cert_key, :sasl_gssapi_principal, :sasl_gssapi_keytab, :sasl_plain_username, :sasl_plain_password, :sasl_scram_username, :sasl_scram_password, :sasl_scram_mechanism
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
