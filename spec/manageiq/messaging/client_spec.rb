require "spec_helper"

describe ManageIQ::Messaging::Client do
  subject { described_class.open({:protocol => 'Test'}) }

  describe '.open' do
    it 'without a protocol raises an exception' do
      expect { described_class.open({}) }.to raise_error(ArgumentError, /Missing protocol/)
    end

    it 'creates an instance of a type specific client' do
      expect(subject).to be_kind_of(ManageIQ::Messaging::Test::Client)
    end

    it 'with an invalid protocol' do
      expect { described_class.open(:protocol => 'Invalid') }.to raise_error(ArgumentError, /Invalid protocol/)
    end

    it 'closes the client before exit if it opens with a block' do
      described_class.open(:protocol => 'Test') do |client|
        expect(client).to receive(:close)
      end
    end
  end

  describe '#publish_message' do
    it 'requires both :service and :message in the options' do
      expect { subject.publish_message({}) }.to raise_error(ArgumentError)
      expect { subject.publish_message(:service => 's') }.to raise_error(ArgumentError)
      expect { subject.publish_message(:message => 'm') }.to raise_error(ArgumentError)
      expect { subject.publish_message(:message => 'm', :service => 's') }.not_to raise_error
    end

    it 'sends a message to a queue' do
      expect(subject).to receive(:publish_message_impl)
      subject.publish_message(:service => 'a', :message => 'm')
    end
  end

  describe '#publish_messages' do
    it 'sends a group of messages to a queue' do
      expect(subject).to receive(:publish_messages_impl)
      subject.publish_messages([])
    end
  end

  describe '#subscribe_messages' do
    it 'requires :service in the options' do
      expect { subject.subscribe_messages({}) {} }.to raise_error(ArgumentError)
      expect { subject.subscribe_messages(:service => 's') {} }.not_to raise_error
    end

    it 'requires a block is given' do
      expect { subject.subscribe_messages(:service => 's') }.to raise_error(RuntimeError, /block is required/)
    end

    it 'subscribes to a queue' do
      expect(subject).to receive(:subscribe_messages_impl)
      subject.subscribe_messages(:service => 's') {}
    end
  end

  describe '#subscribe_background_job' do
    it 'requires :service in the options' do
      expect { subject.subscribe_background_job({}) {} }.to raise_error(ArgumentError)
      expect { subject.subscribe_background_job(:service => 's') }.not_to raise_error
    end

    it 'subscribes to a queue' do
      expect(subject).to receive(:subscribe_background_job_impl)
      subject.subscribe_background_job(:service => 's') {}
    end
  end

  describe '#publish_topic' do
    it 'requires both :service and :event in the options' do
      expect { subject.publish_topic({}) }.to raise_error(ArgumentError)
      expect { subject.publish_topic(:service => 's') }.to raise_error(ArgumentError)
      expect { subject.publish_topic(:event => 'e') }.to raise_error(ArgumentError)
      expect { subject.publish_topic(:event => 'e', :service => 's') }.not_to raise_error
    end

    it 'sends a message to a topic' do
      expect(subject).to receive(:publish_topic_impl)
      subject.publish_topic(:service => 'a', :event => 'e')
    end

    it 'sends an array of messages to a topic' do
      expect(subject)
        .to receive(:publish_topic_impl)
        .with(array_including(hash_including(:event => 'e'), hash_including(:event => 'b')))
      subject.publish_topic([{:service => 'a', :event => 'e'}, {:service => 'a', :event => 'b'}])
    end
  end

  describe '#subscribe_topic' do
    it 'requires :service in the options' do
      expect { subject.subscribe_topic({}) {} }.to raise_error(ArgumentError)
      expect { subject.subscribe_topic(:service => 's') {} }.not_to raise_error
    end

    it 'requires a block is given' do
      expect { subject.subscribe_topic(:service => 's') }.to raise_error(RuntimeError, /block is required/)
    end

    it 'subscribes to a topic' do
      expect(subject).to receive(:subscribe_topic_impl)
      subject.subscribe_topic(:service => 's') {}
    end
  end
end
