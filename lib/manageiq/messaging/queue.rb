module ManageIQ
  module Messaging
    class Queue
      include Common

      def self.publish(client, options)
        assert_options(options, [:message, :service])

        options = options.dup
        address, headers = queue_for_publish(options)
        headers[:sender] = options.delete(:sender) if options[:sender]
        headers[:message_type] = options.delete(:message_type) if options[:message_type]

        raw_publish(client, address, options[:message], headers)
      end

      def self.subscribe(client, options)
        assert_options(options, [:service])

        options = options.dup
        queue_name, headers = queue_for_subscribe(options)

        client.subscribe(queue_name, headers) do |msg|
          begin
            sender = msg.headers['sender']
            message_type = msg.headers['message_type']
            message_body = decode_body(msg.headers, msg.body)
            logger.info("Message received: queue(#{queue_name}), msg(#{message_body}), headers(#{msg.headers})")
            yield sender, message_type, message_body
            logger.info("Message processed")
          ensure
            client.ack(msg)
          end
        end
      end
    end
  end
end
