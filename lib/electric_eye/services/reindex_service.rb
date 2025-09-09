module ElectricEye
  class ReindexService < Starman::Service::Base
    custom_domain :default

    attr_accessor :indexes

    def initialize
      init_indexes
    end

    def call(data)
    end

    def init_indexes
      @indexes = {}
      Index.subclasses.each do |ind|
        (@indexes[ind.domain] ||= {})[ind.service] ||= []

      end
    end
  end
end
