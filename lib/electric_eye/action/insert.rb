module ElectricEye
  module Action
    class Insert
      def init_fields

      end

      def call(data)
        EsClient.index(index: self.index, body: document)
      end
    end
  end
end
