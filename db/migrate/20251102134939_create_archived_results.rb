class CreateArchivedResults < ActiveRecord::Migration[7.1]
  def change
    create_table :archived_results do |t|
      t.string :name             , null: false
      t.integer :diff_count
      t.references :child_project, null: false, foreign_key: { to_table: :projects } # カラム名（child_project）と参照テーブル（projects）が一致していないためto_table
      t.string :file_a_id
      t.string :file_b_id

      t.timestamps
    end
  end
end
