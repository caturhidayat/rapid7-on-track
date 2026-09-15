require "rails_helper"

RSpec.describe CsvImport, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:findings).dependent(:nullify) }
  it { is_expected.to validate_presence_of(:filename) }
  it {
    is_expected.to define_enum_for(:status)
      .with_values(pending: "pending", processing: "processing", completed: "completed", failed: "failed")
      .backed_by_column_of_type(:string)
  }

  it "defaults to pending status" do
    csv_import = CsvImport.new(user: create(:user), filename: "export.csv")
    expect(csv_import).to be_pending
  end
end
