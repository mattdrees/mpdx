class EmailAddressSerializer < ActiveModel::Serializer
  attributes :id, :email, :primary, :created_at, :updated_at
end
