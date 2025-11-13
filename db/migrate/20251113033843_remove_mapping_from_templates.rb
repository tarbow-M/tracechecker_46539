class RemoveMappingFromTemplates < ActiveRecord::Migration[7.1]
  def change
    remove_column :templates, :mapping, :json
  end
end
