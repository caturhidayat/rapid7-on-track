class Finding < ApplicationRecord
  belongs_to :asset
  belongs_to :vulnerability
  belongs_to :csv_import

  validates :vulnerability_id, uniqueness: { scope: :asset_id }

  enum :status, { open: "open", closed: "closed" }, default: "open", validate: true

  scope :past_due, -> { where(past_due: true) }
end
