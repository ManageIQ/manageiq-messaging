require "spec_helper"

describe ManageIQ::Messaging::Rdkafka::Client do
  let(:producer)   { double(:producer) }
  let(:consumer)   { double(:consumer) }
  let(:raw_client) do
    {}.tap do |h|
      allow(h).to receive(:producer).and_return(producer)
      allow(h).to receive(:consumer).and_return(consumer)
    end
  end

  subject do
    allow(::Rdkafka::Config).to receive(:new).and_return(raw_client)
    described_class.new(:host => 'localhost', :port => 1234)
  end

  describe '#initialize' do
    it 'creates a client connects to a single host' do
      expect(::Rdkafka::Config).to receive(:new).with(:"bootstrap.servers"=>"localhost:1234", :"client.id"=>"my-ref")

      described_class.new(
        :protocol   => 'Rdkafka',
        :host       => 'localhost',
        :port       => 1234,
        :client_ref => 'my-ref'
      )
    end

    it 'creates a client connects to a cluster' do
      expect(::Rdkafka::Config).to receive(:new).with({:"bootstrap.servers"=>"host1:1234,host2:1234", :"client.id"=>"my-ref"})

      described_class.new(
        :protocol   => 'Rdkafka',
        :hosts      => %w(host1 host2),
        :port       => 1234,
        :client_ref => 'my-ref'
      )
    end
  end

  describe '#publish_topic' do
    it 'sends the message to the topic' do
      expect(producer).to receive(:produce).with(
        hash_including(
          :payload       => "---\n- 1\n- 2\n- 3\n",
          :topic         => 's',
          :partition_key => 'a',
          :headers       => hash_including(
            :event_type => 'e', :encoding => 'yaml', :identity => "1234"
          )
        )
      ).and_return(double(:handle, :wait => nil))

      subject.publish_topic(
        :service => 's',
        :event => 'e',
        :group_name => 'a',
        :headers => {:identity => "1234"},
        :payload => [1, 2, 3]
      )
    end
  end

  describe '#subscribe_topic' do
    let(:raw_message) { double(:raw_message, :headers => {'sender' => 'x', 'event_type' => 'y'}, :payload => 'v') }

    before do
      allow(consumer).to receive(:subscribe)
      allow(consumer).to receive(:each).and_yield(raw_message)
    end

    context 'no auto_ack' do
      let(:auto_ack) { false }

      it 'listens to the topic with persist_ref' do
        subject.subscribe_topic(:service => 's', :persist_ref => 'pid', :auto_ack => auto_ack) { |message| nil }
        expect(raw_client).to include(:"group.id" => 'pid', :"auto.offset.reset" => 'largest', :"enable.auto.commit" => false)
      end

      it 'listens to the topic without persist_ref' do
        subject.subscribe_topic(:service => 's') { |message| nil }
        expect(raw_client).to include(:"group.id" => /manageiq_messaging_topic_group_/, :"auto.offset.reset" => 'largest', :"enable.auto.commit" => true)
      end

      it 'acks the message on demand' do
        expect(consumer).to receive(:commit)
        subject.subscribe_topic(:service => 's', :persist_ref => 'pid', :auto_ack => auto_ack) { |message| message.ack }
      end
    end

    context 'auto_ack' do
      let(:auto_ack) { true }

      it 'acks the message automatically' do
        expect(consumer).not_to receive(:commit)
        subject.subscribe_topic(:service => 's', :persist_ref => 'pid', :auto_ack => auto_ack) { |message| nil }
      end
    end
  end

  describe '#publish_message' do
    it 'sends a message with affinity to the queue' do
      expect(producer).to receive(:produce).with(
        hash_including(
          :payload => 'p', :topic => 's.uid', :headers => {:message_type => 'm', :identity => "1234"}
        )
      ).and_return(double(:handle, :wait => nil))

      subject.publish_message(
        :service    => 's',
        :message    => 'm',
        :affinity   => 'uid',
        :headers    => {:identity => "1234"},
        :payload    => 'p')
    end

    it 'sends a message without affinity to the queue' do
      expect(producer).to receive(:produce).with(
        hash_including(:payload => 'p', :topic => 's', :headers => hash_including(:message_type => 'm', :sender => 'me'))
      ).and_return(double(:handle, :wait => nil))

      subject.publish_message(:service => 's', :message => 'm', :payload => 'p', :sender => 'me')
    end
  end

  describe '#publish_message with json encoder' do
    subject do
      allow(::Rdkafka::Config).to receive(:new).and_return(raw_client)
      described_class.new(:host => 'localhost', :port => 1234, :encoding => "json")
    end

    it 'sends alternative encoding to the queue' do
      expect(producer).to receive(:produce).with(
        hash_including(
          :payload => "{\"instance_id\":1,\"args\":[\"arg1\",2]}",
          :topic   => 's.uid',
          :headers => hash_including(:message_type => 'my_method', :class_name => 'MyClass', :encoding => 'json')
        )
      ).and_return(double(:handle, :wait => nil))

      subject.publish_message(
        :service    => 's',
        :class_name => 'MyClass',
        :message    => 'my_method',
        :affinity   => 'uid',
        :payload    => { :instance_id => 1, :args => ['arg1', 2] })
    end
  end

  describe '#subscribe_messages' do
    let(:auto_ack) { false }
 
    before do
      allow(consumer).to receive(:subscribe)
      allow(consumer).to receive(:each)
    end

    it 'listens to the queue with built-in group_id' do
      subject.subscribe_messages(:service => 's', :affinity => 'uid', :auto_ack => auto_ack) { |messages| nil }
      expect(raw_client).to include(:"group.id" => described_class::GROUP_FOR_QUEUE_MESSAGES + 's.uid', :"auto.offset.reset" => 'smallest', :"enable.auto.commit" => auto_ack)
    end
  end

  describe '#publish_messages' do
    it 'sends to the queue one by one but delivers once' do
      expect(producer).to receive(:produce).with(hash_including(:payload => 'p1', :topic => 's', :headers => {:message_type => 'm'})).and_return(double(:handle, :wait => nil))
      expect(producer).to receive(:produce).with(hash_including(:payload => 'p2', :topic => 's', :headers => {:message_type => 'm'})).and_return(double(:handle, :wait => nil))
      subject.publish_messages([
        {:service => 's', :message => 'm', :payload => 'p1' },
        {:service => 's', :message => 'm', :payload => 'p2' }])
    end
  end
end
