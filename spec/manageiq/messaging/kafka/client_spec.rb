require "spec_helper"

describe ManageIQ::Messaging::Kafka::Client do
  let(:producer)   { double(:producer) }
  let(:raw_client) { double(:kafka_client, :producer => producer) }

  subject do
    expect(::Kafka).to receive(:new).and_return(raw_client)
    described_class.new(:host => 'localhost', :port => 1234)
  end

  describe '#initialize' do
    it 'creates a client connects to a single host' do
      expect(::Kafka).to receive(:new).with(['localhost:1234'], :client_id => 'my-ref')

      described_class.new(
        :protocol   => 'Kafka',
        :host       => 'localhost',
        :port       => 1234,
        :client_ref => 'my-ref'
      )
    end

    it 'creates a client connects to a cluster' do
      expect(::Kafka).to receive(:new).with(%w(host1:1234 host2:1234), :client_id => 'my-ref')

      described_class.new(
        :hosts      => %w(host1 host2),
        :port       => 1234,
        :client_ref => 'my-ref'
      )
    end
  end

  describe '#publish_topic' do
    it 'sends the message to the topic' do
      expect(producer).to receive(:deliver_messages)
      expect(producer).to receive(:produce).with(
        "---\n- 1\n- 2\n- 3\n",
        hash_including(
          :topic         => 's',
          :partition_key => 'a',
          :headers       => hash_including(:event_type => 'e', :encoding => 'yaml')
        )
      )

      subject.publish_topic(:service => 's', :event => 'e', :group_name => 'a', :payload => [1, 2, 3])
    end
  end

  describe '#subscribe_topic' do
    let(:consumer) { double(:topic_consumer) }
    let(:auto_ack) { false }
    let(:raw_message) { double(:raw_message, :headers => {'sender' => 'x', 'event_type' => 'y'}, :value => 'v') }

    it 'listens to the topic with persist_ref' do
      expect(raw_client).to receive(:consumer).with(:group_id => 'pid').and_return(consumer)
      expect(consumer).to receive(:subscribe).with('s', :start_from_beginning => false)
      expect(consumer).to receive(:each_message).with(:automatically_mark_as_processed => auto_ack).and_yield(raw_message)
      expect(consumer).to receive(:mark_message_as_processed)

      subject.subscribe_topic(:service => 's', :persist_ref => 'pid', :auto_ack => auto_ack) { |message| subject.ack(message.ack_ref) }
    end

    it 'listens to the topic without persist_ref' do
      expect(raw_client).to receive(:each_message).with(:topic => 's', :start_from_beginning => false)

      subject.subscribe_topic(:service => 's') { |_a, _b, _c| nil }
    end
  end

  describe '#publish_message' do
    it 'sends a message with affinity to the queue' do
      expect(producer).to receive(:deliver_messages)
      expect(producer).to receive(:produce).with(
        'p',
        hash_including(:topic => 's.uid', :headers => {:message_type => 'm'})
      )

      subject.publish_message(
        :service    => 's',
        :message    => 'm',
        :affinity   => 'uid',
        :payload    => 'p')
    end

    it 'sends a message without affinity to the queue' do
      expect(producer).to receive(:deliver_messages)
      expect(producer).to receive(:produce).with(
        'p',
        hash_including(:topic => 's', :headers => hash_including(:message_type => 'm', :sender => 'me'))
      )

      subject.publish_message(:service => 's', :message => 'm', :payload => 'p', :sender => 'me')
    end
  end

  describe '#publish_message with json encoder' do
    subject do
      expect(::Kafka).to receive(:new).and_return(raw_client)
      described_class.new(:host => 'localhost', :port => 1234, :encoding => "json")
    end

    it 'sends alternative encoding to the queue' do
      expect(producer).to receive(:deliver_messages)
      expect(producer).to receive(:produce).with(
        "{\"instance_id\":1,\"args\":[\"arg1\",2]}",
        hash_including(
          :topic => 's.uid',
          :headers => hash_including(:message_type => 'my_method', :class_name => 'MyClass', :encoding => 'json')
        )
      )

      subject.publish_message(
        :service    => 's',
        :class_name => 'MyClass',
        :message    => 'my_method',
        :affinity   => 'uid',
        :payload    => { :instance_id => 1, :args => ['arg1', 2] })
    end
  end

  describe '#subscribe_messages' do
    let(:consumer) { double(:message_consumer) }
    let(:auto_ack) { false }

    it 'listens to the queue with built-in group_id' do
      expect(raw_client).to receive(:consumer).with(:group_id => described_class::GROUP_FOR_QUEUE_MESSAGES).and_return(consumer)
      expect(consumer).to receive(:subscribe).with('s.uid')
      expect(consumer).to receive(:each_batch).with(:automatically_mark_as_processed => auto_ack)

      subject.subscribe_messages(:service => 's', :affinity => 'uid', :auto_ack => auto_ack) { |messages| nil }
    end
  end

  describe '#publish_messages' do
    it 'sends to the queue one by one but delivers once' do
      expect(producer).to receive(:produce).with('p1', hash_including(:topic => 's', :headers => {:message_type => 'm'}))
      expect(producer).to receive(:produce).with('p2', hash_including(:topic => 's', :headers => {:message_type => 'm'}))
      expect(producer).to receive(:deliver_messages).once
      subject.publish_messages([
        {:service => 's', :message => 'm', :payload => 'p1' },
        {:service => 's', :message => 'm', :payload => 'p2' }])
    end
  end
end
