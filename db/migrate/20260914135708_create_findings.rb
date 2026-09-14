class CreateFindings < ActiveRecord::Migration[8.1]
  def change
    create_table :findings do |t|
      t.references :asset, null: false, foreign_key: true
      t.references :vulnerability, null: false, foreign_key: true
      t.references :csv_import, null: false, foreign_key: true
      t.integer :instance_count
      t.boolean :in_grace_period
      t.boolean :has_malware
      t.datetime :due_date
      t.boolean :past_due
      t.datetime :date_added
      t.datetime :first_found
      t.datetime :date_modified
      t.datetime :discovery_date
      t.datetime :reintroduced

      t.timestamps
    end

    add_index :findings, [ :asset_id, :vulnerability_id ], unique: true
  end
end
