class AddPreviewDataToArchivedResults < ActiveRecord::Migration[7.1]
  def change
    add_column :archived_results, :preview_data, :json
  end
end
