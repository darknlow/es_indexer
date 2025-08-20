require_relative "../transaction_shared"

RSpec.describe Mongoer::Service::Base do
  include_context "transaction shared"

  let(:service) do
    serv = Class.new(Mongoer::Service::Base) do
      def self.name() "NewOrderService" end
      transaction { create { } } # Ignore, will be overriden below (instance_variable_set)
      result { { result: "Some Value" } }
    end.new
    serv.instance_variable_set(:@transactions, transactions)
    serv
  end

  let(:transactions) do
    my_transaction_1.conf.data_key :orders
    my_transaction_2.conf.data_key :order
    [ my_transaction_2, my_transaction_1 ]
  end

  let(:data) do
    { 
      form_id: 40,
      tenant_id: 20,
      user_id: 30,
      order: { id: 50, units: 10, validation: true },
      orders: [{ id: 60, units: 20, validation: true }, 
               { id: 70, units: 30, validation: false }]
    }
  end

  let(:job) { Mongoer::Persistence::Job.last }

  let(:orders_data) { job.data.last }
  let(:order_data) { job.data.first.first }

  describe ".resolve_tr_data" do
    before(:each) { service.instance_variable_set(:@data, data) }
    context "when no data_key is provided" do
      let(:transactions) { [ my_transaction_1 ] }
      before(:each) { data[:items] = "default" }
      it { expect(service.send(:resolve_tr_data, my_transaction_1)).to eq [ "default" ] }
    end
    context "when result is single value" do
      let(:tr) { transactions.first }
      it { expect(service.send(:resolve_tr_data, tr)).to be_a Array }
      it { expect(service.send(:resolve_tr_data, tr).size).to eq 1 }
    end
    context "when result is array" do
      let(:tr) { transactions.last }
      it { expect(service.send(:resolve_tr_data, tr).size).to eq 2 }
    end
  end

  describe ".process_tr_data" do
    before(:each) do 
      service.instance_variable_set(:@data, data)
    end
    let(:tr) { transactions.last }
    let(:result) { service.send(:process_tr_data, tr) }
    it { expect(result.size).to eq 2 }
    it { expect(result.first).to eq data[:orders].first }
    it { expect(result.last).to eq data[:orders].last }
  end

  describe ".process_data" do
    before(:each) { service.instance_variable_set(:@data, data) }
    let(:result) { service.send(:process_data) }
    it { expect(result.size).to eq 2 }
    it { expect(result.first).to eq [data[:order]] }
    it { expect(result.last).to eq data[:orders] }
  end

  describe ".setup_data" do
    context "when setup is not provided" do
      before(:each) { service.send(:setup_data, data) }
      it { expect(service.data).to eq data }
    end
    context "when setup is provided" do
      before(:each) do
        service.conf.setup { data[:order][:custom] = true }
        service.send(:setup_data, data)
      end
      it { expect(service.data[:order][:custom]).to be true }
    end
  end

  describe ".find_or_create_job" do
    context "when job does not exist" do
      before(:each) do 
        service.send(:find_or_create_job, data)
      end
      it { expect(Mongoer::Persistence::Job.count).to eq 1 }
      [ :form_id, :tenant_id, :user_id ].each do |k|
        it { expect(job.send(k)).to eq data[k] }
      end
      it { expect(job.type).to eq "new_order" }
      it { expect(job.data.first.first.transform_keys(&:to_sym)).to eq data[:order] }
    end
    context "when job exists" do
      before(:each) { create :job, form_id: data[:form_id], tenant_id: data[:tenant_id] }
      it { expect { service.send(:find_or_create_job, data) }.to_not change { Mongoer::Persistence::Job.count } }
      it { expect(service.send(:find_or_create_job, data).id).to eq job.id }
    end
  end

  describe ".call" do
    context "when job is not processed" do
      before(:each) do
        data[:orders].each do |d|
          create :order, id: d[:id], tenant_id: data[:tenant_id], units: d[:units]
        end
        service.processor.instance_variable_set(:@transactions, transactions)
        service.call(data)
      end
      let(:messages) { karafka.produced_messages }
      let(:last_msg) { ::JSON.parse(messages.last[:payload], symbolize_names: true) }
      it { expect(Mongoer::Persistence::Job.count).to eq 1 }
      it { expect(job.val_errors[:orders].first[:index]).to eq 1 }
      it { expect(job.val_errors[:orders].first[:msg]).to eq "Error msg" }
      it { expect(job.processed).to be true }
      it { expect(messages.size).to eq 2 }
      it { expect(last_msg[:data][:result]).to eq "Some Value" }
    end
    context "when job is processed" do
      before(:each) do
        create :job, 
          form_id: data[:form_id],
          tenant_id: data[:tenant_id], 
          type: "new_order", 
          processed: true 
      end
      it { expect { service.call(data) }.not_to change { Mongoer::Persistence::Job.count } }
      it { expect { service.call(data) }.not_to change { Order.count } }
    end
  end
end
