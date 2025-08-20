module Mongoer
  RSpec.describe Action::Base do
    describe ".register_action" do
      let(:action_class) do 
        c = Class.new(described_class) do
          def self.name() "MyCustomAction" end
          register_action { key_attr :custom_attr }
        end
      end
      let(:transaction_class) do 
        action_class
        tr = Class.new(Transaction) do
          my_custom do
            condition 1
            repository 1
            custom_attr 1
            before_lock 1
            after_lock 1
            before_commit 1
            after_commit 1
            not_found_error 1
            validate do
              expr 1
              msg 1
            end
            validate do
              expr 1
              msg 1
            end
          end
        end
        tr
      end
      let(:action_conf) { transaction_class.conf.list.first[:body] }
      it { expect(transaction_class.respond_to?(:my_custom)).to be true }
      [ :condition, :before_lock, :after_lock, :custom_attr ].each do |method|
        it { expect(action_conf.send(method)[:args].first).to eq 1 }
      end
      it "registers the validations"  do
        action_conf.lists[:val].each do |val|
          [ :expr, :msg ].each do |attr|
            expect(val[:body].keys[attr][:args].first).to eq 1
          end
        end
      end
    end
  end
end
