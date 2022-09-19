class Event < ApplicationRecord
  AVAILIABLE_SETTINGS = %w[private protected public].freeze
  # maybe include some sort of proc to indicate wether user needs
  # all or any of the required perms to perform action
  belongs_to :creator, class_name: 'User'

  has_many :user_event_permissions, dependent: :destroy
  has_many :user_relations, through: :user_event_permissions, source: :user

  has_many :accepted_invites, -> { where(permission_type: 'attend') },
           class_name: 'UserEventPermission', inverse_of: :event, dependent: false
  has_many :attending_users, through: :accepted_invites, source: :user

  has_many :pending_invites, -> { where(permission_type: 'accept_invite') },
           class_name: 'UserEventPermission', inverse_of: :event, dependent: false
  has_many :pending_users, through: :pending_invites, source: :user

  validates :date, presence: true
  validates :location, presence: true
  validates :name, presence: true
  validates :desc, presence: true
  validates :event_privacy, inclusion: { in: AVAILIABLE_SETTINGS }
  validates :display_privacy, inclusion: AVAILIABLE_SETTINGS

  scope :past, -> { where('date <= ?', DateTime.now) }
  scope :future, -> { where('date > ?', DateTime.now) }

  after_commit :make_owner_permission, on: :create

  def self.display_public
    where(display_privacy: 'public')
  end

  def future?
    date > DateTime.now
  end

  def past?
    date <= DateTime.now
  end

  # Should be overwitten in the future
  def price
    'Free'
  end

  def image_url
    'https://img.evbuc.com/https%3A%2F%2Fcdn.evbuc.com%2Fimages%2F219765149%2F291099437342%2F1%2Foriginal.20220128-010041?w=512&auto=format%2Ccompress&q=75&sharp=10&rect=0%2C268%2C2048%2C1024&s=6e4df73b75bfc346275a65aaf2835680'
  end

  def accepted_invites
    user_event_permissions.where(permission_type: 'attend').includes(:user)
  end

  def pending_invites
    user_event_permissions.where(permission_type: 'accept_invite').includes(:user)
  end

  def viewable_by?(user)
    return true if display_privacy == 'public'
    return true if user && display_privacy == 'protected'

    holds_permission_currently?(user&.id, 'attend', 'moderate', 'owner', 'accept_invite')
  end

  def editable_by?(user)
    holds_permission_currently?(user&.id, 'owner')
  end

  def required_perms_for_action(perm_type:, action:)
    required_permissions.dig(action,
                             perm_type) || (raise "Invalid perm type: #{perm_type} or action: #{action}")
  end

  private

  def required_permissions
    attend_perm = event_privacy == 'private' ? %w[accept_invite current_user] : ['current_user']
    {
      create: {
        'moderate' => [['owner']],
        'attend' => [attend_perm],
        'accept_invite' => [['moderate'], ['owner']]
      },
      destroy: {
        'moderate' => [['owner']],
        'attend' => [['current_user'], ['moderate'], ['owner']],
        'accept_invite' => [['moderate'], ['owner']]
      }
    }.freeze
  end

  def holds_permission_currently?(user_id, *permission_type)
    user_event_permissions.where(user_id:, permission_type:).any?
  end

  ###################################################################
  ######################### Setup Tasks #############################
  ###################################################################
  def make_owner_permission
    user_event_permissions.create(user_id: creator_id, permission_type: 'owner')
  end
end
