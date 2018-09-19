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
        "---\npayload: p\nevent_type: e\nencoding: yaml\n",
        hash_including(:topic => 's', :partition_key => 'a')
      )

      subject.publish_topic(:service => 's', :event => 'e', :payload => 'p', :affinity => 'a')
    end
  end

  describe '#subscribe_topic' do
    let(:consumer) { double(:topic_consumer) }

    it 'listens to the topic with persist_ref' do
      expect(raw_client).to receive(:consumer).with(:group_id => 'pid').and_return(consumer)
      expect(consumer).to receive(:subscribe).with('s', :start_from_beginning => false)
      expect(consumer).to receive(:each_message)

      subject.subscribe_topic(:service => 's', :persist_ref => 'pid') { |_a, _b, _c| nil }
    end

    it 'listens to the topic without persist_ref' do
      expect(raw_client).to receive(:each_message).with(:topic => 's', :start_from_beginning => false)

      subject.subscribe_topic(:service => 's') { |_a, _b, _c| nil }
    end
  end

  describe '#publish_message' do
    it 'sends a regular message to the queue' do
      expect(producer).to receive(:deliver_messages)
      expect(producer).to receive(:produce).with(
        "---\npayload: p\nmessage_type: m\nencoding: yaml\n",
        hash_including(:topic => 's', :partition_key => 'uid')
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
        "---\npayload: p\nsender: me\nmessage_type: m\nencoding: yaml\n",
        :topic => 's'
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
        "{\"payload\":{\"instance_id\":1,\"args\":[\"arg1\",2]},\"message_type\":\"my_method\",\"class_name\":\"MyClass\",\"encoding\":\"json\"}",
        hash_including(:topic => 's', :partition_key => 'uid')
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

    it 'listens to the queue with built-in group_id' do
      expect(raw_client).to receive(:consumer).with(:group_id => described_class::GROUP_FOR_QUEUE_MESSAGES).and_return(consumer)
      expect(consumer).to receive(:subscribe).with('s')
      expect(consumer).to receive(:each_batch)

      subject.subscribe_messages(:service => 's', :affinity => 'uid') { |messages| nil }
    end
  end

  describe '#publish_messages' do
    it 'sends to the queue one by one but delivers once' do
      expect(producer).to receive(:produce).with("---\npayload: p1\nmessage_type: m\nencoding: yaml\n", :topic => 's')
      expect(producer).to receive(:produce).with("---\npayload: p2\nmessage_type: m\nencoding: yaml\n", :topic => 's')
      expect(producer).to receive(:deliver_messages).once
      subject.publish_messages([
        {:service => 's', :message => 'm', :payload => 'p1' },
        {:service => 's', :message => 'm', :payload => 'p2' }])
    end
  end
end
