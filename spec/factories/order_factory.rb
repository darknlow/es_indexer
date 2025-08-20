require_relative '../dummy/models/order'

FactoryBot.define do
  factory :order do
    sequence(:id) { |i| i }
    client { 'John Doe' }
    units { 15 }
    sequence(:tenant_id) { |i| i }
  end
end 
