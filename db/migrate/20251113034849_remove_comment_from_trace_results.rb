class RemoveCommentFromTraceResults < ActiveRecord::Migration[7.1]
  def change
    remove_column :trace_results, :comment, :text
  end
end
