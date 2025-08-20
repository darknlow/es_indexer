FactoryBot.define do
  factory :job, class: "Mongoer::Persistence::Job" do
    sequence(:id) { |i| i }
    data { [{ client: "George"}] }
    type { "new_order" }
    sequence(:form_id) { |i| i }
    sequence(:tenant_id) { |i| i }
    sequence(:user_id) { |i| i }
  end
end 
