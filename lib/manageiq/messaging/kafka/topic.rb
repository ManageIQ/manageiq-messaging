require 'socket'

module ManageIQ
  module Messaging
    module Kafka
      module Topic
        GROUP_FOR_ADHOC_LISTENERS = Socket.gethostname.freeze

        private

        def publish_topic_impl(options)
          raw_publish(true, *topic_for_publish(options))
        end

        def publish_topic_multi_impl(messages)
          handles = messages.map { |message| raw_publish(false, *topic_for_publish(message)) }
          handles.each(&:wait)
        end

        def subscribe_topic_impl(options, &block)
          topic = address(options)

          options[:persist_ref] = "#{GROUP_FOR_ADHOC_LISTENERS}_#{Time.now.to_i}" unless options[:persist_ref]
          topic_consumer = consumer(false, options)
          topic_consumer.subscribe(topic)
          topic_consumer.each do |message|
            process_topic_message(topic_consumer, topic, message, &block)
          end
        end
      end
    end
  end
end
