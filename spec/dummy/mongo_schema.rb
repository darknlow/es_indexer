require "mongoid"

class MongoSchema
  def self.db_setup
    db = Mongoid::Clients.default.database
    db[:orders]&.drop
    db[:jobs]&.drop
    db[:transactions]&.drop
    validator = { 
      validator: { 
        "$jsonSchema" => { 
          bsonType: "object",
          properties: {
            units: {
              bsonType: "int",
              minimum: 1,
              description: "Units must be greater than 0" }}}}}
    # Uncomment to use validator
    # db[:orders, validator].create
    db[:orders].create
    db[:jobs].create
    db[:transactions].create
    db[:jobs].indexes.create_one({ form_id: 1 }, { unique: true })
    db[:transactions].indexes.create_one({ job_id: 1, index: 1, type: 1}, { unique: true })
  end
end
