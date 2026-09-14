class Finding < ApplicationRecord
  belongs_to :asset
  belongs_to :vulnerability
  belongs_to :csv_import

  validates :vulnerability_id, uniqueness: { scope: :asset_id }

  scope :past_due, -> { where(past_due: true) }
  scope :open, -> { where(past_due: false) }
end
