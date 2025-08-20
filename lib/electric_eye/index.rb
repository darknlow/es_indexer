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
        @collections[mongo_col] = Source.new(
          conf: c[:body], 
          assocs: c.list[:assocs],
          domain: self.domain)
      end
    end

    def index(data)
      domain = data[:domain]
      name = data[:collection]
      document = @collections[collection].call data
      EsClient.index(index: self.index, body: document)
    end

    def self.domain
      @domain ||= self.class.name.doconstantize.split(":").last.underscore
    end

    def self.index
      @index ||= self.class.name.tableize
    end
  end
end
