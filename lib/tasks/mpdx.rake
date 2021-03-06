namespace :mpdx do

  task set_special: :environment do
    AccountList.find_each do |al|
      al.contacts.includes(:donor_accounts).find_each do |contact|
        if contact.status.blank? && contact.donor_accounts.present?
          contact.update_attributes(status: 'Partner - Special')
        end
      end
    end
  end

  task merge_contacts: :environment do
    AccountList.where("id > 125").find_each do |al|
      puts al.id
      al.merge_contacts
    end
  end

  task merge_accounts: :environment do

    def merge_account_lists
      AccountList.order('created_at').each do |al|
        other_list = AccountList.where(name: al.name).where("id <> #{al.id} AND name like 'Staff Account (%'").first
        if other_list# && other_contact.donor_accounts.first == contact.donor_accounts.first
          puts other_list.name
          al.merge(other_list)
          al.merge_contacts
          merge_account_lists
          return
        end
      end
    end
    merge_account_lists
  end

  task merge_donor_accounts: :environment do

    def merge_donor_accounts
      account_numbers = DonorAccount.connection.select_values("select account_number, organization_id from donor_accounts where account_number <> '' group by account_number, organization_id having count(*) > 1")
      DonorAccount.where(account_number: account_numbers).order('created_at').each do |al|
        other_account = DonorAccount.where(account_number: al.account_number, organization_id: al.organization_id).where("id <> #{al.id}").first
        if other_account
          puts other_account.account_number
          al.merge(other_account)
          merge_donor_accounts
          return
        end
      end
    end
    merge_donor_accounts
  end

  task address_cleanup: :environment do
    def merge_addresses(contact)
      addresses = contact.addresses.order('addresses.created_at')
      if addresses.length > 1
        addresses.reload
        addresses.each do |address|
          other_address = addresses.detect {|a| a == address && a.id != address.id}
          if other_address
            address.merge(other_address)
            merge_addresses(contact)
            return
          end
        end
      end
    end

    Contact.includes(:addresses).where("addresses.id is not null AND (addresses.country is null or addresses.country = 'United States' or addresses.country = '' or addresses.country = 'United States of America')").find_each do |c|
      merge_addresses(c)
    end
  end
end


