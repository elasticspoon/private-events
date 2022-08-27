module GeneralHelper
  def self.array_subsets(array)
    (0..array.length).collect { |i| array.combination(i).to_a }.flatten(1)
  end

  def self.non_empty_array_subsets(array)
    (1..array.length).collect { |i| array.combination(i).to_a }.flatten(1)
  end

  def generate_perms(user_id, event_id, *perms)
    perms.flatten.each do |perm|
      UserEventPermission.create(user_id: user_id, event_id: event_id, permission_type: perm)
    end
  end
end
