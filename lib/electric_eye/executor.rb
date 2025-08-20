require "starman/service/executor"

module ElectricEye
  class Executor < Starman::Service::Executor

    retryables ::Mongo::Error::ReadWriteRetryable,
      ::Redis::BaseConnectionError
  end
end
