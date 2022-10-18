module ManageIQ
  module Messaging
    module Kafka
      module Queue
        GROUP_FOR_QUEUE_MESSAGES = ENV['QUEUE_MESSAGES_GROUP_PREFIX'].freeze || 'manageiq_messaging_queue_group_'.freeze

        private

        def publish_message_impl(options)
          raise ArgumentError, "Kafka messaging implementation does not take a block" if block_given?
          raw_publish(*queue_for_publish(options)).wait
        end

        def publish_messages_impl(messages)
          handles = messages.collect { |msg_options| raw_publish(*queue_for_publish(msg_options)) }
          handles.each(&:wait)
        end

        def subscribe_messages_impl(options, &block)
          wait = options.delete(:wait_for_topic)
          wait = true if wait.nil?

          topic = address(options)
          options[:persist_ref] = GROUP_FOR_QUEUE_MESSAGES + topic

          wait_for_topic(wait) do
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
end
