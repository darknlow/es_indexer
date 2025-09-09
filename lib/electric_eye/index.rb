require "starman/configurable"
require "active_support/inflector"

module ElectricEye
  class Index
    include Starman::Configurable

    base_service true

    list_attr :collection, list: :collections
    list_attr :assoc, list: :assocs
    key_attr :delete_if
    key_attr :broadcast

    attr_accessor :collection, :target

    def initialize
      @collections = {}
      conf.list[:collections].each do |c|
        mongo_col = c[:args].first
        @collections[mongo_col] = Collection.new(
          index_name: self.index_name,
          conf: c[:body],
          assocs: c.list[:assocs],
          domain: self.domain)
      end
    end

    def index_change(data)
      domain = data[:domain]
      name = data[:collection]
      @target = @collections[collection].index_change data
      delete?
    end

    def delete?
      return unless conf.delete_if && instance_exec(&conf.delete_if[:body])
      EsClient.delete(target)
    end

    def reindex(version=nil)
      # Create new index with new version
      collections.values.each do |coll|
      end
    end

    def self.coll_domain
      @coll_domain ||= self.class.name.doconstantize.split(":").last.underscore
    end

    def self.index
      @index ||= "#{read_alias}_#{cluster_ts}"
    end

    def self.read_alias
      @read_alias ||= self.class.name.tableize
    end

    def self.write_alias
      @write_alias ||= "#{read_alias}_#{es_version}_#{stream_version}"
    end
  end
end

