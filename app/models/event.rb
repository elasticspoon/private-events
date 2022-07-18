class Event < ApplicationRecord
  AVAILIABLE_SETTINGS = %w[private protected public].freeze
  # maybe include some sort of proc to indicate wether user needs
  # all or any of the required perms to perform action
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

  after_commit :do_creation_tasks, on: :create

  attr_reader :required_permissions

  def self.past
    where('date <= ?', DateTime.now)
  end

  def self.future
    where('date > ?', DateTime.now)
  end

  def self.display_public
    where(display_privacy: 'public')
  end

  def future?
    date > DateTime.now
  end

  def past?
    date < DateTime.now
  end

  def accepted_invites
    user_event_permissions.where(permission_type: 'attend').includes(:user)
  end

  def pending_invites
    user_event_permissions.where(permission_type: 'accept_invite').includes(:user)
  end

  def attending_viewable_by?(user)
    perms_for_event_setting?(user, attendee_privacy)
  end

  def viewable_by?(user)
    perms_for_event_setting?(user, display_privacy)
  end

  def joinable_by?(user)
    return false if user.nil?

    user.can_join?(self)
  end

  def required_perms_for_action(perm_type, action)
    required_permissions.dig(action, perm_type) || (raise "Invalid perm type: #{perm_type} or action: #{action}")
  end

  private

  def private_allowed?(held_perms)
    (held_perms & %w[attend accept_invite moderate owner]).any?
  end

  # needs fixing some day
  # generic function to check a user's permissions for an event
  def perms_for_event_setting?(current_user, event_setting)
    held_perms = User.held_event_perms(current_user, id)
    perms_allow_setting?(event_setting, held_perms)
  end

  def perms_allow_setting?(event_setting, held_perms)
    case event_setting
    when 'public'
      true
    when 'protected'
      !held_perms.nil?
    when 'private'
      !held_perms.nil? && private_allowed?(held_perms)
    else
      raise 'Invalid attendee_privacy'
    end
  end

  ###################################################################
  ######################### Setup Tasks #############################
  ###################################################################
  def do_creation_tasks
    make_owner_permission
    set_required_perms
  end

  def make_owner_permission
    user_event_permissions.create(user_id: creator_id, permission_type: 'owner')
  end

  def set_required_perms
    attend_perm = event_privacy == 'private' ? %w[accept_invite current_user] : ['current_user']
    default_perms = {
      create: {
        'moderate' => [['owner']],
        'attend' => [attend_perm],
        'accept_invite' => [['moderate'], ['owner']]
      },
      destroy: {
        'moderate' => ['owner'],
        'attend' => [['current_user'], ['moderate'], ['owner']],
        'accept_invite' => [['moderate'], ['owner']]
      }
    }.freeze
    @required_permissions = default_perms
  end
end
