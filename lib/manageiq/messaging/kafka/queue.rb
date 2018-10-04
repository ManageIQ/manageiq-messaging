module ManageIQ
  module Messaging
    module Kafka
      module Queue
        private

        def publish_message_impl(options)
          raise ArgumentError, "Kafka messaging implementation does not take a block" if block_given?
          raw_publish(true, *queue_for_publish(options))
        end

        def publish_messages_impl(messages)
          messages.each { |msg_options| raw_publish(false, *queue_for_publish(msg_options)) }
          producer.deliver_messages
        end

        def subscribe_messages_impl(options)
          topic = address(options)

          consumer = queue_consumer
          consumer.subscribe(topic)
          consumer.each_batch do |batch|
            logger.info("Batch message received: queue(#{topic})")
            begin
              messages = batch.messages.collect do |message|
                sender, message_type, _class_name, payload = process_queue_message(topic, message)
                ManageIQ::Messaging::ReceivedMessage.new(sender, message_type, payload, nil)
              end

              yield messages
            rescue StandardError => e
              logger.error("Event processing error: #{e.message}")
              logger.error(e.backtrace.join("\n"))
            end
            logger.info("Batch message processed")
          end
        end
      end
    end
  end
end
