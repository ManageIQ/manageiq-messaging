module ManageIQ
  module Messaging
    class Client
      delegate :subscribe, :to => :stomp_client
      delegate :publish,   :to => :stomp_client
      delegate :close,     :to => :stomp_client
      delegate :ack,       :to => :stomp_client

      private
      attr_reader :stomp_client

      def initialize(long_live = false, options = {})
        # TODO: need to be able to configure host
        hosts = [{:login => "admin", :passcode => "smartvm", :host => "127.0.0.1", :port => 61613}]
        headers = {}
        headers.merge!(:host => "127.0.0.1", :"accept-version" => "1.2", :"heart-beat" => "2000,0") if long_live
        headers.merge!(:"client-id" => options[:client_id]) if options[:client_id]

        @stomp_client = Stomp::Client.new(:hosts => hosts, :connect_headers => headers)
      end
    end
  end
end
