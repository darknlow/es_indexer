RSpec.describe Mongoer::Service::Producer do
  let(:producer) { described_class.new(service, result_conf) }
  let(:init_producer) do
    producer.instance_variable_set(:@job, job)
    producer.instance_variable_set(:@result_conf, result_conf)
  end
  let(:result_conf) { { body: Proc.new { { key: "value" } } } }
  let(:service) { "new_order" }
  let(:job) { build :job, val_errors: "Some Error" }
  let(:payload) { ::JSON.parse(msg[:payload], symbolize_names: true) }
  let(:gluon_topic) { Mongoer::Conf.gluon_topic[:args].first }
  let(:forms_topic) { Mongoer::Conf.forms_topic[:args].first }

  describe ".forms_msg" do
    let(:msg) { producer.send(:forms_msg) }
    before(:each) { init_producer }
    it { expect(payload[:data][:form_id]).to eq job.form_id }
    it { expect(payload[:data][:errors]).to eq job.val_errors }
    it { expect(msg[:topic]).to eq forms_topic }
  end

  describe ".gluon_msg" do
    let(:msg) { producer.send(:gluon_msg) }
    before(:each) { init_producer }
    it { expect(payload[:data][:key]).to eq "value" }
    it { expect(payload[:service]).to eq service }
    it { expect(msg[:topic]).to eq gluon_topic }
  end

  describe ".call" do
    before(:each) { producer.call(job) }
    let(:produced) { karafka.produced_messages }
    let(:gluon) { produced.last }
    let(:forms) { produced.first }
    it { expect(produced.size).to eq 2 }
    it { expect(gluon[:topic]).to eq gluon_topic }
    it { expect(::JSON.parse(gluon[:payload])["service"]).to eq service }
    it { expect(forms[:topic]).to eq forms_topic }
    it { expect(::JSON.parse(forms[:payload])["data"]["form_id"]).to eq job.form_id }
  end
end
