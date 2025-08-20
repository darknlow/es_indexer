# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

module ElectricEye
  class Error < StandardError; end

  def initialize_services!
    Service::Initializer.initialize!
  end
end

loader.eager_load
