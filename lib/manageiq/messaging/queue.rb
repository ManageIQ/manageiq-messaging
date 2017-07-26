module ManageIQ
  module Messaging
    class Queue
      include Common

      def self.publish(client, options, &block)
        assert_options(options, [:message, :service])

        address, headers = queue_for_publish(options)
        headers[:sender] = options[:sender] if options[:sender]
        headers[:message_type] = options[:message] if options[:message]
        headers[:class_name] = options[:class_name] if options[:class_name]
        headers[:correlation_id] = Time.now.to_i.to_s if block_given?

        raw_publish(client, address, options[:payload] || '', headers)

        return unless block_given?

        receive_response(client, options[:service], headers[:correlation_id], &block)
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

          result = yield [Struct::Message.new(sender, message_type, message_body, msg)]
          logger.info("Message processed")

          correlation_id = msg.headers['correlation_id']
          send_response(client, options[:service], correlation_id, result) if correlation_id
        end
      end
    end
  end
end
