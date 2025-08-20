RSpec.describe Mongoer::Consumer do
  subject(:consumer) { karafka.consumer_for(topic) }

  # Set in spec_helper
  let(:topic) { ENV['KAFKA_TOPIC'] } 

  # Avoid using Class.new, unpredictable rspec behavior initializing descendants
  class NewOrderService < Mongoer::Service::Base
    transaction do
      type "new_order"
      data_key :order
      create { repository OrderRepository }
    end
  end

  class FatalService < Mongoer::Service::Base
    transaction do
      create do
        repository OrderRepository
        before_commit { raise StandardError }
      end
    end
  end

  class OrderRepository < Mongoer::Repository
    build_attr :id
  end

  let(:data) do
    { service: "new_order",
      data: {
        form_id: 1,
        origin_id: 1,
        tenant_id: 1,
        user_id: 1,
        order: { id: 1, units: 10, validation: true }}}
  end

  describe ".consume" do
    context "no error" do
      before(:each) do
        karafka.produce(data.to_json)
        consumer.consume
      end
      it { expect(Mongoer::Persistence::Job.count).to eq 1 }
      it { expect(Order.count).to eq 1 }
      it { expect(karafka.produced_messages.size).to eq 2 }
      it do
        puts karafka.produced_messages.last
        expect true
      end
    end
    context "fatal error" do
      before(:each) do
        data[:service] = "fatal"
        karafka.produce(data.to_json)
        consumer.consume
      end
      it do 
        produced = karafka.produced_messages
        msg = karafka.produced_messages.last
        expect(produced.size).to eq 2
        ::JSON.parse(msg[:payload], symbolize_names: true).each do |k, v|
          expect(v.to_s).to eq data[k].to_s
        end
      end
    end
  end
end
