module ManageIQ
  module Messaging
    class Client
      def self.open(options)
        StompClient.new(options)
      end

      def publish_background_job(options)
        BackgroundJob.push(self, options)
      end

      def subscribe_background_job(options)
        BackgroundJob.subscribe(self, options)
      end

      def publish_queue(options)
        Queue.publish(self, options)
      end

      def subscribe_queue(options, &block)
        raise "A block is required" unless block_given?

        Queue.subscribe(self, options, &block)
      end

      def publish_topic(options)
        Topic.publish(self, options)
      end

      def subscribe_topic(options, &block)
        raise "A block is required" unless block_given?

        Topic.subscribe(self, options, &block)
      end
    end
  end
end
