# frozen_string_literal: true

ENV['KAFKA_TOPIC'] = "mongoer"

require "mongoer"
require "factory_bot"
require 'karafka/testing/rspec/helpers'
require_relative "dummy/mongo_schema"

RSpec.configure do |config|
  Mongoid.load!(ENV['MONGOID_YML'], :production)
  # Enable flags like --only-failures and --next-failure
  config.include Karafka::Testing::RSpec::Helpers
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
    MongoSchema.db_setup
  end

  config.before(:example) do
    Order.delete_all
    Mongoer::Persistence::Job.delete_all
    Mongoer::Persistence::Transaction.delete_all
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
