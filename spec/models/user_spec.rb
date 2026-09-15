require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to have_secure_password }
  it { is_expected.to have_many(:sessions).dependent(:destroy) }

  it "normalizes email_address to a stripped, downcased value" do
    user = create(:user, email_address: "  Mixed.Case@Example.com ")
    expect(user.email_address).to eq("mixed.case@example.com")
  end

  it "enforces email_address uniqueness at the database level" do
    create(:user, email_address: "duplicate@example.com")

    expect {
      create(:user, email_address: "duplicate@example.com")
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "authenticates with the correct password" do
    user = create(:user, password: "correct-password", password_confirmation: "correct-password")

    expect(user.authenticate("correct-password")).to eq(user)
    expect(user.authenticate("wrong-password")).to be false
  end
end
