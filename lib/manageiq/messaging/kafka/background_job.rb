module ManageIQ
  module Messaging
    module Kafka
      module BackgroundJob
        private

        def subscribe_background_job_impl(_options)
          raise NotImplementedError
        end
      end
    end
  end
end
