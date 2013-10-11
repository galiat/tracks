class TagCloud

  attr_reader :user,:tags,:min,:tags_divisor, :tags_for_cloud_90days, :min_90days,:cut_off_3months,:tags_divisor_90days

  def compute
    get_stats_tags
  end

  def initialize(user,cut_off_3months)
    @user = user
    @cut_off_3months = cut_off_3months
  end

  # tag cloud code inspired by this article
  # http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
  # TODO: parameterize limit
  def get_stats_tags
    levels=10

    # Get the tag cloud for all tags for actions
    query = "SELECT tags.id, name, count(*) AS count"
    query << " FROM taggings, tags, todos"
    query << " WHERE tags.id = tag_id"
    query << " AND taggings.taggable_id = todos.id"
    query << " AND todos.user_id="+user.id.to_s+" "
    query << " AND taggings.taggable_type='Todo' "
    query << " GROUP BY tags.id, tags.name"
    query << " ORDER BY count DESC, name"
    query << " LIMIT 100"
    @tags = Tag.find_by_sql(query).sort_by { |tag| tag.name.downcase }

    max, @min = 0, 0
    @tags.each { |t|
      max = [t.count.to_i, max].max
      @min = [t.count.to_i, @min].min
    }

    @tags_divisor = ((max - @min) / levels) + 1

    # Get the tag cloud for all tags for actions
    query = "SELECT tags.id, tags.name AS name, count(*) AS count"
    query << " FROM taggings, tags, todos"
    query << " WHERE tags.id = tag_id"
    query << " AND todos.user_id=? "
    query << " AND taggings.taggable_type='Todo' "
    query << " AND taggings.taggable_id=todos.id "
    query << " AND (todos.created_at > ? OR "
    query << "      todos.completed_at > ?) "
    query << " GROUP BY tags.id, tags.name"
    query << " ORDER BY count DESC, name"
    query << " LIMIT 100"
    @tags_for_cloud_90days = Tag.find_by_sql(
      [query, user.id, @cut_off_3months, @cut_off_3months]
    ).sort_by { |tag| tag.name.downcase }

    max_90days, @min_90days = 0, 0
    @tags_for_cloud_90days.each { |t|
      max_90days = [t.count.to_i, max_90days].max
      @min_90days = [t.count.to_i, @min_90days].min
    }

    @tags_divisor_90days = ((max_90days - @min_90days) / levels) + 1
  end
end