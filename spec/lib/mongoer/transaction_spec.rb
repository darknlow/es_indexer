RSpec.describe Mongoer::Transaction do
  let(:repo) do
    Class.new(Mongoer::Repository) do
      build_attr :id, :units, :client
      def self.name() "OrderRepository" end
    end
  end
  let(:tr) do
    repository = repo
    tr_class = Class.new(Mongoer::Transaction) do
      type :new_order
      data_key :order
      create do
        repository repository
      end
      update do
        repository repository
        field do
         name :client
         value { data[:client] }
        end 
        field do
         name :units
         value { data[:units] }
        end
      end
    end
    tr_class.new
  end
  let(:data) do
    {
      id: 1,
      update_id: 2,
      client: "Nikos",
      units: 20 
    }
  end
  let(:shared) { { common: { form_id: 1 }, records: {} } }

  describe ".type" do
    it { expect(tr.type).to eq :new_order }
  end

  describe ".data_key" do
    context "when key is defined" do
      it { expect(tr.data_key).to eq :order }
    end
    context "when key is not defined" do
      let(:tr) do
        Class.new(Mongoer::Transaction) { update {} }.new
      end
      it { expect(tr.data_key).to eq :items }
    end
  end

  describe ".initialize" do
    let(:create_conf) { tr.actions.first.conf }
    let(:update_conf) { tr.actions.last.conf }
    it { expect(tr.actions.size).to eq 2 }
    it { expect(tr.actions.first).to be_a(::Mongoer::Action::CreateAction) }
    it { expect(tr.actions.last).to be_a(::Mongoer::Action::UpdateAction) }
    it { expect(tr.actions.first.pos).to eq 0 }
    it { expect(tr.actions.last.pos).to eq 1 }
    it { expect(create_conf.get_repository).to be repo }
  end

  describe ".call" do
    let(:created_order) { Order.where(id: data[:id]).first }
    let(:updated_order) { Order.where(id: data[:update_id]).first }
    before(:each) do
      order = create :order, id: data[:update_id], client: "George", units: 1
      tr.call(:commit, data, shared)
      order.reload
    end
    it { expect(created_order[:lock_id]).to be nil }
    it { expect(updated_order[:lock_id]).to be nil }
    it { expect(shared[:records][:order].first.id).to eq data[:id] }
  end
end
