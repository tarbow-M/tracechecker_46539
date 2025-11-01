class ParentProject < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  
  # 子プロジェクト (Projects) との関連
  has_many :projects, dependent: :destroy

  # ActiveStorage を使ったファイル添付 (複数可)
  has_many_attached :files

  # --- Validations ---
  validates :name, presence: true
end