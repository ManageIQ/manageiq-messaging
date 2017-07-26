module ManageIQ
  module Messaging
    class Topic
      include Common

      def self.publish(client, options)
        assert_options(options, [:event, :service])

        address, headers = topic_for_publish(options)
        headers[:sender] = options[:sender] if options[:sender]
        headers[:event_type] = options[:event] if options[:event]

        raw_publish(client, address, options[:payload], headers)
      end

      def self.subscribe(client, options)
        assert_options(options, [:service])

        options = options.dup
        queue_name, headers = topic_for_subscribe(options)

        client.subscribe(queue_name, headers) do |event|
          client.ack(event)
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
