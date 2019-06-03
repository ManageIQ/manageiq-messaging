# ManageIQ Messaging Client

[![Gem Version](https://badge.fury.io/rb/manageiq-messaging.svg)](http://badge.fury.io/rb/manageiq-messaging)
[![Build Status](https://travis-ci.org/ManageIQ/manageiq-messaging.svg)](https://travis-ci.org/ManageIQ/manageiq-messaging)
[![Code Climate](https://codeclimate.com/github/ManageIQ/manageiq-messaging.svg)](https://codeclimate.com/github/ManageIQ/manageiq-messaging)
[![Test Coverage](https://codeclimate.com/github/ManageIQ/manageiq-messaging/badges/coverage.svg)](https://codeclimate.com/github/ManageIQ/manageiq-messaging/coverage)
[![Dependency Status](https://gemnasium.com/ManageIQ/manageiq-messaging.svg)](https://gemnasium.com/ManageIQ/manageiq-messaging)
[![Security](https://hakiri.io/github/ManageIQ/manageiq-messaging/master.svg)](https://hakiri.io/github/ManageIQ/manageiq-messaging/master)

Client library for ManageIQ components to exchange messages through its internal message bus.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'manageiq-messaging'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install manageiq-messaging

## Usage

### Initialize a client

It is not recommended to directly create an actual client through `new` operation. Follow the example by specifying a protocol. This allows to easily switch the underlying messaging system from one type to another. Currently `:Stomp` and `:Kafka` are implemented.

```
  ManageIQ::Messaging.logger = Logger.new(STDOUT)

  client = ManageIQ::Messaging::Client.open(
    :protocol   => 'Stomp',
    :host       => 'localhost',
    :port       => 61616,
    :password   => 'smartvm',
    :username   => 'admin',
    :client_ref => 'generic_1',
    :encoding   => 'json' # default 'yaml'
  )

  # publish or consume messages using the client

  client.close
```

Alternatively, you can pass a block to `.open` without the need to explicitly close the client.

```
  ManageIQ::Messaging::Client.open(
    :protocol   => 'Stomp',
    :host       => 'localhost',
    :port       => 61616,
    :password   => 'smartvm',
    :username   => 'admin',
    :client_ref => 'generic_1'
  ) do |client|
      # do stuff with the client
    end
  end
```

### Publish and subscribe messages

This is the one-to-one publish/subscribe pattern. Multiple subscribers can subscribe to the same queue but only one will consume the message. Subscribers are load balanced.

```
  client.publish_message(
    :service  => 'ems_operation',
    :affinity => 'ems_amazon1',
    :message  => 'power_on',
    :payload  => {
      :ems_ref => 'u987',
      :id      => '123'
    }
  )

  client.subscribe_messages(:service => 'ems_operation', :affinity => 'ems_amazon1', :auto_ack => false) do |messages|
    messages.each do |msg|
      # do stuff with msg.message and msg.payload
      msg.ack
    end
  end

  # You can create a second client instance and call subscribe_messages with
  # the same options. Then both clients will take turns to consume the messages.
```

For better sending performance, you can publish a collection of messages together

```
  msg1 = {:service => 'ems_inventory', :affinity => 'ems1', :message => 'refresh', :payload => 'vm1'}
  msg2 = {:service => 'ems_inventory', :affinity => 'ems1', :massage => 'refresh', :payload => 'vm2')
  client.publish_messages([msg1, msg2])
```

Provide a block if you want `#publish_message` to wait on a response from the subscriber. This feature may not be supported by every underlying messaging system.

```
  client.publish_message(
    :service  => 'ems_operation',
    :affinity => 'ems_amazon1',
    :message  => 'power_on',
    :payload  => {
      :ems_ref => 'u987',
      :id      => '123'
    }
  ) do |result|
    ansible_install_pkg(vm1) if result == 'running'
  end
```

### Publish and subscribe background jobs

Background Job is a special type of message with a known `class_name` and the subscriber knows how to process the message without a user block

```
  client.publish_message(
    :service    => 'generic',
    :class_name => 'MiqTask',
    :message    => 'update_attributes', # method name
    :payload    => {
      :instance_id => 2,
      :args        => [{:status => 'Timeout'}]
    }
  )

  client.subscribe_background_job(:service => 'generic')
```

Provide a call block if you want `#publish_message` to wait on a response from the subscriber.

### Publish and subscribe topics (events)

This is the one-to-many publish/subscribe pattern. Multiple subscribers can subscribe to the same queue and each one will receive the same message.

```
  client.publish_topic(
    :service => 'provider_events',
    :event   => 'powered_on',
    :sender  => 'ems_amazon1', # optional
    :payload => {
      :ems_ref   => 'uid987',
      :timestamp => '1501091391'
    })

  client.subscribe_topic(:service => 'provider_events', :persist_ref => 'automate_1') do |msg|
    # do stuff with msg.sender, msg.message, and msg.payload. sender may be nil if not set by the publisher
  end
```

By default, events are delivered to live subscribers only. Some messaging systems support persistence with options.

### Add your own headers to a message (Queue or Topic)

If you want you can add in your own headers to the send message

```
  client.publish_topic(
    :service => 'provider_events',
    :event   => 'powered_on',
    :headers => {:request_id => "12345"},
    :payload => {:ems_ref => 'uid987'}

  )

  client.subscribe_topic(:service => 'provider_events', :persist_ref => 'automate_1') do |msg|
    puts "Received event #{msg.message} with request-id: #{msg.headers[:request_id]}"
  end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ManageIQ/manageiq-messaging. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
