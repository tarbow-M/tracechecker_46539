class RemoveLastRunAndDiffCountFromProjects < ActiveRecord::Migration[7.1]
  def change
    remove_column :projects, :last_run, :datetime
    remove_column :projects, :diff_count, :integer
  end
end
