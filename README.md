# Manageiq::Messaging

ManageIQ library for ManageIQ components to exchange messages through its internal messaging bus.

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
```
  ManageIQ::Messaging.logger = Logger.new(STDOUT)
  
  client = ManageIQ::Messaging::Client.open(
    :host      => 'localhost', 
    :port      => 61616, 
    :password  => 'smartvm', 
    :username  => 'admin', 
    :client_id => 'generic_1')
  
  # publish or comsume messages using the client
  
  client.close
```
Alternatively your code can live in a block for the `.open` method without the need to explictly close the client
```
  ManageIQ::Messaging::Client.open(
    :host      => 'localhost', 
    :port      => 61616, 
    :password  => 'smartvm', 
    :username  => 'admin', 
    :client_id => 'generic_1') do |client|
      # do stuff with the client
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
      :ems_ref => 'u987'
      :id      => '123'
    })
    
  client.subscribe_messages(:service => 'ems_operation', :affinity => 'ems_amazon1', :limit => 10) do |messages|
    messages.each do |msg|
      # do suff with msg.message and msg.payload
      client.ack(msg.ack_id) # ack is required, but you can do it before or after do stuff
    end
  end
  
  # You can create client2 and subscribe_messages with the same options; then both clients will take turns to
  # consume the messages.
```

To have a better sending performance you can publish a colletction of messages together
```
  msg1 = {:service => 'ems_inventory', :affinity => 'ems1', :message => 'refresh', :payload => 'vm1'}
  msg2 = {:service => 'ems_inventory', :affinity => 'ems1', :massage => 'refresh', :payload => 'vm2')
  client.publish_messages([msg1, msg2])
```

Provide a call block if you want `#publish_message` to wait on a response from the subscriber.
```
  client.publish_message(
    :service  => 'ems_operation', 
    :affinity => 'ems_amazon1', 
    :message  => 'power_on', 
    :payload  => {
      :ems_ref => 'u987'
      :id      => '123'
    }) do |result|
      ansible_install_pkg(vm1) if result == 'running'
    end
```

### Publish and subscribe background jobs
Background Job is a special type of message with a known `class_name` and the subscriber knows how to process the message without a user block
```
  client.publich_message(
    :service    => 'generic',
    :class_name => 'MiqTask',
    :messge     => 'update_attributes',
    :payload    => {
      :instance_id => 2,
      :args        => [{:status => 'Timeout'}]
    }
    
  client.subscribe_background_job(:service => 'generic')
```

Provide a call block if you want `#publish_message` to wait on a response from the subscriber.

### Publish and subscribe topics (events)
This is the one-to-many publish/subscribe pattern. Multiple subscribers can subscribe to the same queue and each one will receive the same message.
```
  client.publish_topic(
    :service => 'provider_events',
    :event   => 'powered_on',
    :sender  => 'ems_amazon1',
    :payload => {
      :ems_ref   => 'uid987'
      :timestamp => '1501091391'
    })
    
  client.subscribe_topic(:service => 'provider_events', :persist_id => 'automate_1') do |sender, event, payload|
    # do stuff with event and payload. sender is optional
  end  
```

By default events are delivered to live subscribers only; subscribe's `persist_id` is not required. If a subscriber wants to receive the events it missed when it is offline, it should always create with same same `client_id` and subscribe to the topic with the same `persist_id`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/manageiq-messaging. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

