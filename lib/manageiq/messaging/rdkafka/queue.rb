module ManageIQ
  module Messaging
    module Rdkafka
      module Queue
        GROUP_FOR_QUEUE_MESSAGES = 'manageiq_messaging_queue_group_'.freeze

        private

        def publish_message_impl(options)
          raise ArgumentError, "Kafka messaging implementation does not take a block" if block_given?
          raw_publish(true, *queue_for_publish(options))
        end

        def publish_messages_impl(messages)
          handles = messages.collect { |msg_options| raw_publish(false, *queue_for_publish(msg_options)) }
          handles.each(&:wait)
        end

        def subscribe_messages_impl(options, &block)
          topic = address(options)
          options[:persist_ref] = GROUP_FOR_QUEUE_MESSAGES + topic

          queue_consumer = consumer(true, options)
          queue_consumer.subscribe(topic)
          queue_consumer.each do |message|
              process_queue_message(queue_consumer, topic, message, &block)
          end
        end
      end
    end
  end
end
