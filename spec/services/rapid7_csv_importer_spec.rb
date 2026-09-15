require "rails_helper"

RSpec.describe Rapid7CsvImporter do
  let(:user) { create(:user) }

  def uploaded_fixture(name)
    File.open(Rails.root.join("spec/fixtures/files/#{name}"))
  end

  describe "initial import" do
    subject(:result) { described_class.new(uploaded_fixture("rapid7_export_initial.csv"), user: user).call }

    it "creates one asset per distinct Asset Unique Identifier" do
      result
      expect(Asset.pluck(:asset_uid)).to contain_exactly("asset-uid-a", "asset-uid-b")
    end

    it "creates one vulnerability per distinct Vulnerability Unique Identifier" do
      result
      expect(Vulnerability.pluck(:vulnerability_uid)).to contain_exactly(
        "google-chrome-cve-2026-2441", "microsoft-office-obsolete", "rarlab-winrar-cve-2023-38831"
      )
    end

    it "opens a finding for every row and reports zero closures" do
      expect(result.rows_processed).to eq(3)
      expect(result.closed_count).to eq(0)
      expect(result.errors).to be_empty
      expect(Finding.open.count).to eq(3)
    end

    it "marks the csv_import completed" do
      expect(result.csv_import).to be_completed
      expect(result.csv_import.rows_count).to eq(3)
    end
  end

  describe "re-import reconciliation" do
    before { described_class.new(uploaded_fixture("rapid7_export_initial.csv"), user: user).call }

    subject(:result) { described_class.new(uploaded_fixture("rapid7_export_update.csv"), user: user).call }

    it "closes findings whose pairing no longer appears in the new export" do
      result

      closed_uids = Finding.closed.joins(:vulnerability).pluck("vulnerabilities.vulnerability_uid")
      expect(closed_uids).to contain_exactly("google-chrome-cve-2026-2441", "rarlab-winrar-cve-2023-38831")
      expect(result.closed_count).to eq(2)
    end

    it "sets closed_at on newly-closed findings" do
      result

      Finding.closed.each { |finding| expect(finding.closed_at).to be_present }
    end

    it "opens a new finding for a pairing introduced in the new export" do
      result

      new_finding = Finding.joins(:vulnerability).find_by(vulnerabilities: { vulnerability_uid: "microsoft-dot_net-obsolete" })
      expect(new_finding).to be_open
    end

    it "keeps a still-present pairing open and refreshes its metadata" do
      result

      still_open = Finding.joins(:vulnerability).find_by(vulnerabilities: { vulnerability_uid: "microsoft-office-obsolete" })
      expect(still_open).to be_open
      expect(still_open.due_date).to eq(Time.zone.parse("2026-09-09 23:03:30"))
    end

    context "when a previously-closed finding reappears in a later export" do
      before do
        described_class.new(uploaded_fixture("rapid7_export_update.csv"), user: user).call
      end

      it "reopens it and clears closed_at" do
        described_class.new(uploaded_fixture("rapid7_export_initial.csv"), user: user).call

        reopened = Finding.joins(:vulnerability).find_by(vulnerabilities: { vulnerability_uid: "google-chrome-cve-2026-2441" })
        expect(reopened).to be_open
        expect(reopened.closed_at).to be_nil
      end
    end
  end
end
