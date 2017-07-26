module ManageIQ
  module Messaging
    class Queue
      include Common

      def self.publish(client, options)
        assert_options(options, [:message, :service])

        address, headers = queue_for_publish(options)
        headers[:sender] = options[:sender] if options[:sender]
        headers[:message_type] = options[:message] if options[:message]
        headers[:class_name] = options[:class_name] if options[:class_name]

        raw_publish(client, address, options[:payload] || '', headers)
      end

      def self.publish_batch(client, messages)
        messages.each { |options| publish(client, options) }
      end

      Struct.new("Message", :sender, :message, :payload, :ack_id)

      def self.subscribe(client, options)
        assert_options(options, [:service])

        queue_name, headers = queue_for_subscribe(options)

        # for STOMP we can get message one at a time
        client.subscribe(queue_name, headers) do |msg|
          sender = msg.headers['sender']
          message_type = msg.headers['message_type']
          message_body = decode_body(msg.headers, msg.body)
          logger.info("Message received: queue(#{queue_name}), msg(#{message_body}), headers(#{msg.headers})")

          yield [Struct::Message.new(sender, message_type, message_body, msg)]
          logger.info("Message processed")
        end
      end
    end
  end
end
