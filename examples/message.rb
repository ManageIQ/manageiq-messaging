#!/usr/bin/env ruby

require 'manageiq-messaging'
require_relative "common"

Thread::abort_on_exception = true

class ProducerConsumer < Common
  def run
    ManageIQ::Messaging::Client.open(q_options) do |client|
      puts "producer"
      5.times do |i|
        client.publish_message(
          :service  => 'ems_operation',
          :affinity => 'ems_amazon1',
          :message  => 'power_on',
          :payload  => {
            :ems_ref => 'u987',
            :id      => i.to_s,
          }
        )
      end
      puts "produced 5 messages"

      puts "consumer"
      client.subscribe_messages(:service => 'ems_operation', :affinity => 'ems_amazon1', :auto_ack => false) do |messages|
        messages.each do |msg|
          do_stuff(msg)
          client.ack(msg.ack_ref)
        end
      end
      sleep(5)
      puts "consumed"
    end
  end

  def do_stuff(msg)
    puts "GOT MESSAGE: #{msg.message}: #{msg.payload}"
  end
end

ProducerConsumer.new.parse.run
