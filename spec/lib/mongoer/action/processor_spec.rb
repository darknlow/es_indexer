require_relative "./action_shared.rb"

module Mongoer
  RSpec.describe Action::Processor do
    include_context "action shared"

    let(:action_class) do 
      class Committed < StandardError; end
      act_class = Class.new(Action::Base) do
        def self.name() "MyCustomAction" end;
        def commit_and_release() raise Committed end;
        register_action
      end
    end

    let(:repo) do
      Class.new(Repository) do
        def self.name() "OrderRepository" end
      end
    end

    let(:tr_class) do
      repository = repo
      Class.new(Transaction) do
        my_custom { repository repository }
      end
    end

    let(:order) { create :order, build_data }

    let(:locked_order) do
      order = build :order, build_data
      order[:lock_id] = lock_id
      order.save
      order
    end

    let(:lock_id) { shared[:job_id] }

    describe ".hook_exec" do
      context "when block is provided" do
        before(:each) do
          action.conf.before_lock { data[:some_key] =  "some value" } 
          action.hook_exec(:before_lock)
        end
        it { expect(action.data[:some_key]).to eq "some value" }
      end
      context "when setup block is not present" do
        it { expect { action.hook_exec(:before_lock) }.to_not raise_error }
      end
    end

    describe ".record" do
      before(:each) { records[action.pos] = true }
      it { expect(action.record).to be true }
    end

    describe ".record=" do
      before(:each) { action.record = true }
      it { expect(action.records[action.pos]).to be true }
    end

    describe ".lock_id" do
      it { expect(action.lock_id).to eq shared[:job_id] }
    end

    describe ".record_criteria" do
      let(:tr_class) do
        Class.new(Transaction) do
          repo = Class.new do
            def self.name() "OrderRepository" end
            def self.context(data, shared) "Default Context" end
          end
          my_custom do 
            repository repo
          end
        end
      end
      it { expect(action.repo.name).to eq "OrderRepository" }
      it { expect(action.record_criteria).to eq "Default Context" }
    end

    describe ".locked_criteria" do
      context "when the record is locked by this job" do
       before(:each) { locked_order } 
        it { expect(action.locked_criteria.first.id).to eq(locked_order.id) }
      end

      context "when the record is locked by another job" do
        let(:lock_id) { 300 }
        before(:each) { locked_order }
        it { expect(action.locked_criteria.first).to be nil }
      end

      context "when the record is unlocked" do
        before(:each) { order }
        it { expect(action.locked_criteria.first).to be nil }
      end
    end

    describe ".lock" do
      context "when hooks are provided" do
        before(:each) do
          order
          action.conf.before_lock { data[:before_lock_key] = "some value" } 
          action.conf.after_lock { data[:after_lock_key] = "some value" } 
          action.lock
        end
        [ :before_lock_key, :after_lock_key ].each do |k|
          it { expect(action.data[k]).to eq "some value" }
        end
      end
      context "when the record is ulocked" do
        before(:each) do 
          order
          action.lock
          order.reload
        end
        it { expect(order["lock_id"]).to eq lock_id }
      end
      context "when the record is locked by this job" do
        before(:each) do
          locked_order
          action.lock
          locked_order.reload
        end
        it { expect(locked_order["lock_id"]).to eq lock_id }
      end
      context "when the record is locked by another job" do
        let(:lock_id) { 300 }
        before(:each) { locked_order }
        it { expect { action.lock }.to raise_error(Action::LockedError) }
      end
      context "when the record does not exist" do
        context "when it is not optional" do
          def error_test
            expect { action.lock }.to raise_error do |error|
              expect(error.message).to eq msg
              expect(error).to be_a(Action::InvalidError)
            end
          end
          context "when not_found_error is not defined" do
            let(:msg) { "Record not found" }
            it { error_test }
          end
          context "when not_found_error is defined" do
            before(:each) do 
              action.conf.not_found_error { "Some error #{data[:client]}" }
            end
            let(:msg) { "Some error #{data[:client]}" }
            it { error_test }
          end
        end
        context "when it is optional" do
          before(:each) { action.conf.optional(true) }
          it { expect { action.lock }.not_to raise_error }
        end
      end
    end

    describe ".release" do
      context "when the record is locked by this job" do
        it { create :order }
        before(:each) do
          locked_order
          action.release
          locked_order.reload
        end
        it { expect(locked_order[:lock_id]).to be nil }
      end
      context "when the record is locked by another job" do
        let(:lock_id) { 300 }
        before(:each) do
          locked_order
          action.release
          locked_order.reload
        end
        it { expect(locked_order[:lock_id]).to eq lock_id }
      end
    end

    describe ".commit" do
      def is_committed?
        expect { action.commit }.to raise_error(Committed)
      end

      context "when optional" do
        before(:each) { action.conf.optional(true) }
        context "when the record has been locked" do
          before(:each) { action.record = true }
          it { is_committed? }
        end
        context "when no record is locked" do
          it { expect(action.commit).to be nil }
        end
      end
      context "when condition is not provided" do
        it { is_committed? }
      end
      context "when condition succeeds" do
        before(:each) { action.conf.condition { true } }
        it { is_committed? }
      end
      context "when condition fails" do
        it "does not commit" do
          action.conf.condition { false }
          expect(action.commit).to be nil
        end
      end
      context "when hooks are provided" do
        before(:each) do
          action.conf.before_commit { data[:before_key] = "some value" }
          action.conf.after_commit { data[:after_key] = data[:committed] }
          action.define_singleton_method(:commit_and_release) { data[:committed] = data[:before_key] }
          action.commit
        end
        [:before_key, :committed, :after_key].each do |k|
          it { expect(action.data[k]).to eq "some value" }
        end
      end
    end

    describe ".validate" do
      context "when no validations are provided" do
        it "does not raise error" do
          expect { action.validate }.to_not raise_error
        end
      end
      context "when the validations are true" do
        it "does not raise error" do
          [1..2].each { action.conf.validate { expr { true } } }
          expect { action.validate }.to_not raise_error
        end
      end
      context "when validating against existing record" do
        before(:each) do
          action.conf.validate do
            expr { record.persisted? }
            msg "Error msg"
          end
          order.save
          action.record = order 
        end
        it { expect { action.validate }.to_not raise_error }
      end

      context "when a validation is false" do
       before(:each) do
         [1..2].each { action.conf.validate { expr { true } } }
         action.conf.validate do
           expr { false }
           msg "Error msg"
         end
         [1..2].each { action.conf.validate { expr { true } } }
       end
       it "raises InvalidError" do
         expect { action.validate }.to raise_error do |error|
           expect(error).to be_a(Action::InvalidError)
           expect(error.message).to eq "Error msg"
         end
       end
      end
    end
  end
end
