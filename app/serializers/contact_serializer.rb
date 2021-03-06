class ContactSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  cached
  delegate :cache_key, to: :object

  embed :ids, include: true

  ATTRIBUTES = [:id, :name, :pledge_amount, :pledge_frequency, :pledge_start_date, :status, :deceased,
                :notes, :notes_saved_at, :next_ask, :never_ask, :likely_to_give, :church_name, :send_newsletter,
                :magazine, :last_activity, :last_appointment, :last_letter, :last_phone_call, :last_pre_call,
                :last_thank, :avatar]

  attributes *ATTRIBUTES

  INCLUDES = [:people, :addresses]
  INCLUDES.each do |i|
    has_many i
  end

  def attributes
    hash = super

    if scope.is_a?(Hash) && scope[:since]
      hash[:deleted_people] = Version.where(item_type: 'Person', event: 'destroy', related_object_type: 'Contact', related_object_id: id).where("created_at > ?", Time.at(scope[:since].to_i)).pluck(:item_id)
      hash[:deleted_addresses] = Version.where(item_type: 'Address', event: 'destroy', related_object_type: 'Contact', related_object_id: id).where("created_at > ?", Time.at(scope[:since].to_i)).pluck(:item_id)
    end

    # added by Spencer Oberstadt to support old api access on 5/12/13
    # remove in a few weeks
    hash[:addresses] = object.address_ids if object.address_ids.count > 0

    hash
  end

  def avatar
    contact_exhibit = exhibit(object)
    contact_exhibit.avatar(:large)
  end

  INCLUDES.each do |relationship|
    define_method(relationship) do
      #add_since(object.send(relationship))
      object.send(relationship)
    end
  end
end
