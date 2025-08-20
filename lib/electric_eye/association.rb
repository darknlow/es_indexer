require "starman/configurable"
require "activesupport/inflector"

module ElectricEye
  class Association
    include Starman::Configurable

    key_attr :fields
    key_attr :target
    list_attr :has_one, list: :has_ones
    list_attr :assoc, list: :assocs

    def initialize(source_field)
      @source_field = source_field
    end

    def get(target)
      response = Elastic.client.search(
        index: index,
        body: { query: { match: { id: id }}})
      response['hits']['hits']
    end

    def enrich(target)
      record = get(target)

    end

    def index
      @index ||= self.class.name.tableize
    end

    def domain(dom=nil)
      return @domain = dom if dom
      return @domain if @domain
      @domain = self.class.demodulize
    end

    def assocs
      return @assocs if @assocs
      @assocs = {}
      conf.list[:assocs].each do |c|
        name = c[:args].first
        @assocs[name] = Class.new(self.class) do
          instance_exec(&c[:body])
          domain domain
        end.new
      end
      conf.list[:has_ones].each do |c|
        name = c[:args].first
        next if @assocs[name]
        @assocs[name] = (domain + name).constantize.new
      end
    end
  end
end
