class Asset < ApplicationRecord
  has_many :findings, dependent: :destroy
  has_many :vulnerabilities, through: :findings

  validates :asset_uid, presence: true, uniqueness: true
  validates :hostname, presence: true
end
