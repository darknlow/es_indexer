require_relative "./job_shared"

module Mongoer
  RSpec.describe Job::BatchProcessor do
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
          orders.last[:lock_id] = 300
          orders.each(&:save)
        end
        it { expect { processor.send(:process_job) }.to raise_error(Action::LockedError) }
        it { expect(tr_model.count).to be 0 }
      end
      context "InvalidError on lock" do
        before(:each) do
          data.last[:validation] = false
          orders.each(&:save)
          processor.send(:process_job)
        end
        it { expect(error[:index]).to eq 1 }
        it { expect(tr_model.count).to eq 0 }
      end
      context "InvalidError on commit" do
        let(:transactions) { [ my_transaction_2 ] }
        before(:each) do
          orders.last.save
          processor.send(:process_job)
        end
        it { expect(error[:msg]).to eq "Record exists" }
        it { expect(error[:index]).to eq 1 }
        it { expect(tr_model.count).to eq 0 }
      end
    end

    describe ".lock" do
      context "no error" do
        before(:each) do 
          orders.each(&:save)
          processor.send(:lock)
        end
        it { Order.all.each { |o| expect(o[:lock_id]).to eq job.id } }
      end
      context "with error" do
        it do
          expect { processor.send(:lock) }.to raise_error(Action::InvalidError)
        end
      end
    end

    describe ".validate_and_commit" do
      def invalid_exc_test
        expect { processor.send(:validate_and_commit) }
            .to raise_error(Action::InvalidError)
        processor.send(:validate_and_commit)
      rescue Action::InvalidError
        expect(tr_model.count).to eq 0
      end

      context "no error" do
        before(:each) do
          orders.each(&:save)
          processor.send(:validate_and_commit)
        end
        it { Order.all.each_with_index { |o, i| expect(o.units).to eq data[i][:units] } }
        it { expect(tr_model.count).to eq 2 }
      end
      context "tr is dupe" do
        before(:each) { create :transaction, job_id: job.id, index: 0, type: :my_transaction_1 }
        it do 
          expect { processor.send(:validate_and_commit) }.to raise_error(::Starmongo::RecordExistsError)
        end
        it do 
          processor.send(:validate_and_commit)
        rescue ::Starmongo::RecordExistsError
          expect(tr_model.count).to eq 1
        end
      end
      context "InvalidError on validate" do
        before(:each) do
          data.last[:validation] = false
          orders.each(&:save)
        end
        it { invalid_exc_test }
      end
      context "InvalidError on commit" do
        let(:transactions) { [ my_transaction_2 ] }
        before(:each) { orders.last.save }
        it { invalid_exc_test }
      end
    end

    describe ".release" do
      before(:each) do
        orders.each_with_index { |o, i| o[:lock_id] = data[i][:lock_id] }
        orders.each(&:save)
        processor.send(:release)
      end
      it { Order.all.each { |ord| expect(ord[:lock_id]).to be nil } }
    end

    describe ".tr_dupe_error_handler" do
      before(:each) { create :transaction, job_id: job.id, index: item[:index] }
      it do 
        expect(processor.send(:tr_dupe_error_handler)).to eq false
        expect(processor.errors.any?).to be false
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
      end
    end
  end
end
