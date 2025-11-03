class ArchivedResult < ApplicationRecord
    # --- Associations ---
    # "child_project" という名前で "Project" モデルを参照する
    belongs_to :child_project, class_name: 'Project'
    
    # (次回作成する TraceResult との関連)
    has_many :trace_results, dependent: :destroy

    # --- Validations ---
    validates :name, presence: true
end
