require_relative "./action_shared.rb"

RSpec.describe Mongoer::Action::UpdateOrDeleteAction do
  include_context "action shared"
  let(:tr_class) do
    repository = repo
    Class.new(Mongoer::Transaction) do
      update_or_delete do
        repository repository
        delete_if { record.units - data[:units] == 0 }
        field do
          name :units
          value { -data[:units] }
          operator :inc
        end
      end
    end
  end
  let(:order) { create(:order, build_data)  }
  before(:each) { action.record = order }

  describe ".delete_if" do
    context "when true" do
      before(:each) { data[:units] = 5 }
      it { expect(action.delete_if).to be true }
    end
    context "when false" do
      it { expect(action.delete_if).to be false }
    end
  end

  describe ".action_select" do
    context "when delete_if is true" do
      before(:each) { data[:units] = 5 }
      it { expect(action.action_select).to eq :delete }
    end
    context "when delete_if is false" do
      it { expect(action.action_select).to eq :update }
    end
  end

  describe ".commit_and_release" do
    context "when delete_if is true" do
      before(:each) { data[:units] = 5 }
      it { expect { action.commit_and_release }.to change { Order.count }.by(-1) }
    end
    context "when delete_if is false" do
      before(:each) { action.commit_and_release }
      let(:record) { Order.last }
      it { expect(record.units).to eq -5 }
    end
  end
end
