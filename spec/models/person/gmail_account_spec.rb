require 'spec_helper'

describe Person::GmailAccount do
  let(:google_account) { build(:google_account) }
  let(:gmail_account) { Person::GmailAccount.new(google_account) }
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:person) { create(:person) }
  let(:user) { create(:user) }
  let(:client) { double }

  context '#client' do
    it "initializes a gmail client" do
      client = gmail_account.client
      client.authorization.access_token.should == google_account.token
    end
  end

  context '#folders' do
    it "returns a list of gmail folders/labels" do
      gmail_account.stub(:client).and_return(client)

      client.should_receive(:labels).and_return(double(all: []))

      gmail_account.folders
    end
  end

  context '#gmail' do
    it "refreshes the google account token if expired" do
      Gmail.stub(:connect).and_return(double(logout: true))
      google_account.expires_at = 1.hour.ago

      google_account.should_receive(:refresh_token!).once
      gmail_account.gmail {}
    end
  end

  context '#import_emails' do
    let(:sent_mailbox) { double }
    let(:all_mailbox) { double }
    let(:client) { double(logout: true) }
    let(:email) { double }
    let!(:email_address) { create(:email_address, person: person) }

    before do
      contact.people << person
      google_account.person = user
      google_account.save
      account_list.users << user

      Gmail.stub(:connect).and_return(client)
      client.stub(:mailbox).with('[Gmail]/Sent Mail').and_return(sent_mailbox)
      client.stub(:mailbox).with('[Gmail]/All Mail').and_return(all_mailbox)
    end

    it "logs a sent email" do
      sent_mailbox.should_receive(:emails).and_return([email])
      all_mailbox.should_receive(:emails).and_return([])

      gmail_account.should_receive(:log_email).once

      gmail_account.import_emails(account_list)
    end

    it "logs a received email" do
      sent_mailbox.should_receive(:emails).and_return([])
      all_mailbox.should_receive(:emails).and_return([email])

      gmail_account.should_receive(:log_email).once

      gmail_account.import_emails(account_list)
    end
  end

  context '#log_email' do
    let(:gmail_message) { double(message: double(multipart?: false, body: double(decoded: 'message body')),
                                 envelope: double(date: Time.zone.now, message_id: '1'),
                                 subject: 'subject') }

    it "creates a completed task" do
      expect {
      expect {
        gmail_account.log_email(gmail_message, account_list, contact, person.id, user.id, 'Done')
      }.to change(Task, :count).by(1)
      }.to change(ActivityComment, :count).by(1)

      task = Task.last
      task.subject.should == 'subject'
      task.completed.should == true
      task.completed_at.to_s(:db).should == gmail_message.envelope.date.to_s(:db)
      task.result.should == 'Done'
    end

    it "doesn't create a duplicate task" do
      create(:task, account_list: account_list, remote_id: gmail_message.envelope.message_id, source: 'gmail')

      expect {
      expect {
        gmail_account.log_email(gmail_message, account_list, contact, person.id, user.id, 'Done')
      }.not_to change(Task, :count)
      }.to change(ActivityContact, :count).by(1)
    end

    it "creates a message" do
      expect {
        gmail_account.log_email(gmail_message, account_list, contact, person.id, user.id, 'Done')
      }.to change(Message, :count).by(1)

      task = Message.last
      task.subject.should == 'subject'
      task.body.should == 'message body'
      task.remote_id.should == gmail_message.envelope.message_id
      task.sent_at.to_s(:db).should == gmail_message.envelope.date.to_s(:db)
    end

    it "doesn't create a duplicate message" do
      create(:message, account_list: account_list, remote_id: gmail_message.envelope.message_id, source: 'gmail')

      expect {
        gmail_account.log_email(gmail_message, account_list, contact, person.id, user.id, 'Done')
      }.not_to change(Message, :count)
    end
  end
end
