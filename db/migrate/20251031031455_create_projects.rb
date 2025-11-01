class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.references :parent_project, null: false, foreign_key: true
      t.string :name              , null: false
      t.string :status
      t.datetime :last_run
      t.integer :diff_count
      t.boolean :is_locked        , default: false

      t.timestamps
    end
  end
end
