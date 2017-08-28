if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "manageiq/messaging"

module ManageIQ::Messaging::Test
  class Client < ManageIQ::Messaging::Client
    def initialize(options); end
    def close; end
    def publish_message_impl(args); end
    def publish_topic_impl(args); end
    def publish_messages_impl(args); end
    def subscribe_messages_impl(args); end
    def subscribe_topic_impl(args); end
    def subscribe_background_job_impl(args); end
  end
end
