module ManageIQ
  module Messaging
    module Stomp
      module Common
        require 'manageiq/messaging/common'
        include ManageIQ::Messaging::Common

        private

        def raw_publish(address, body, headers)
          publish(address, encode_body(headers, body), headers)
          logger.info("Published to address(#{address}), msg(#{payload_log(body.inspect)}), headers(#{headers.inspect})")
        end

        def queue_for_publish(options)
          affinity = options[:affinity] || 'none'
          address = "queue/#{options[:service]}.#{affinity}"

          headers = {:"destination-type" => 'ANYCAST', :persistent => true}
          headers[:expires]            = options[:expires_on].to_i * 1000 if options[:expires_on]
          headers[:AMQ_SCHEDULED_TIME] = options[:deliver_on].to_i * 1000 if options[:deliver_on]
          headers[:priority]           = options[:priority] if options[:priority]
          headers[:_AMQ_GROUP_ID]      = options[:group_name] if options[:group_name]

          [address, headers]
        end

        def queue_for_subscribe(options)
          affinity = options[:affinity] || 'none'
          queue_name = "queue/#{options[:service]}.#{affinity}"

          headers = {:"subscription-type" => 'ANYCAST', :ack => 'client'}

          [queue_name, headers]
        end

        def topic_for_publish(options)
          address = "topic/#{options[:service]}"

          headers = {:"destination-type" => 'MULTICAST', :persistent => true}
          headers[:expires]            = options[:expires_on].to_i * 1000 if options[:expires_on]
          headers[:AMQ_SCHEDULED_TIME] = options[:deliver_on].to_i * 1000 if options[:deliver_on]
          headers[:priority]           = options[:priority] if options[:priority]

          [address, headers]
        end

        def topic_for_subscribe(options)
          queue_name = "topic/#{options[:service]}"

          headers = {:"subscription-type" => 'MULTICAST', :ack => 'client'}
          headers[:"durable-subscription-name"] = options[:persist_ref] if options[:persist_ref]

          [queue_name, headers]
        end

        def send_response(service, correlation_ref, result)
          response_options = {
            :service  => "#{service}.response",
            :affinity => correlation_ref
          }
          address, response_headers = queue_for_publish(response_options)
          raw_publish(address, result || '', response_headers.merge(:correlation_id => correlation_ref))
        end

        def receive_response(service, correlation_ref)
          response_options = {
            :service  => "#{service}.response",
            :affinity => correlation_ref
          }
          queue_name, response_headers = queue_for_subscribe(response_options)
          subscribe(queue_name, response_headers) do |msg|
            ack(msg)
            begin
              yield decode_body(msg.headers, msg.body)
            ensure
              unsubscribe(queue_name)
            end
          end
        end
      end
    end
  end
end
