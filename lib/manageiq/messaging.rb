require 'active_support/core_ext/module/delegation'
require 'yaml'
require 'stomp'

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
require 'manageiq/messaging/common'
require 'manageiq/messaging/client'
require 'manageiq/messaging/stomp_client'
require 'manageiq/messaging/queue'
require 'manageiq/messaging/topic'
require 'manageiq/messaging/background_job'
