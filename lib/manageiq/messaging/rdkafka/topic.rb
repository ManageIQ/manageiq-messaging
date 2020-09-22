module ManageIQ
  module Messaging
    module Rdkafka
      module Topic
        GROUP_FOR_ADHOC_LISTENERS = 'manageiq_messaging_topic_group_'.freeze

        private

        def publish_topic_impl(options)
          raw_publish(true, *topic_for_publish(options))
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
