RSpec.shared_context "transaction shared" do
  let(:repo) do
    Class.new(Mongoer::Repository) do
      build_attr :id, :units
      def self.name() "OrderRepository" end
    end
  end

  let(:my_transaction_1) do
    repository = repo
    Class.new(Mongoer::Transaction) do
      def self.name() "MyTransaction1" end
      type :my_transaction_1
      update do
        repository repository
        validate do
          expr { data[:validation] } 
          msg "Error msg"
        end
        field do
          name :units
          value { data[:units] }
        end
      end
    end.new
  end

  let(:my_transaction_2) do
    repository = repo
    Class.new(Mongoer::Transaction) do
      def self.name() "MyTransaction2" end
      type :my_transaction_2
      create do
        repository repository
        validate do
          expr { data[:validation] }
          msg "Error msg"
        end
      end
    end.new
  end
end
