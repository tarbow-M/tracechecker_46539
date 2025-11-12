class ArchivedResult < ApplicationRecord
    # --- Associations ---
    # "child_project" という名前で "Project" モデルを参照する
    belongs_to :child_project, class_name: 'Project'
    has_many :trace_results, dependent: :destroy
    belongs_to :file_a, class_name: 'ActiveStorage::Attachment', foreign_key: 'file_a_id'
    belongs_to :file_b, class_name: 'ActiveStorage::Attachment', foreign_key: 'file_b_id'

    # --- PostgreSQLのJsonb型に対応するためのメソッド ---
    def preview_data
      read_attribute(:preview_data) || {}
    end
    
    # --- Validations ---
    validates :name, presence: true
end
