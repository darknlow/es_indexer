require_relative "./action_shared.rb"

RSpec.describe Mongoer::Action::UpdateOrCreateAction do
  include_context "action shared"
  let(:tr_class) do
    repository = repo
    Class.new(Mongoer::Transaction) do
      update_or_create do
        repository repository
        field do
          name :units
          value { data[:units] }
          operator :inc
        end
        field do
         name :client
         value { data[:client] }
        end 
      end
    end
  end
  let(:order) { create(:order, build_data) }

  describe ".optional" do
    before(:each) { action.conf.optional(true) }
    it "the DSL option is ignored, it is always false" do
      expect(action.optional).to be false
    end
  end

  describe ".lock" do
    context "when the record exists" do
      before(:each) do
        order 
        action.lock
        order.reload
      end
      it { expect(order[:lock_id]).to eq shared[:job_id] }
      it { expect(action.record.id).to eq order.id }
    end
    context "when the record does not exist" do
      before(:each) { action.lock }
      it { expect(action.record).to be nil }
    end
  end

  describe ".commit_and_release" do
    context "when the record exists" do
      before(:each) { action.record = order }
      context "when delete_if is false" do
        before(:each) do
          action.commit_and_release
          order.reload
        end
        it { expect(order.client).to eq data[:client] }
        it { expect(order.units).to eq(data[:units] + build_data[:units]) }
      end
      context "when delete_if is true" do
        before(:each) { action.conf.delete_if { true } }
        it { expect { action.commit_and_release }.to change { Order.count }.by(-1) }
      end
    end

    context "when the record does not exist" do
      before(:each) { data[:exists] = false }
      it { expect { action.commit_and_release }.to change { Order.count }.by(1) }
    end
  end
end
