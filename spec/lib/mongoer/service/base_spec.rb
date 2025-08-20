RSpec.describe Mongoer::Service::Base do
  let(:service) do
    Class.new(Mongoer::Service::Base) do
      def self.name() "NewOrderService" end
      result { next "Job Result" }
      transaction do
        create { repository { Order } }
      end
      transaction do
        update { repository { Order } }
      end
    end
  end

  describe ".initialize" do
    let(:service_one) { service.new }
    let(:service_two) { service.new }
    let(:transactions) { service.new.transactions }
    let(:batch_service) do 
      Class.new(described_class) do 
        def self.name() "BatchService" end
        batch true
        transaction { create { repository { Order } } }
      end.new
    end
    let(:seq_service) do 
      Class.new(described_class) do 
        def self.name() "SequentialService" end
        batch false
        transaction { create { repository { Order } } }
      end.new
    end
    it { expect(service_one.processor.object_id).to_not eq service_two.processor.object_id }
    it { expect(batch_service.processor.class).to be ::Mongoer::Job::BatchProcessor }
    it { expect(seq_service.processor.class).to be ::Mongoer::Job::SequentialProcessor }
    it { expect(transactions.size).to eq 2 }
    it { expect(transactions.first.class.object_id).not_to eq transactions.last.class.object_id }
    it { expect(transactions.first.actions.size).to eq 1 }
    it { expect(transactions.first.actions.first).to be_a Mongoer::Action::CreateAction }
    it { expect(transactions.last.actions.first).to be_a Mongoer::Action::UpdateAction }
    it { expect(service_one.producer.service).to eq service_one.class.service }
    it { expect(service_one.producer.result_conf).to eq service_one.class.result }
  end
end
