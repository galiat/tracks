class TagCloud

  attr_reader :user,:tags,:min,:divisor, :tags_for_cloud_90days, :min_90days,:cut_off,:divisor_90days

  def compute
    get_stats_tags
  end

  def initialize(user,cut_off)
    @user = user
    @cut_off = cut_off
  end

  # tag cloud code inspired by this article
  # http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
  # TODO: parameterize limit
  def get_stats_tags
    levels=10

    # Get the tag cloud for all tags for actions
    params = [sql, user.id]
    @tags = Tag.find_by_sql(
      params
    ).sort_by { |tag| tag.name.downcase }

    max, @min = 0, 0
    @tags.each { |t|
      max = [t.count.to_i, max].max
      @min = [t.count.to_i, @min].min
    }

    @divisor = ((max - @min) / levels) + 1

    params = [sql(cut_off), user.id, @cut_off, @cut_off]
    @tags_for_cloud_90days = Tag.find_by_sql(
      params
    ).sort_by { |tag| tag.name.downcase }

    max_90days, @min_90days = 0, 0
    @tags_for_cloud_90days.each { |t|
      max_90days = [t.count.to_i, max_90days].max
      @min_90days = [t.count.to_i, @min_90days].min
    }

    @divisor_90days = ((max_90days - @min_90days) / levels) + 1
  end

  private


  def sql(cut_off = nil)
    query = "SELECT tags.id, tags.name AS name, count(*) AS count"
    query << " FROM taggings, tags, todos"
    query << " WHERE tags.id = tag_id"
    query << " AND taggings.taggable_id=todos.id "
    query << " AND todos.user_id=? "
    query << " AND taggings.taggable_type='Todo' "
    if cut_off
      query << " AND (todos.created_at > ? OR "
      query << "      todos.completed_at > ?) "
    end
    query << " GROUP BY tags.id, tags.name"
    query << " ORDER BY count DESC, name"
    query << " LIMIT 100"    
  end  
end