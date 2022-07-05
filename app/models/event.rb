class Event < ApplicationRecord
  AVAILIABLE_SETTINGS = %w[private protected public].freeze
  # maybe include some sort of proc to indicate wether user needs
  # all or any of the required perms to perform action
  REQUIRED_PERMISSIONS = {
    create: {
      'moderate' => [['owner'], 'all_required'],
      'attend' => [['current_user'], 'all_required'],
      'accept_invite' => [%w[moderate owner], 'one_required']
    },
    destroy: {
      'moderate' => [['owner'], 'one_required'],
      'attend' => [%w[current_user moderate owner], 'one_required'],
      'accept_invite' => [%w[moderate owner], 'one_required']
    }
  }.freeze

  belongs_to :creator, class_name: 'User'

  has_many :user_event_permissions, dependent: :destroy
  has_many :user_relations, through: :user_event_permissions, source: :user

  validates :date, presence: true
  validates :location, presence: true
  validates :creator_id, presence: true
  validates :name, presence: true
  validates :desc, presence: true
  validates :event_privacy, inclusion: { in: AVAILIABLE_SETTINGS }
  validates :display_privacy, inclusion: AVAILIABLE_SETTINGS
  validates :attendee_privacy, inclusion: AVAILIABLE_SETTINGS

  def self.past
    where('date < ?', DateTime.now)
  end

  def self.future
    where('date > ?', DateTime.now)
  end

  def self.display_public
    where(display_privacy: 'public')
  end

  def future
    date > DateTime.now
  end

  def past
    date < DateTime.now
  end

  def accepted_invites
    user_event_permissions.where(permission_type: 'attend').includes(:user).map(&:user)
  end

  def pending_invites
    user_event_permissions.where(permission_type: 'accept_invite').includes(:user).map(&:user)
  end

  # needs fixing some day
  def privacy_perms(privacy_type, current_user)
    held_perms = current_user.held_event_perms(id, current_user.id)
    case privacy_type
    when 'private'
      one_required(held_perms, %w[attend accept_invite moderate owner])
    when 'protected'
      one_required(held_perms, %w[attend accept_invite moderate owner])
    when 'public'
      true
    else
      raise 'Invalid attendee_privacy'
    end
  end

  def attendee_perms_display?(current_user)
    privacy_perms(attendee_privacy, current_user)
  end

  def user_perms_display?(current_user)
    privacy_perms(display_privacy, current_user)
  end

  def user_perms_view?(current_user)
    privacy_perms(event_privacy || 'public', current_user)
  end

  # looks up required permissions to 'action' a permission of specified perm_type
  # returns a proc requiring either all or any of the required perms
  # proc takes a block with held perms
  # returns if held perms fulfil requirements
  def required_perms_for_action(perm_type, action)
    req_perms, method = REQUIRED_PERMISSIONS[action][perm_type]
    case method
    when 'all_required'
      proc { |held_perms| all_required(held_perms, req_perms) }
    when 'one_required'
      proc { |held_perms| one_required(held_perms, req_perms) }
    else
      raise "Invalid method #{method}"
    end
  end

  private

  def all_required(held_perms, required_perms)
    held_perms & required_perms == required_perms
  end

  def one_required(held_perms, required_perms)
    (held_perms & required_perms).any?
  end
end
