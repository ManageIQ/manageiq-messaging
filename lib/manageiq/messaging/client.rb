module ManageIQ
  module Messaging
    # The abstract client class. It defines methods needed to publish or subscribe messages.
    # It is not recommended to directly create a solid subclass instance. The proper way is
    # to call class method +Client.open+ with desired protocol. For example:
    #
    #   client = ManageIQ::Messaging::Client.open(
    #     :protocol  => 'Stomp',
    #     :host       => 'localhost',
    #     :port       => 61616,
    #     :password   => 'smartvm',
    #     :username   => 'admin',
    #     :client_ref => 'generic_1',
    #     :encoding   => 'json'
    #   )
    #
    # To close the connection one needs to explicitly call +client.close+.
    # Alternatively if a block is given for the +open+ method, the connection will be closed
    # automatically before existing the block. For example:
    #
    #   ManageIQ::Messaging::Client.open(
    #     :protocol   => 'Stomp'
    #     :host       => 'localhost',
    #     :port       => 61616,
    #     :password   => 'smartvm',
    #     :username   => 'admin',
    #     :client_ref => 'generic_1'
    #   ) do |client|
    #     # do stuff with the client
    #     end
    #   end
    class Client
      # Open or create a connection to the message broker.
      # Expected +options+ keys are:
      # * :protocol (Implemented: 'Stomp', 'Kafka'. Default 'Stomp')
      # * :encoding ('yaml' or 'json'. Default 'yaml')
      # Other connection options are underlying messaging system specific.
      #
      # Returns a +Client+ instance if no block is given.
      def self.open(options)
        protocol = options[:protocol] || :Stomp
        client = Object.const_get("ManageIQ::Messaging::#{protocol}::Client").new(options)
        return client unless block_given?

        begin
          yield client
        ensure
          client.close
        end
        nil
      end

      # Publish a message to a queue. The message will be delivered to only one subscriber.
      # Expected keys in +options+ are:
      # * :service    (service and affinity are used to determine the queue name)
      # * :affinity   (optional)
      # * :class_name (optional)
      # * :message    (e.g. method name or message type)
      # * :payload    (message body, a string or an user object that can be serialized)
      # * :sender     (optional, identify the sender)
      # * :headers    (optional, additional headers to add to the message)
      # Other options are underlying messaging system specific.
      #
      # Optionally a call back block can be provided to wait on the consumer to send
      # an acknowledgment. Not every underlying messaging system supports callback.
      # Example:
      #
      #   client.publish_message(
      #     :service  => 'ems_operation',
      #     :affinity => 'ems_amazon1',
      #     :message  => 'power_on',
      #     :payload  => {
      #       :ems_ref => 'u987',
      #       :id      => '123'
      #     }
      #   ) do |result|
      #     ansible_install_pkg(vm1) if result == 'running'
      #   end
      def publish_message(options, &block)
        assert_options(options, [:message, :service])

        publish_message_impl(options, &block)
      end

      # Publish multiple messages to a queue.
      # An aggregate version of +#publish_message+ but for better performance.
      # All messages are sent in a batch. Every element in +messages+ array is
      # an +options+ hash.
      #
      def publish_messages(messages)
        publish_messages_impl(messages)
      end

      # Subscribe to receive messages from a queue.
      # Expected keys in +options+ are:
      # * :service  (service and affinity are used to determine the queue)
      # * :affinity (optional)
      # * :auto_ack (default true, if it is false, client.ack method must be explicitly called)
      # Other options are underlying messaging system specific.
      #
      # A callback block is needed to consume the messages:
      #
      #   client.subscribe_message(options) do |messages|
      #     messages.each do |msg|
      #       # msg is a type of ManageIQ::Messaging::ReceivedMessage
      #       # attributes in msg
      #       msg.sender
      #       msg.message
      #       msg.payload
      #       msg.ack_ref
      #
      #       msg.ack # needed only when options[:auto_ack] is false
      #       # process the message
      #     end
      #   end
      #
      # With the auto_ack option default to true, the message will be automatically
      # acked immediately after the delivery.
      # Some messaging systems allow the subscriber to ack each message in the
      # callback block. The code in the block can decide when to ack according
      # to whether a message can be retried. Ack the message in the beginning of
      # processing if the message is not re-triable; otherwise ack it after the
      # message is proccessed. Any un-acked message will be redelivered to next subscriber
      # AFTER the current subscriber disconnects normally or abnormally (e.g. crashed).
      #
      # To ack a message call +msg.ack+
      def subscribe_messages(options, &block)
        raise "A block is required" unless block_given?
        assert_options(options, [:service])

        subscribe_messages_impl(options, &block)
      end

      # Subscribe to receive from a queue and run each message as a background job.
      # Expected keys in +options+ are:
      # * :service  (service and affinity are used to determine the queue)
      # * :affinity (optional)
      # * :auto_ack (default true, if it is false, client.ack method must be explicitly called)
      # Other options are underlying messaging system specific.
      #
      # This subscriber consumes messages sent through +publish_message+ with required
      # +options+ keys, for example:
      #
      #     client.publish_message(
      #       :service    => 'generic',
      #       :class_name => 'MiqTask',
      #       :message    => 'update_attributes', # method name, for instance method :instance_id is required
      #       :payload    => {
      #         :instance_id => 2, # database id of class instance stored in rails DB
      #         :args        => [{:status => 'Timeout'}] # argument list expected by the method
      #       }
      #     )
      #
      # Background job assumes each job is not re-triable. It is auto-acked as soon as a request
      # is received
      def subscribe_background_job(options)
        assert_options(options, [:service])

        subscribe_background_job_impl(options)
      end

      # Publish a message as a topic. All subscribers will receive a copy of the message.
      # Expected keys in +options+ are:
      # * :service (service is used to determine the topic address)
      # * :event   (event name)
      # * :payload (message body, a string or an user object that can be serialized)
      # * :sender  (optional, identify the sender)
      # * :headers (optional, additional headers to add to the message)
      # Other options are underlying messaging system specific.
      #
      def publish_topic(options)
        assert_options(options, [:event, :service])

        publish_topic_impl(options)
      end

      # Subscribe to receive topic type messages.
      # Expected keys in +options+ are:
      # * :service (service is used to determine the topic address)
      # Other options are underlying messaging system specific.
      #
      # Some messaging systems allow subscribers to consume events missed during the period when
      # the client is offline when they reconnect. Additional options are needed to turn on
      # this feature.
      #
      # A callback block is needed to consume the topic:
      #
      #   client.subcribe_topic(:service => 'provider_events', :auto_ack => false) do |msg|
      #     # msg is a type of ManageIQ::Messaging::ReceivedMessage
      #     # attributes in msg
      #     msg.sender
      #     msg.message
      #     msg.payload
      #     msg.ack_ref
      #
      #     msg.ack # needed only when options[:auto_ack] is false
      #     # process the message
      #   end
      #
      # With the auto_ack option default to true, the message will be automatically
      # acked immediately after the delivery.
      # Some messaging systems allow the subscriber to ack each message in the
      # callback block. The code in the block can decide when to ack according
      # to whether a message can be retried. Ack the message in the beginning of
      # processing if the message is not re-triable; otherwise ack it after the
      # message is proccessed. Any un-acked message will be redelivered to next subscriber
      # AFTER the current subscriber disconnects normally or abnormally (e.g. crashed).
      #
      # To ack a message call +msg.ack+
      def subscribe_topic(options, &block)
        raise "A block is required" unless block_given?
        assert_options(options, [:service])

        subscribe_topic_impl(options, &block)
      end

      private

      def logger
        ManageIQ::Messaging.logger
      end

      def assert_options(options, keys)
        missing = keys - options.keys
        raise ArgumentError, "options must contain keys #{missing}" unless missing.empty?
      end
    end
  end
end
