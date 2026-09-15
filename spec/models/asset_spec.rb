require "rails_helper"

RSpec.describe Asset, type: :model do
  it { is_expected.to validate_presence_of(:asset_uid) }
  it { is_expected.to validate_presence_of(:hostname) }
  it { is_expected.to validate_uniqueness_of(:asset_uid) }
  it { is_expected.to have_many(:findings).dependent(:destroy) }
  it { is_expected.to have_many(:vulnerabilities).through(:findings) }
end
