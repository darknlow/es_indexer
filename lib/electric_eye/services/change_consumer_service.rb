module ElectricEye
  class ChangeConsumerService < Starman::Service::Base
    custom_domain :default

    attr_accessor :collections

    def initialize
      init_collections
    end

    def call(data)
      domain = data[:domain]
      coll = data[:collection]
      collections[domain][coll].each do |coll|
        coll.index_change data
      end
    end

    private

    def init_collections
       @collections = {}
       Index.subclasses.each do |ind|
         ind.conf.list[:collections].each do |src|
           name = src[:args].first
           # Multiple collections for multiple views (api / cms etc.)
           (@collections[ind.coll_domain] ||= {})[name] ||= []) << 
             init_single_coll(src, ind)
         end
       end
    end

    def init_single_coll(conf, index)
      coll = Collection.new do
        instance_exec(&conf[:body])
      end
      coll.domain = index.domain
      coll.index_name = index.index_name
      coll.delete_if = index.delete_if[:body]
      coll
    end
  end
end
