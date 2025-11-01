class Project < ApplicationRecord
# --- Associations ---
  belongs_to :parent_project

  # --- Validations ---
  validates :name, presence: true
end
