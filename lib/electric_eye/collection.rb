require "starman/configurable"

module ElectricEye
  class Collection
    include Starman::Configurable

    attr_reader :collection, :indexes
    attr_accessor :index, :source, :target, :assocs, :domain, :hooks

    key_attr :id
    key_attr :fields
    key_attr :on_create
    key_attr :on_delete
    key_attr :on_update
    key_attr :embedded
    list_attr :has_one, list: :has_ones
    list_attr :field, list: :fields


    base_service true
    list_attr :index

    def initialize(index)
      @collection = self.class.service
    end

    def call(data)
      indexes.each do |index|
        index.call(collection, data)
      end
    end


  def initialize(params)
    @assocs = params[:assocs]
    @index = params[:index]
    @domain = params[:domain]
  end

  def call(data)
    send(data[:action], data[:document])
  end

  def add_index(ind)
    indexes << ind
  end

  def initialize_actions
    @actions = {}
    @actions[:create] = ElectricEye::Action::Insert.new(conf)
    @actions[:update] = ElectricEye::Action::Update.new(conf)
    @actions[:delete] = ElectricEye::Action::Delete.new(conf)
  end
end
