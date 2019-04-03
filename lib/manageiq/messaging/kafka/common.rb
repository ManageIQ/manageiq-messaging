module ManageIQ
  module Messaging
    module Kafka
      module Common
        require 'manageiq/messaging/common'
        include ManageIQ::Messaging::Common

        GROUP_FOR_QUEUE_MESSAGES = 'manageiq_messaging_queue_group_'.freeze

        private

        def producer
          @producer ||= kafka_client.producer
        end

        def topic_consumer(persist_ref, session_timeout = nil)
          # persist_ref enables consumer to receive messages sent when consumer is temporarily offline
          # it also enables consumers to do load balancing when multiple consumers join the with the same ref.
          @topic_consumer.try(:stop) unless @persist_ref == persist_ref
          @persist_ref = persist_ref

          consumer_opts = {:group_id => persist_ref}
          consumer_opts[:session_timeout] = session_timeout if session_timeout.present?

          @topic_consumer ||= kafka_client.consumer(consumer_opts)
        end

        def queue_consumer(topic, session_timeout = nil)
          # all queue consumers join the same group so that each message can be processed by one and only one consumer
          @queue_consumer.try(:stop) unless @queue_topic == topic
          @queue_topic = topic

          consumer_opts = {:group_id => GROUP_FOR_QUEUE_MESSAGES + topic}
          consumer_opts[:session_timeout] = session_timeout if session_timeout.present?

          @queue_consumer ||= kafka_client.consumer(consumer_opts)
        end

        trap("TERM") do
          @topic_consumer.try(:stop)
          @topic_consumer = nil
          @queue_consumer.try(:stop)
          @queue_consumer = nil
        end

        def raw_publish(commit, body, options)
          producer.produce(encode_body(options[:headers], body), options)
          producer.deliver_messages if commit
          logger.info("Published to topic(#{options[:topic]}), msg(#{payload_log(body.inspect)})")
        end

        def queue_for_publish(options)
          body, kafka_opts = for_publish(options)
          kafka_opts[:headers][:message_type] = options[:message] if options[:message]
          kafka_opts[:headers][:class_name] = options[:class_name] if options[:class_name]

          [body, kafka_opts]
        end

        def topic_for_publish(options)
          body, kafka_opts = for_publish(options)
          kafka_opts[:headers][:event_type] = options[:event] if options[:event]

          [body, kafka_opts]
        end

        def for_publish(options)
          kafka_opts = {:topic => address(options), :headers => {}}
          kafka_opts[:partition_key] = options[:group_name] if options[:group_name]
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

        def process_queue_message(queue, message)
          payload = decode_body(message.headers, message.value)
          sender, message_type, class_name = parse_message_headers(message.headers)
          logger.info("Message received: queue(#{queue}), message(#{payload_log(payload)}), sender(#{sender}), type(#{message_type})")
          [sender, message_type, class_name, payload]
        end

        def process_topic_message(topic, message)
          begin
            payload = decode_body(message.headers, message.value)
            sender, event_type = parse_event_headers(message.headers)
            logger.info("Event received: topic(#{topic}), event(#{payload_log(payload)}), sender(#{sender}), type(#{event_type})")
            yield ManageIQ::Messaging::ReceivedMessage.new(sender, event_type, payload, message, self)
            logger.info("Event processed")
          rescue StandardError => e
            logger.error("Event processing error: #{e.message}")
            logger.error(e.backtrace.join("\n"))
          end
        end

        def parse_message_headers(headers)
          return [nil, nil, nil] unless headers.kind_of?(Hash)
          headers.values_at('sender', 'message_type', 'class_name')
        end

        def parse_event_headers(headers)
          return [nil, nil] unless headers.kind_of?(Hash)
          headers.values_at('sender', 'event_type')
        end
      end
    end
  end
end
