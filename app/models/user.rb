class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  ## Association ----------------------------------------------
  has_many :parent_projects, dependent: :destroy
  has_many :templates      , dependent: :destroy
  has_many :logs           , dependent: :destroy

  ## Validation ------------------------------------------------
  # personal_num は必須かつ一意
  validates :personal_num, presence: true, uniqueness: true, format: { with: /\A\d+\z/, message: "は数字で入力してください" }
  # name は必須
  validates :name, presence: true
end
