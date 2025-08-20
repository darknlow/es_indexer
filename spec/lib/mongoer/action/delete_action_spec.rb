require_relative "./action_shared.rb"

RSpec.describe Mongoer::Action::DeleteAction do
  include_context "action shared"

  let(:tr_class) do
    repository = repo
    Class.new(Mongoer::Transaction) do
      delete do
        repository repository
      end
    end
  end
  let(:order) { create(:order, build_data) }

  describe ".commit_and_release" do
    context "when the record has not been deleted" do
      before(:each) { order }
      it { expect { action.commit_and_release }.to change { Order.count }.by(-1) }
    end
    context "when the record has been deleted" do
      it { expect { action.commit_and_release }.to raise_error(::Mongoer::Action::InvalidError) }
    end
  end
end
