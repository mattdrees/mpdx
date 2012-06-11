require_dependency 'address_methods'
class DonorAccount < ActiveRecord::Base
  include AddressMethods

  has_many :master_person_donor_accounts, dependent: :destroy
  has_many :master_people, through: :master_person_donor_accounts
  has_many :people, through: :master_people
  has_many :donations, dependent: :destroy
  has_many :contact_donor_accounts
  has_many :contacts, through: :contact_donor_accounts
  belongs_to :organization
  belongs_to :master_company

  attr_accessible :name, :total_donations

  def primary_master_person
    master_people.where('master_person_donor_accounts.primary' => true).first
  end

  def link_to_contact_for(account_list)
    contact = account_list.contacts.where('donor_accounts.id' => id).includes(:donor_accounts).first # already linked

    unless contact
      # Try to find a contact for this user that matches based on name, address, or person details
      account_list.contacts.each do |c|
        contact = c if c.name == name
      end
    end

    unless contact
      # Try to find a contact for this user that matches based on address
      addresses.each do |a|
        next unless a.not_blank? && a.city.present?
        if address = account_list.addresses.where(a.attributes.with_indifferent_access.slice(:street, :city, :state, :country, :postal_code)).first
          contact = address.addressable
        end
      end
    end

    contact ||= Contact.create_from_donor_account(self, account_list)
    contact.donor_accounts << self unless contact.donor_accounts.include?(self)
    contact
  end

  def update_donation_totals(donation)
    self.first_donation_date = donation.donation_date if first_donation_date.nil? || donation.donation_date < first_donation_date
    self.last_donation_date = donation.donation_date if last_donation_date.nil? || donation.donation_date > last_donation_date
    self.total_donations = self.total_donations.to_f + donation.amount
    save(validate: false)
  end

end
