require 'socket'

module ManageIQ
  module Messaging
    module Kafka
      module Topic
        GROUP_FOR_ADHOC_LISTENERS = Socket.gethostname.freeze

        private

        def publish_topic_impl(messages)
          handles = messages.collect { |message| raw_publish(*topic_for_publish(message)) }
          handles.each(&:wait)
        end

        def subscribe_topic_impl(options, &block)
          wait = options.delete(:wait_for_topic)
          wait = true if wait.nil?

          topic = address(options)

          options[:persist_ref] = "#{GROUP_FOR_ADHOC_LISTENERS}_#{Time.now.to_i}" unless options[:persist_ref]

          wait_for_topic(wait) do
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
end
