require 'async'

class Person::PrayerLettersAccount < ActiveRecord::Base
  extend Person::Account

  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :general
  SERVICE_URL = 'https://www.prayerletters.com/api/v1/contacts'

  validates :token, :secret, :person_id, presence: true

  def self.find_or_create_from_auth(auth_hash, person)
    @rel = person.prayer_letters_accounts
    @remote_id = auth_hash['uid']
    params = auth_hash.credentials
    @attributes = {
                    token: params.token,
                    secret: params.secret
                  }
    if @account = person.prayer_letters_account
      @account.update_attributes(@attributes)
    else
      @rel.create!(@attributes)
    end
  end

  def validate_token
    return false unless token.present? && secret.present?
    begin
      contacts(limit: 1) # If this works, the tokens are valid
      self.valid_token = true
    rescue RestClient::Unauthorized => e
      self.valid_token = false
    end
    update_column(:valid_token, valid_token) unless new_record?
    valid_token
  end

  def to_s
    person.to_s
  end

  def get_response(method, params = nil)
    RestClient::Request.execute(:method => method, :url => SERVICE_URL, :payload => params, :timeout => -1) { |response, request, result, &block|
      ap request
      ap response
      ap result
      response
    }

  end



end

