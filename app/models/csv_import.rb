class CsvImport < ApplicationRecord
  belongs_to :user
  has_many :findings, dependent: :nullify

  validates :filename, presence: true

  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" }, default: "pending"
end
