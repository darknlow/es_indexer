module ElectricEye
  module Action
    class Base

      attr_accessor :conf

      def initialize(conf)
        @conf = conf
      end

      def common
        @target ||= {}
        fields.each { |f| result[f] = record[f] }
        conf.list.each do |f|
          name = f[:agrs].first
          value = instance_exec(&f[:body])
          result[name] = value
        end
        embedded
        result
      end

      def hook_delta(hook)
        hook_fields = conf.send(hook)[:body]
        @fields = conf.fields[:args].merge
      end
    end
  end
end
