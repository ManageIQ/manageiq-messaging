module ManageIQ
  module Messaging
    module Common
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        private

        def raw_publish(client, address, payload, headers)
          unless client
            client = Client.new
            close_on_exit = true
          end

          begin
            client.publish(address, encode_body(headers, payload), headers)
            puts("Address(#{address}), msg(#{payload.inspect}), headers(#{headers.inspect})")
          ensure
            client.close if close_on_exit
          end
        end

        def queue_for_publish(options)
          affinity = options.delete(:affinity) || 'none'
          address = "queue/#{options.delete(:service)}.#{affinity}"

          headers = {:"destination-type" => "ANYCAST"}
          headers[:expires] = options.delete(:expires_on).to_i * 1000 if options[:expires_on]
          headers[:AMQ_SCHEDULED_TIME] = options.delete(:deliver_on).to_i * 1000 if options[:deliver_on]
          headers[:priority] = options.delete(:priority) if options[:priority]

          [address, headers]
        end

        def queue_for_subscribe(options)
          affinity = options.delete(:affinity) || 'none'
          queue_name = "queue/#{options.delete(:service)}.#{affinity}"

          headers = {:"subscription-type" => 'ANYCAST', :ack => 'client'}

          [queue_name, headers]
        end

        def topic_for_publish(options)
          options.delete(:resource)
          address = "topic/#{options.delete(:service)}"

          headers = {:"destination-type" => "MULTICAST"}
          headers[:expires] = options.delete(:expires_on).to_i * 1000 if options[:expires_on]
          headers[:AMQ_SCHEDULED_TIME] = options.delete(:deliver_on).to_i * 1000 if options[:deliver_on]
          headers[:priority] = options.delete(:priority) if options[:priority]

          [address, headers]
        end

        def topic_for_subscribe(options)
          options.delete(:resource)
          queue_name = "topic/#{options.delete(:service)}"

          headers = {:"subscription-type" => 'MULTICAST', :ack => 'client'}
          headers[:"durable-subscription-name"] = options.delete(:persist_id) if options[:persist_id]

          [queue_name, headers]
        end

        def assert_options(options, keys)
          keys.each do |key|
            raise "options must contains key #{key}" if options[key].nil?
          end
        end

        def encode_body(headers, payload)
          return payload if payload.kind_of?(String)
          headers[:encoding] = 'yaml'
          payload.to_yaml
        end

        def decode_body(headers, raw_body)
          return raw_body unless headers['encoding'] == 'yaml'
          YAML.load(raw_body)
        end
      end
    end
  end
end
