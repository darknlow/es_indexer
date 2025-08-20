FactoryBot.define do
  factory :transaction, class: "Mongoer::Persistence::Transaction" do
    sequence(:id) { |i| i }
    sequence(:job_id) { |i| i }
    type { "new_order" }
    index { 1 }
    data { [{ client: "George"}] }
  end
end 
