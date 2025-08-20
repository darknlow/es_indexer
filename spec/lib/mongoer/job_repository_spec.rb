RSpec.describe Mongoer::Persistence::JobRepository do
  let(:data) do
    {
      form_id: 1, 
      tenant_id: 1,
      user_id: 1,
      type: "new_order",
      data: [[{ "trans_id" => 1, "units" => 10 }]],
    }
  end

  describe ".processed" do
    context "when job is already processed" do
      let(:job) { create :job, data.merge(processed: true) }
      it { expect(described_class.processed(job.id, nil)).to be nil }
    end
    context "when job is not processed" do
      let(:job) { create :job, data.merge(processed: false) }
      let(:errors) { [{ "index" => 1, "msg" => "some error" }] }
      it { expect(described_class.processed(job.id, nil).id).to eq job.id }
      it do
        proc_job = described_class.processed(job.id, errors).reload
        expect(proc_job.processed).to eq true
        expect(proc_job.val_errors).to eq errors
      end
    end
  end

end
