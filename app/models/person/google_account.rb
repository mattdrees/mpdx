require 'google/api_client'
require 'gmail'
class Person::GoogleAccount < ActiveRecord::Base
  extend Person::Account

  # attr_accessible :email

  def self.find_or_create_from_auth(auth_hash, person)
    @rel = person.google_accounts
    creds = auth_hash.credentials
    @remote_id = auth_hash.uid
    expires_at = creds.expires ? Time.at(creds.expires_at) : nil
    @attributes = {
      remote_id: @remote_id,
      token: creds.token,
      refresh_token: creds.refresh_token,
      expires_at: expires_at,
      email: auth_hash.info.email,
      valid_token: true}
    super
  end

  def to_s
    email
  end

  def self.one_per_user?() false; end

  def queue_import_data

  end

  def email_body(email)
    email.text_part.body.decoded
  end

  def client
    unless @client
      @client = Google::APIClient.new(application_name: 'MPDX', application_version: '1.0')
      @client.authorization.access_token = token
    end
    @client
  end

  def plus
    @plus ||= client.discovered_api('plus')
  end

  def imap
    refresh_token! if token_expired?

    unless @imap
      @imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
      @imap.authenticate('XOAUTH2', email, token)
    end
    @imap
  end

  def token_expired?
    expires_at < Time.now
  end

  def contacts
    refresh_token! if token_expired?

    unless @contacts
      client = OAuth2::Client.new(APP_CONFIG['google_key'], APP_CONFIG['google_secret'])
      oath_token = OAuth2::AccessToken.new(client, token)
      contact_user = GoogleContactsApi::User.new(oath_token)
      @contacts = contact_user.contacts
    end
    @contacts
  end

  def refresh_token!
    # Refresh auth token from google_oauth2.
    params = {
        client_id: APP_CONFIG['google_key'],
        client_secret: APP_CONFIG['google_secret'],
        refresh_token: refresh_token,
        grant_type: 'refresh_token'
    }
    RestClient.post('https://accounts.google.com/o/oauth2/token', params, content_type: 'application/x-www-form-urlencoded') {|response, request, result, &block|
      if response.code == 200
        ap response
        json = JSON.parse(response)
        self.token = json['access_token']
        self.expires_at = 59.minutes.from_now
        save
      else
        raise response.inspect
      end
    }
  end

end
