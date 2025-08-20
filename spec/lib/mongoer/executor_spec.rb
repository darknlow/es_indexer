module Mongoer
  RSpec.describe Executor do
    let(:repo) do
      Class.new(Repository) do
        def self.name() "OrderRepositoty" end
        def self.build(data, shared)
          raise Action::LockedError if data[:retryable_error]
          raise StandardError if data[:fatal_error] 
          Order.new(id: data[:order_id])
        end
      end
    end

    let(:service) do
      repository = repo
      Class.new(Service::Base) do
        def self.name() "NewOrderService" end
        transaction do
          type "new_order"
          data_key :order
          create do
            repository repository
          end
        end
      end
    end
    let(:data) do
      { order: { order_id: 10 } }
    end
    before(:each) { service }

    describe ".initialize" do
      let(:executor_one) { described_class.new }
      let(:executor_two) { described_class.new }
      it { expect(executor_one.services[:default][:new_order].class.name).to eq "NewOrderService" }
      it { expect(executor_one.services[:default][:new_order].object_id).to_not eq executor_two.services[:new_order].object_id }
    end

    describe ".call" do
      let(:executor) do 
        ex = described_class.new
        ex.services = { default: { new_order: service.new } }
        ex
      end
      let(:call) { executor.call(:default, :new_order, data) }
      it { expect { call }.to change { Persistence::Job.count }.by(1) }
      it do
        call
        job = Persistence::Job.last
        expect(job.type).to eq "new_order"
      end
      context "on retryable error" do
        before(:each) { data[:order][:retryable_error] = true }
        it { expect { call }.to raise_error(Action::LockedError) }
      end
      context "on fatal error" do
        before(:each) { data[:order][:fatal_error] = true }
        it { expect { call }.to raise_error(Starman::Service::FatalError) }
      end
    end
  end
end
