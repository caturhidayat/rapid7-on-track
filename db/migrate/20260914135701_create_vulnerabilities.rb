class CreateVulnerabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :vulnerabilities do |t|
      t.string :vulnerability_uid
      t.string :title
      t.string :severity
      t.integer :severity_rank
      t.integer :severity_score
      t.integer :pci_severity
      t.decimal :cvss_score
      t.string :cvss_access_vector
      t.string :cvss_access_complexity
      t.string :cvss_authentication
      t.string :cvss_confidentiality_impact
      t.string :cvss_integrity_impact
      t.string :cvss_availability_impact
      t.integer :skill_level_rank
      t.boolean :has_exploits
      t.integer :exploit_count
      t.datetime :date_published

      t.timestamps
    end
    add_index :vulnerabilities, :vulnerability_uid, unique: true
  end
end
