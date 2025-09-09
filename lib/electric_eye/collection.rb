require "starman/configurable"

module ElectricEye
  class Collection
    include Starman::Configurable

    attr_reader :collection, :indexes
    attr_accessor :index, :source, :target, :assocs, :domain, :hooks, :delete_if

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

    def initialize(params)
      @assocs = params[:assocs]
      @index = params[:index_name]
      @domain = params[:domain]
      instance_exec(&params[:conf])
    end

    def index_change(data)
      @target = send(data[:action], data[:document])
      delete?
    end

    def delete?
      return unless conf.delete_if
      instance_exec

    def reindex(index_name)
    end

    def initialize_actions
      @actions = {}
      @actions[:create] = ElectricEye::Action::Insert.new(conf)
      @actions[:update] = ElectricEye::Action::Update.new(conf)
      @actions[:delete] = ElectricEye::Action::Delete.new(conf)
    end
  end
end
