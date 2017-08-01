module ManageIQ
  module Messaging
    module Stomp
      module BackgroundJob
        private

        def subscribe_background_job_impl(options)
          queue_name, headers = queue_for_subscribe(options)

          subscribe(queue_name, headers) do |msg|
            ack(msg)
            begin
              assert_options(msg.headers, ['class_name', 'message_type'])

              msg_options = decode_body(msg.headers, msg.body)
              msg_options = {} if msg_options.empty?
              logger.info("Processing background job: queue(#{queue_name}), job(#{msg_options.inspect}), headers(#{msg.headers})")
              result = run_job(msg_options.merge(:class_name => msg.headers['class_name'], :method_name => msg.headers['message_type']))
              logger.info("Background job completed")

              correlation_ref = msg.headers['correlation_id']
              send_response(options[:service], correlation_ref, result) if correlation_ref
            rescue Timeout::Error
              logger.warn("Background job timed out")
              if Object.const_defined?('ActiveRecord::Base')
                begin
                  logger.info("Reconnecting to DB after timeout error during queue deliver")
                  ActiveRecord::Base.connection.reconnect!
                rescue => err
                  logger.error("Error encountered during <ActiveRecord::Base.connection.reconnect!> error:#{err.class.name}: #{err.message}")
                end
              end
            end
          end
        end

        def run_job(options)
          assert_options(options, [:class_name, :method_name])

          instance_id = options[:instance_id]
          args = options[:args]
          miq_callback = options[:miq_callback]

          obj = Object.const_get(options[:class_name])
          obj = obj.find(instance_id) if instance_id

          msg_timeout = 600 # TODO: configurable per message
          result = Timeout.timeout(msg_timeout) do
            obj.send(options[:method_name], *args)
          end

          run_job(miq_callback) if miq_callback
          result
        end
      end
    end
  end
end
