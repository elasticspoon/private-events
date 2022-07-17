module GeneralHelper
  def self.array_subsets(array)
    (0..array.length).collect { |i| array.combination(i).to_a }.flatten(1)
  end

  def self.non_empty_array_subsets(array)
    (1..array.length).collect { |i| array.combination(i).to_a }.flatten(1)
  end

  def generate_perms(user_id, event_id, *perms)
    perms.flatten.each do |perm|
      UserEventPermission.create(user_id:, event_id:, permission_type: perm)
    end
  end

  def self.perms(event_privacy)
    attend_perm = event_privacy == 'private' ? ['accept_invite'] : []
    {
      create: {
        'moderate' => [['owner'], 'all_required'],
        'attend' => [attend_perm, 'all_required'],
        'accept_invite' => [%w[moderate owner], 'one_required']
      },
      destroy: {
        'moderate' => [['owner'], 'one_required'],
        'attend' => [%w[current_user moderate owner], 'one_required'],
        'accept_invite' => [%w[moderate owner], 'one_required']
      }
    }.freeze
  end

  def self.perms_copy(event_privacy)
    attend_perm = event_privacy == 'private' ? ['accept_invite'] : []
    {
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
  end
end
