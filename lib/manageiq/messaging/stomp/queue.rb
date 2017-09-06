module ManageIQ
  module Messaging
    module Stomp
      module Queue
        def publish_message_impl(options, &block)
          address, headers = queue_for_publish(options)
          headers[:sender]         = options[:sender] if options[:sender]
          headers[:message_type]   = options[:message] if options[:message]
          headers[:class_name]     = options[:class_name] if options[:class_name]
          headers[:correlation_id] = Time.now.to_i.to_s if block_given?

          raw_publish(address, options[:payload] || '', headers)

          return unless block_given?

          receive_response(options[:service], headers[:correlation_id], &block)
        end

        def publish_messages_impl(messages)
          messages.each { |msg_options| publish_message(msg_options) }
        end

        def subscribe_messages_impl(options)
          queue_name, headers = queue_for_subscribe(options)

          # for STOMP we can get message one at a time
          subscribe(queue_name, headers) do |msg|
            begin
              sender = msg.headers['sender']
              message_type = msg.headers['message_type']
              message_body = decode_body(msg.headers, msg.body)
              logger.info("Message received: queue(#{queue_name}), msg(#{payload_log(message_body)}), headers(#{msg.headers})")

              result = yield [ManageIQ::Messaging::ReceivedMessage.new(sender, message_type, message_body, msg)]
              logger.info("Message processed")

              correlation_ref = msg.headers['correlation_id']
              if correlation_ref
                result = result.first if result.kind_of?(Array)
                send_response(options[:service], correlation_ref, result)
              end
            rescue => e
              logger.error("Message processing error: #{e.message}")
              logger.error(e.backtrace.join("\n"))
            end
          end
        end
      end
    end
  end
end
