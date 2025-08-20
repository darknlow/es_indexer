require_relative "./action_shared.rb"

module Mongoer
  RSpec.describe Action::CreateAction do
    include_context "action shared"

    let(:tr_class) do
      repository = repo
      Class.new(Transaction) do
        create do
          repository repository
          validate do
            expr { false }
            msg "Validation failed"
          end
        end
      end
    end

    describe ".validate" do
      it { expect { action.validate }.to raise_error(Action::InvalidError) }
    end

    describe ".lock" do
      context "when the record does not exist" do
        it { expect { action.lock }.to_not raise_error }
      end
      context "when the record exists" do
        before(:each) { create(:order, build_data) }
        it { expect { action.lock }.to_not raise_error }
      end
    end

    describe ".optional" do
      before(:each) { action.conf.optional(true) }
      it "ignores DSL option" do
        expect(action.optional).to be false
      end
    end

    describe ".commit_and_release" do
      context "when the record does not exist" do
        it "creates and locks the record" do
          expect { action.commit_and_release }.to change { Order.count }.by(1) 
          expect(order.units).to eq data[:units]
          expect(order.client).to eq data[:client]
          expect(action.record).to eq order
        end
      end
      context "when the record is a dupe" do
        before(:each) { create(:order, build_data) }
        it do 
          expect { action.commit_and_release }.to raise_error do |error|
            expect(error).to be_a(Action::InvalidError)
            expect(error.message).to eq "Record exists"
          end
        end
        it { expect { action.commit_and_release }.to raise_error(Action::InvalidError) }
        it { expect { action.commit_and_release rescue nil }.to_not change { Order.count } }
      end
      context "on unexpected OperationFailure" do
        let(:repo) do
          Class.new(Repository) do
            def self.build(data, shared)
              raise Mongo::Error::OperationFailure.new("Random message", nil, { code: 100 })
            end
          end
        end
        it {expect { action.commit_and_release }.to raise_error(Mongo::Error::OperationFailure) }
      end
    end
  end
end
