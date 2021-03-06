class AccountMailer < ActionMailer::Base
  default from: "support@mpdx.org"

  def invalid_mailchimp_key(account_list)
    mail to: account_list.users.collect(&:email).compact.collect(&:email),
         subject: _('Mailchimp API Key no longer valid')
  end

  def mailchimp_required_merge_field(account_list)
    mail to: account_list.users.collect(&:email).compact.collect(&:email),
         subject: _('Mailchimp List is requiring an additional merge field')
  end

end

