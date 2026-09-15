require "rails_helper"

RSpec.describe Finding, type: :model do
  it { is_expected.to belong_to(:asset) }
  it { is_expected.to belong_to(:vulnerability) }
  it { is_expected.to belong_to(:csv_import) }
  it {
    is_expected.to define_enum_for(:status)
      .with_values(open: "open", closed: "closed")
      .backed_by_column_of_type(:string)
  }

  it "defaults to open status" do
    finding = create(:finding)
    expect(finding).to be_open
  end

  it "is invalid when the asset already has a finding for the same vulnerability" do
    existing = create(:finding)
    duplicate = build(:finding, asset: existing.asset, vulnerability: existing.vulnerability)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:vulnerability_id]).to be_present
  end

  describe "scopes" do
    it ".past_due returns only findings flagged past_due" do
      overdue = create(:finding, past_due: true)
      create(:finding, past_due: false)

      expect(Finding.past_due).to contain_exactly(overdue)
    end

    it ".open and .closed partition by status" do
      open_finding = create(:finding, status: "open")
      closed_finding = create(:finding, status: "closed")

      expect(Finding.open).to contain_exactly(open_finding)
      expect(Finding.closed).to contain_exactly(closed_finding)
    end
  end
end
