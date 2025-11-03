class Log < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  belongs_to :project, optional: true

  # --- Validations ---
  validates :action_type, presence: true
end
