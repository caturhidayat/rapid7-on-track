class AddStatusToFindings < ActiveRecord::Migration[8.1]
  def change
    add_column :findings, :status, :string, default: "open", null: false
    add_column :findings, :closed_at, :datetime

    add_index :findings, :status
  end
end
