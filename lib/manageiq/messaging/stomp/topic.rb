module ManageIQ
  module Messaging
    module Stomp
      module Topic
        private

        def publish_topic_impl(options)
          address, headers = topic_for_publish(options)
          headers[:sender] = options[:sender] if options[:sender]
          headers[:event_type] = options[:event] if options[:event]

          raw_publish(address, options[:payload], headers)
        end

        def subscribe_topic_impl(options)
          queue_name, headers = topic_for_subscribe(options)

          subscribe(queue_name, headers) do |event|
            ack(event)
            begin
              sender = event.headers['sender']
              event_type = event.headers['event_type']
              event_body = decode_body(event.headers, event.body)
              logger.info("Event received: queue(#{queue_name}), event(#{event_body}), headers(#{event.headers})")
              yield sender, event_type, event_body
              logger.info("Event processed")
            end
          end
        end
      end
    end
  end
end
