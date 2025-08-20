require_relative "../../dummy/models/backorder_order"

RSpec.describe Mongoer::Repository do

  let(:repository) do
    Class.new(described_class) do
      def self.name() "OrderRepository" end
      build_attr :client
    end
  end

  describe ".tenantize" do
    let(:data) { { client: "Nikos", tenant_id: 1 } }
    it { expect(repository.build(data)[:tenant_id]).to eq 1 }
  end

  describe ".model" do
    context "with no namespace" do
      it { expect(repository.model.collection_name).to eq :orders }
    end
    context "with namespace" do
      let(:repository) do
        Class.new(described_class) do
          def self.name() "Backorder::OrderRepository" end
        end
      end
      it { expect(repository.model.collection_name).to eq "backorder:orders".to_sym }
    end
  end
end
