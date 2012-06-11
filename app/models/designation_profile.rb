class DesignationProfile < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization
  has_many :designation_profile_accounts, dependent: :destroy
  has_many :designation_accounts, through: :designation_profile_accounts
  has_one :account_list
  after_create :find_or_create_account_list, unless: Proc.new { |p| p.skip_account_list }

  attr_accessor :skip_account_list
  attr_accessible :skip_account_list, :name, :code

  scope :for_org, lambda {|org_id| where(organization_id: org_id)}

  def to_s() name; end

  def designation_account
    designation_accounts.first
  end

  def find_or_create_account_list
    unless account_list
      self.account_list = AccountList.where(designation_profile_id: id).first_or_create!({name: name, creator_id: user.id}, without_protection: true)
      self.account_list.users << user unless account_list.users.include?(user)
    end
    account_list
  end

end
