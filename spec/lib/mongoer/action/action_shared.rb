RSpec.shared_context "action shared", shared_context: :metadata do
  let(:action_class) { described_class }
  let(:action) do
    act = action_class.new(tr_class.conf.list.first[:body], 0)
    act.data = data
    act.shared = shared
    act.records = records
    act
  end
  let(:data) { { client: "Nikos", units: 10, id: 11 } }
  let(:shared) { { job_id: 11, tenant_id: 11 } }
  let(:records) { [] }
  let(:build_data) do 
    { client: "George", 
      units: 5, 
      tenant_id: 11,
      id: data[:id] }
  end
  let(:order) { Order.last }
  let(:repo) do
    Class.new(Mongoer::Repository) do
      def self.name() "OrderRepository" end
      build_attr :id, :client, :units
    end
  end
end
