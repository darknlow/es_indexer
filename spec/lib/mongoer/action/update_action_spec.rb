require_relative "./action_shared.rb"

RSpec.describe Mongoer::Action::UpdateAction do
  include_context "action shared"

  let(:tr_class) do
    repository = repo
    Class.new(Mongoer::Transaction) do
      update do
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
  let(:updated_order) do
    order = build(:order, {
      id: data[:trans_id],
      client: data[:client],
      units: data[:units] + build_data[:units] })
    order.save
  end


  describe ".commit_and_release" do
    context "when the record exists" do
      let(:old_ts) { order.updated_at }
      before(:each) do 
        old_ts
        action.commit_and_release
        order.reload
      end
      it { expect(order.client).to eq data[:client] }
      it { expect(order.units).to eq(data[:units] + build_data[:units]) }
      it { expect(old_ts).to_not eq order.updated_at }
    end
    context "when the record has been deleted" do
      it { expect { action.commit_and_release }.to raise_error(::Mongoer::Action::InvalidError) }
    end
  end
end
