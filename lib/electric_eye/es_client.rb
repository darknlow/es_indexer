module ElectricEye
  class EsClient
    class << self
      def client
        @client ||= Elasticsearch::Client.new(
          url: ENV["ELASTIC_URL"], log: true)
      end

      def update
      end

      def index
      end

      def delete
      end
    end
  end
end
