module Mongoer
  module Service
    class Producer
      attr_reader :job, :result, :result_conf, :service
      
      def initialize(service, result_conf)
        @service = service
        @result_conf = result_conf
      end

      def call(job)
        @job = job
        messages = [ forms_msg ]
        messages << gluon_msg if result_conf
        Karafka.producer.produce_many_sync(messages)
      end

      private

      def forms_msg
        payload = {
          service: :process_form,
          data: {
            form_id: job.form_id,
            errors: job.val_errors,
          }
        }
        { payload: payload.to_json, 
          topic: Mongoer::Conf.get_forms_topic }
      end

      def gluon_msg
        payload = {
          data: gluon_data,
          service: service,
          domain: Mongoer::Conf.domain
        }
        { payload: payload.to_json, 
          topic: Mongoer::Conf.get_gluon_topic }
      end

      def gluon_data
        result = instance_exec(&result_conf[:body])
        result.merge!(
          tenant_id: job.tenant_id,
          origin_id: job.id,
          user_id: job.user_id)
        result
      end
    end
  end
end
