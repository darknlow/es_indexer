require_relative "../transaction_shared"

RSpec.shared_context "job shared" do
  include_context "transaction shared" 

  let(:tr_model) { Mongoer::Persistence::Transaction }

  let(:processor) do
    pr = described_class.new(transactions)
    pr.send(:reset_state, job)
    pr.instance_variable_set(:@data, item)
    pr.instance_variable_set(:@tr, pr.transactions.first)
    pr.instance_variable_set(:@index, 0)
    pr
  end

  let(:transactions) { [ my_transaction_1 ] }

  let(:job) { build(:job, data: [data], tenant_id: tenant_id) }
  let(:tenant_id) { 10 }
  let(:data) do
    [ { id: 1, units: 10, validation: true },
      { id: 2, units: 20, validation: true } ]
  end
  let(:foreign_lock) { 300 }
  let(:item) { data.first }
  let(:error) { processor.errors[:items].first }
  let(:old_units) { 5 }
  let(:order) { create :order, id: item[:id], tenant_id: tenant_id, units: old_units }
  let(:orders) do
    orders = []
    data.each do |tr_data|
      order = build(:order, id: tr_data[:id], tenant_id: tenant_id, units: old_units)
      orders << order
    end
    orders
  end
end
