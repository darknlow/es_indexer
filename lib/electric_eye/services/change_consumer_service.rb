module ElectricEye
  class ChangeConsumerService < Starman::Service::Base
    domain :default

    attr_accessor :indexes

    def initialize
      map_coll_to_index
    end

    def call(data)
      indexes[domain][name].index data
    end

    private

    def map_coll_to_index
       @indexes = {}
       Index.subclasses.each do |ind|
         ind.conf.list[:collections].each do |src|
           name = src[:args].first
           @indexes[ind.domain] ||= {})[name] = ind.new
         end
       end
    end
  end
end
