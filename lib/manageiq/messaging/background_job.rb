module ManageIQ
  module Messaging
    class BackgroundJob
      include Common

      def self.publish(client, options)
        assert_options(options, [:class_name, :method_name, :service])

        options = options.dup
        address, headers = queue_for_publish(options)

        raw_publish(client, address, options, headers)
      end

      def self.subscribe(client, options)
        assert_options(options, [:service])

        options = options.dup
        queue_name, headers = queue_for_subscribe(options)

        client.subscribe(queue_name, headers) do |msg|
          begin
            msg_options = decode_body(msg.headers, msg.body)
            logger.info("Processing background job: queue(#{queue_name}), job(#{msg_options.inspect}), headers(#{msg.headers})")
            run_job(msg_options)
            run_job(msg_options[:miq_callback]) if msg_options[:miq_callback]
            logger.info("Background job completed")
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
          ensure
            client.ack(msg)
          end
        end
      end

      def self.run_job(options)
        assert_options(options, [:class_name, :method_name])
        obj = Object.const_get(options[:class_name])
        obj = obj.find(options[:instance_id]) if options[:instance_id]

        msg_timeout = options[:msg_timeout].to_i
        msg_timeout = 600 if msg_timeout.zero?
        Timeout.timeout(msg_timeout) do
          result = obj.send(options[:method_name], *options[:args])
        end
      end
      private_class_method :run_job
    end
  end
end
