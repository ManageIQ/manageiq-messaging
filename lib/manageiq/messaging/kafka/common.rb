module ManageIQ
  module Messaging
    module Kafka
      module Common
        require 'manageiq/messaging/common'
        include ManageIQ::Messaging::Common

        private

        def producer
          @producer ||= kafka_client.producer
        end

        def consumer(beginning, options)
          @consumer&.close
          kafka_client[:"group.id"] = options[:persist_ref]
          kafka_client[:"auto.offset.reset"] = beginning ? 'smallest' : 'largest'
          kafka_client[:"enable.auto.commit"] = !!auto_ack?(options)
          kafka_client[:"session.timeout.ms"] = options[:session_timeout] * 1000 if options[:session_timeout].present?
          kafka_client[:"group.instance.id"] = options[:group_instance_id] if options[:group_instance_id].present?
          @consumer = kafka_client.consumer
        end

        def raw_publish(wait, body, options)
          options[:payload] = encode_body(options[:headers], body)
          producer.produce(options).tap do |handle|
            handle.wait if wait
            logger.info("Published to topic(#{options[:topic]}), msg(#{payload_log(body.inspect)})")
          end
        end

        def queue_for_publish(options)
          body, kafka_opts = for_publish(options)
          kafka_opts[:headers][:message_type] = options[:message] if options[:message]
          kafka_opts[:headers][:class_name] = options[:class_name] if options[:class_name]
          kafka_opts[:headers].merge!(options[:headers].except(*message_header_keys)) if options.key?(:headers)

          [body, kafka_opts]
        end

        def topic_for_publish(options)
          body, kafka_opts = for_publish(options)
          kafka_opts[:headers][:event_type] = options[:event] if options[:event]
          kafka_opts[:headers].merge!(options[:headers].except(*event_header_keys)) if options.key?(:headers)

          [body, kafka_opts]
        end

        def for_publish(options)
          kafka_opts = {:topic => address(options)}
          kafka_opts[:partition_key] = options[:group_name] if options[:group_name]
          kafka_opts[:headers] = {}
          kafka_opts[:headers][:sender] = options[:sender] if options[:sender]

          body = options[:payload] || ''

          [body, kafka_opts]
        end

        def address(options)
          if options[:affinity]
            "#{options[:service]}.#{options[:affinity]}"
          else
            options[:service]
          end
        end

        def process_queue_message(queue_consumer, queue, message)
          begin
            payload = decode_body(message.headers, message.payload)
            sender, message_type, _class_name = parse_message_headers(message.headers)
            client_headers = message.headers.except(*message_header_keys).with_indifferent_access

            logger.info("Message received: queue(#{queue}), message(#{payload_log(payload)}), sender(#{sender}), type(#{message_type})")
            yield [ManageIQ::Messaging::ReceivedMessage.new(sender, message_type, payload, client_headers, queue_consumer, self)]
            logger.info("Messsage processed")
          rescue StandardError => e
            logger.error("Message processing error: #{e.message}")
            logger.error(e.backtrace.join("\n"))
            raise
          end
        end

        def process_topic_message(topic_consumer, topic, message)
          begin
            payload = decode_body(message.headers, message.payload)
            sender, event_type = parse_event_headers(message.headers)
            client_headers = message.headers.except(*event_header_keys).with_indifferent_access

            logger.info("Event received: topic(#{topic}), event(#{payload_log(payload)}), sender(#{sender}), type(#{event_type})")
            yield ManageIQ::Messaging::ReceivedMessage.new(sender, event_type, payload, client_headers, topic_consumer, self)
            logger.info("Event processed")
          rescue StandardError => e
            logger.error("Event processing error: #{e.message}")
            logger.error(e.backtrace.join("\n"))
            raise
          end
        end

        def message_header_keys
          [:sender, :message_type, :class_name]
        end

        def parse_message_headers(headers)
          return [nil, nil, nil] unless headers.kind_of?(Hash)
          headers.values_at(*message_header_keys)
        end

        def event_header_keys
          [:sender, :event_type]
        end

        def parse_event_headers(headers)
          return [nil, nil] unless headers.kind_of?(Hash)
          headers.values_at(*event_header_keys)
        end
      end
    end
  end
end
