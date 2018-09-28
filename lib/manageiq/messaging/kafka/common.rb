module ManageIQ
  module Messaging
    module Kafka
      module Common
        GROUP_FOR_QUEUE_MESSAGES = 'manageiq_messaging_queue_group'.freeze

        private

        def producer
          @producer ||= kafka_client.producer
        end

        def topic_consumer(group_ref)
          @consumer.try(:stop) unless @group_ref == group_ref
          @group_ref = group_ref
          @topic_consumer ||= kafka_client.consumer(:group_id => group_ref)
        end

        def queue_consumer
          # all queue consumers join the same group so that each message can be processed by one and only one consumer
          @queue_consumer ||= kafka_client.consumer(:group_id => GROUP_FOR_QUEUE_MESSAGES)
        end

        trap("TERM") do
          @consumer.try(:stop)
          @consumer = nil
        end

        def raw_publish(commit, body, options)
          producer.produce(encode_body(body), options)
          producer.deliver_messages if commit
          logger.info("Published to topic(#{options[:topic]}), msg(#{payload_log(body[:data].inspect)})")
        end

        def queue_for_publish(options)
          body, kafka_opts = for_publish(options)
          body[:message_type] = options[:message] if options[:message]
          body[:class_name] = options[:class_name] if options[:class_name]

          [body, kafka_opts]
        end

        def topic_for_publish(options)
          body, kafka_opts = for_publish(options)
          body[:event_type] = options[:event] if options[:event]

          [body, kafka_opts]
        end

        def for_publish(options)
          kafka_opts = {:topic => options[:service]}
          kafka_opts[:partition_key] = options[:affinity] if options[:affinity]

          body = {:payload => options[:payload] || ''}
          body[:sender] = options[:sender] if options[:sender]

          [body, kafka_opts]
        end

        def process_queue_message(queue, message)
          queue_message = decode_body(message.value)
          sender, message_type, class_name, payload = parse_message(queue_message)
          logger.info("Message received: queue(#{queue}), message(#{payload_log(payload)}), sender(#{sender}), type(#{message_type})")
          [sender, message_type, class_name, payload]
        end

        def process_topic_message(topic, message)
          begin
            event = decode_body(message.value)
            sender, event_type, payload = parse_event(event)
            logger.info("Event received: topic(#{topic}), event(#{payload_log(payload)}), sender(#{sender}), type(#{event_type})")
            yield sender, event_type, payload
            logger.info("Event processed")
          rescue StandardError => e
            logger.error("Event processing error: #{e.message}")
            logger.error(e.backtrace.join("\n"))
          end
        end

        def parse_message(message)
          return [nil, nil, nil, message] unless message.kind_of?(Hash)
          message.values_at('sender', 'message_type', 'class_name', 'payload')
        end

        def parse_event(event)
          return [nil, nil, event] unless event.kind_of?(Hash)
          event.values_at('sender', 'event_type', 'payload')
        end

        def encode_body(body)
          body[:encoding] = encoding
          case encoding
          when 'json'
            JSON.generate(body)
          when 'yaml'
            body.stringify_keys.to_yaml
          else
            raise "unknown message encoding: #{encoding}"
          end
        end

        def decode_body(raw_body)
          if raw_body.lstrip.start_with?('{')
            parsed = JSON.parse(raw_body)
            return raw_body unless parsed.key?('payload') && parsed['encoding'] == 'json'
          else
            parsed = YAML.safe_load(raw_body)
            return raw_body unless parsed.key?('payload') && parsed['encoding'] == 'yaml'
          end
          parsed
        rescue StandardError
          raw_body
        end

        def payload_log(payload)
          payload.to_s[0..100]
        end
      end
    end
  end
end
