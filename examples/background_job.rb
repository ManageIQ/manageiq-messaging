#!/usr/bin/env ruby

require 'manageiq-messaging'
require_relative "common"

Thread::abort_on_exception = true

class ProducerConsumer < Common
  SERVICE_NAME = "prodcom"
  def run
    ManageIQ::Messaging::Client.open(q_options) do |client|
      puts "producer"
      5.times do |i|
        client.publish_message(:service    => SERVICE_NAME,
                               :class_name => self.class.name,
                               :message    => 'do_stuff',
                               :payload    => {:args=>["hello#{i}"]}
                              )
      end
      puts "produced 5 jobs"

      # this could be a different client
      puts "consumer"
      client.subscribe_background_job(:service => SERVICE_NAME)

      sleep(5) # wait for consumer to consume all
      puts "consumed"
    end
  end

  def self.do_stuff(args)
    puts "GOT MESSAGE: do_stuff(#{args.inspect})"
  end
end

ProducerConsumer.new.parse.run
