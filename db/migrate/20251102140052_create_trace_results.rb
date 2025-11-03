class CreateTraceResults < ActiveRecord::Migration[7.1]
  def change
    create_table :trace_results do |t|
      t.references :archived_result, null: false, foreign_key: true
      t.string :key                , null: false
      t.string :flag               , null: false
      t.text :comment
      t.json :target_cell # (ハイライト座標 {row:X, col:Y} などを保存)
      
      t.timestamps
    end
  end
end
