class CreateAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :assets do |t|
      t.string :hostname
      t.string :ip_address
      t.string :asset_uid
      t.string :operating_system
      t.string :os_family
      t.string :os_vendor
      t.string :os_product
      t.string :os_version
      t.string :os_architecture
      t.decimal :os_certainty
      t.string :host_type
      t.string :host_type_source
      t.boolean :has_malware
      t.integer :malware_count
      t.boolean :pci_compliant
      t.decimal :risk_score
      t.decimal :raw_risk_score
      t.integer :critical_vulnerability_count
      t.integer :severe_vulnerability_count
      t.integer :moderate_vulnerability_count

      t.timestamps
    end
    add_index :assets, :asset_uid, unique: true
  end
end
