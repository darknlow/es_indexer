require "starafka/consumer"

module Mongoer
  class Consumer < Starafka::Consumer
    dlq_topic Conf.get_dlq_topic

    executor Executor
    fatal_error Starman::Service::FatalError
  end
end
