class CreateCsvImports < ActiveRecord::Migration[8.1]
  def change
    create_table :csv_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :filename
      t.integer :rows_count
      t.string :status
      t.text :error_message

      t.timestamps
    end
  end
end
