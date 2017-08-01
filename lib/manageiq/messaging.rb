require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/hash'
require 'yaml'

require 'manageiq/messaging/null_logger'

module ManageIQ
  module Messaging
    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= NullLogger.new
    end
  end
end

require 'manageiq/messaging/version'
require 'manageiq/messaging/client'
require 'manageiq/messaging/received_message'
