require 'active_support/core_ext/module/delegation'
require 'yaml'
require 'stomp'

module ManageIQ
  module Messaging
    # Your code goes here...
  end
end

require 'manageiq/messaging/version'
require 'manageiq/messaging/common'
require 'manageiq/messaging/client'
require 'manageiq/messaging/queue'
require 'manageiq/messaging/topic'
require 'manageiq/messaging/background_job'
