class ContactSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :name, :pledge_amount, :pledge_frequency, :pledge_start_date, :status, :deceased,
             :notes, :notes_saved_at, :next_ask, :never_ask, :likely_to_give, :church_name, :send_newsletter,
             :magazine, :last_activity, :last_appointment, :last_letter, :last_phone_call, :last_pre_call,
             :last_thank

  has_many :people, :addresses

end
