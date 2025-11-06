class AddMappingToTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :templates, :mapping, :json
  end
end
