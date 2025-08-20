require_relative "./job_shared"

module Mongoer
  RSpec.describe Job::Base do
    include_context "job shared"

    let(:transactions) { [ my_transaction_1, my_transaction_2 ] }

    describe ".initialize" do
      it { expect(processor.transactions.size).to eq 2 }
      [ "MyTransaction1", "MyTransaction2" ].each_with_index do |name, index|
        it { expect(processor.transactions[index].class.name).to eq name }
      end
    end

    describe ".reset_state" do
      let(:job) { create :job }
      let(:processor) { described_class.new(transactions) }
      before(:each) { processor.send(:reset_state, job) }
      it { expect(processor.job).to eq job }
      it { expect(processor.shared[:records]).to eq({}) }
      it { expect(processor.shared[:common][:job_id]).to eq job.id }
    end

    describe ".iterate" do
      let(:job) do 
        create(:job, data: [
          [ { units: 1 }, { units: 2 } ],
          [ { units: 3 }, { units: 4 } ]])
      end
      let(:result) do
        [ 
          [ "MyTransaction1", 1 ],
          [ "MyTransaction1", 2 ],
          [ "MyTransaction2", 3 ],
          [ "MyTransaction2", 4 ]]
      end
      it do
        index = 0
        processor.send(:iterate) do
          expect(processor.tr.class.name).to eq result[index].first
          expect(processor.data[:units]).to eq result[index].last
          index += 1
        end
      end
    end

    describe ".call" do
      it { expect { processor.call(job) }.to raise_error(NoMethodError) }
      let(:job) { create(:job, data: [data]) }
      context "when NoMethodError is defined" do
        before(:each) do 
          processor.define_singleton_method(:process_job) { true }
          result
        end
        let(:result) { processor.call(job) }
        it { expect(processor.errors).to eq({}) }
        it { expect(processor.job).to eq job }
        it { expect(processor.shared[:common][:job_id]).to eq job.id }
      end
    end

    describe ".process_stage" do
      context "when no error is raised" do
        before(:each) do
          processor.define_singleton_method(:lock) do
            return false
          end
        end
        it { expect(processor.send(:process_stage, :lock)).to eq true }
      end
      context "when error is raised" do
        before(:each) do
          processor.define_singleton_method(:lock) { raise ::Starmongo::RecordExistsError }
          processor.define_singleton_method(:tr_dupe_error_handler) { true }
          processor.define_singleton_method(:release) { true }
        end
        it { expect(processor.send(:process_stage, :lock)).to eq false }
      end
    end

    describe ".error_handler" do
      before(:each) do
        processor.define_singleton_method(:stages) { @stages ||= {} }
        processor.define_singleton_method(:invalid_error_handler) { |e| self.stages[:invalid] = true }
        processor.define_singleton_method(:tr_dupe_error_handler) { self.stages[:dupe] = true }
        processor.define_singleton_method(:release) { self.stages[:released] = true }
      end
      context "on RecordExists" do
        before(:each) { processor.send(:error_handler, ::Starmongo::RecordExistsError.new) }
        it { expect(processor.stages[:dupe]).to eq true }
        it { expect(processor.stages[:released]).to eq true }
      end
      context "on InvalidError" do
        before(:each) { processor.send(:error_handler, Action::InvalidError) }
        it { expect(processor.stages[:invalid]).to eq true }
        it { expect(processor.stages[:released]).to eq true }
      end
      context "on generic StandardError" do
        it { expect { processor.send(:error_handler, StandardError) }.to raise_error StandardError }
        it do
          processor.send(:error_handler, StandardError)
        rescue StandardError
          expect(processor.stages[:released]).to eq true
        end
      end
    end

    describe ".tr_call" do
      before(:each) do
        order
        processor.send(:tr_call, :lock)
        order.reload
      end
      it { expect(order[:lock_id]).to eq job.id }
    end

    describe ".release" do
      let(:order) { create :order, id: item[:id], tenant_id: tenant_id, lock_id: job.id }
      before(:each) do
        order
        processor.send(:release)
        order.reload
      end
      it { expect(order[:lock_id]).to be nil }
    end

    describe ".create_tr" do
      context "no error" do
        it { expect { processor.send(:create_tr) }.to change { Persistence::Transaction.count }.by(1) }
        it do
          processor.send(:create_tr)
          tr = Persistence::Transaction.last
          expect(tr.job_id).to eq job.id
          expect(tr.index).to eq 0
          expect(tr.data[:units]).to eq item[:units]
        end
      end
      context "with error" do
        it do
          error = "Error msg"
          processor.send(:create_tr, error)
          tr = Persistence::Transaction.last
          expect(tr.val_error).to eq error 
        end
      end
    end

    describe ".error" do
      before(:each) { processor.send(:add_error, "Some Error") }
      it { expect(error[:index]).to eq 0 }
      it { expect(error[:msg]).to eq "Some Error" }
    end
  end
end
