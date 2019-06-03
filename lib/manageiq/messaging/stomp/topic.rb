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
            begin
              ack(event) if auto_ack?(options)

              sender = event.headers['sender']
              event_type = event.headers['event_type']
              event_body = decode_body(event.headers, event.body)
              logger.info("Event received: queue(#{queue_name}), event(#{event_body}), headers(#{event.headers})")
              yield ManageIQ::Messaging::ReceivedMessage.new(sender, event_type, event_body, event.headers, event, self)
              logger.info("Event processed")
            rescue => e
              logger.error("Event processing error: #{e.message}")
              logger.error(e.backtrace.join("\n"))
            end
          end
        end
      end
    end
  end
end
