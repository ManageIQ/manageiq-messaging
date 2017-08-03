module ManageIQ
  module Messaging
    class ReceivedMessage
      attr_accessor :sender, :message, :payload, :ack_ref

      def initialize(sender, message, payload, ack_ref)
        @sender, @message, @payload, @ack_ref = sender, message, payload, ack_ref
      end
    end
  end
end
