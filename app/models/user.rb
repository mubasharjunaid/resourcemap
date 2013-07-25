class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :token_authenticatable
  before_create :reset_authentication_token
  # Setup accessible (or protected) attributes for your model attr_accessible :email, :password, :password_confirmation, :remember_me, :phone_number
  has_many :memberships
  has_many :channels
  has_many :layer_memberships
  has_many :collections, through: :memberships, order: 'collections.name ASC'
  has_one :user_snapshot

  attr_accessor :is_guest

  # In order to use it in the ability file
  def readable_layer_ids
    layer_memberships.where(:read => true).map(&:layer_id).uniq
  end

  def create_collection(collection)
    return false unless collection.save
    memberships.create! collection_id: collection.id, admin: true
    collection.register_gateways_under_user_owner(self)
    collection
  end

  def admins?(collection)
    memberships.where(:collection_id => collection.id).first.try(:admin?)
  end

  def belongs_to?(collection)
    memberships.where(:collection_id => collection.id).exists?
  end

  def membership_in(collection)
    memberships.where(:collection_id => collection.id).first
  end

  def display_name
    email
  end

  def can_write_field?(field, collection, field_es_code)
    return false unless field

    membership = membership_in(collection)
    return true if membership.admin?

    lm = LayerMembership.where(user_id: self.id, collection_id: collection.id, layer_id: field.layer_id).first
    lm && lm.write
  end

  def activities
    Activity.where(collection_id: memberships.pluck(:collection_id))
  end

  def can_view?(collection, option)
    return collection.public if collection.public
    membership = self.memberships.where(:collection_id => collection.id).first
    return false unless membership
    return membership.admin if membership.admin

    return true if(validate_layer_read_permission(collection, option))
    false
  end

  def can_update?(site, properties)
    membership = self.memberships.where(:collection_id => site.collection_id).first
    return false unless membership
    return membership.admin if membership.admin?
    return true if(validate_layer_write_permission(site, properties))
    false
  end

  def validate_layer_write_permission(site, properties)
    properties.each do |prop|
      field = Field.where("code=? && collection_id=?", prop.values[0].to_s, site.collection_id).first
      return false if field.nil?
      lm = LayerMembership.where(user_id: self.id, collection_id: site.collection_id, layer_id: field.layer_id).first
      return false if lm.nil?
      return false if(!lm && lm.write)
    end
    return true
  end

  def validate_layer_read_permission(collection, field_code)
    field = Field.where("code=? && collection_id=?", field_code, collection.id).first
    return false if field.nil?
    lm = LayerMembership.where(user_id: self.id, collection_id: collection.id, layer_id: field.layer_id).first
    return false if lm.nil?
    return false if(!lm && lm.read)
    return true
  end

  def self.encrypt_users_password
    all.each { |user| user.update_attributes password: user.encrypted_password }
  end

  def get_gateway
    channels.first
  end

  def active_gateway
    channels.where("channels.is_enable=?", true)
  end

  def update_successful_outcome_status
    self.success_outcome = layer_count? & collection_count? & site_count? & gateway_count?
  end

  def collections_i_admin
    self.memberships.includes(:collection).where(:admin => true).map {|m| { id: m.collection.id, name: m.collection.name }}
  end
end
