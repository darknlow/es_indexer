class Order
  include Mongoid::Document
  include Mongoid::Timestamps

  field :id, type: Integer
  field :client, type: String
  field :units, type: Integer
  field :tenant_id, type: Integer
  field :lock_id, type: Integer
end
