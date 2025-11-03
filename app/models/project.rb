class Project < ApplicationRecord
# --- Associations ---
  belongs_to :parent_project
  # (foreign_key: を指定し、"child_project_id" カラムを使うよう指示)
  has_many :archived_results, foreign_key: :child_project_id, dependent: :destroy
  has_many :logs, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true
end
