class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  ## Association ----------------------------------------------
  has_many :parent_projects, dependent: :destroy
  has_many :templates, dependent: :destroy
  # has_many :logs

  ## Validation ------------------------------------------------
  # personal_num は必須かつ一意
  validates :personal_num, presence: true, uniqueness: true
  # name は必須
  validates :name, presence: true
end
