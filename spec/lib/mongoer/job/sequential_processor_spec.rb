require_relative "./job_shared"

module Mongoer
  RSpec.describe Job::SequentialProcessor do
    include_context "job shared"

    describe ".process_job" do
      context "no errors" do
        before(:each) do 
          orders.each(&:save)
          processor.send(:process_job)
        end
        it { expect(tr_model.count).to eq 2 }
        it { tr_model.each { |tr| expect(tr.val_error).to be nil } } 
        it { Order.all.each_with_index { |o, i| expect(o.units).to eq data[i][:units] } }
      end
      context "LockedError" do
        before(:each) do
          orders.last[:lock_id] = foreign_lock
          orders.each(&:save)
        end
        it { expect { processor.send(:process_job) }.to raise_error(Action::LockedError) }
        it { expect(tr_model.count).to be 0 }
      end
      context "InvalidError on lock" do
        before(:each) do
          data.first[:validation] = false
          orders.each(&:save)
          processor.send(:process_job)
        end
        it { expect(error[:index]).to eq 0 }
        it { expect(tr_model.count).to eq 2 }
        it { expect(tr_model.first.val_error).to eq "Error msg" }
        it { expect(tr_model.last.val_error).to be nil }
        it { expect(Order.first.units).to eq old_units }
        it { expect(Order.last.units).to eq data.last[:units] }
      end
      context "InvalidError on commit" do
        let(:transactions) { [ my_transaction_2 ] }
        before(:each) do
          order
          processor.send(:process_job)
        end
        it { expect(error[:msg]).to eq "Record exists" }
        it { expect(error[:index]).to eq 0 }
        it { expect(Order.count).to eq 2 }
      end
    end

    describe ".lock_and_validate" do
      context "no error" do
        before(:each) do 
          order
          processor.send(:lock_and_validate)
          order.reload
        end
        it { expect(order[:lock_id]).to eq job.id }
      end
      context "with error" do
        before(:each) { item[:validation] = false }
        it do
          expect { processor.send(:lock_and_validate) }.to raise_error(Action::InvalidError)
        end 
      end
    end

    describe ".commit" do
      context "no error" do
        before(:each) do
          order
          processor.send(:commit)
          order.reload
        end
        it { expect(order.units).to eq item[:units] }
        it { expect(tr_model.count).to eq 1 }
      end
      context "with error" do
        before(:each) { create :transaction, job_id: job.id, index: 0, type: :my_transaction_1 }
        it { expect { processor.send(:commit) }.to raise_error(::Starmongo::RecordExistsError) }
        it { expect(order.units).to eq old_units }
        it { expect(tr_model.count).to eq 1 }
      end
    end

    describe ".release" do
      let(:locked_order) do 
        ord = build :order, id: item[:id]
        ord[:lock_id] = item[:lock_id]
        ord.save
        ord
      end
      before(:each) do
        locked_order
        processor.send(:release)
        locked_order.reload
      end
      it { expect(locked_order[:lock_id]).to be nil }
    end

    describe ".tr_dupe_error_handler" do
      before(:each) do 
        create :transaction, job_id: job.id, index: 0, type: :my_transaction_1, val_error: val_error
        processor.send(:tr_dupe_error_handler)
      end
      context "no error" do
        let(:val_error) { nil }
        it { expect(processor.errors.any?).to be false }
      end
      context "with error" do
        let(:val_error) { "Error msg" }
        it { expect(processor.errors.size).to eq 1 }
        it { expect(error[:index]).to eq 0 }
      end
    end

    describe ".invalid_error_handler" do
      let(:inv_processor) do
        processor.send(:invalid_error_handler, Action::InvalidError.new("Invalid"))
      end
      context "tr not exists" do
        before(:each) { inv_processor }
        it { expect(error[:index]).to eq 0 }
        it { expect(error[:msg]).to eq "Invalid" }
        it { expect(tr_model.count).to eq 1 }
        it { expect(tr_model.last.val_error).to eq "Invalid" }
      end
      context "tr is dupe" do
        before(:each) do 
          create :transaction, job_id: job.id, index: 0, type: :my_transaction_1, val_error: "Old Invalid" 
          inv_processor
        end
        it { expect(error[:msg]).to eq "Old Invalid" }
        it { expect(tr_model.count).to eq 1 }
        it { expect(tr_model.last.val_error).to eq "Old Invalid" }
      end
    end
  end
end
