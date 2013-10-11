class TagCloud
  attr_reader :user,:divisor,:cut_off

  def initialize(user,cut_off=nil)
    @user = user
    @cut_off = cut_off
  end

  def tags
    unless @tags
      params = [sql(@cut_off), user.id]
      if @cut_off
        params += [@cut_off, @cut_off]
      end
      @tags = Tag.find_by_sql(params).sort_by { |tag| tag.name.downcase }
    end
    @tags
  end

  def divisor
    @divisor ||= ((max - min) / levels) + 1
  end

  def min
    0
  end

  private

  def tag_counts
   @tag_counts ||= tags.map {|t| t.count.to_i}
  end

  def levels
    10
  end

  def max
    tag_counts.max
  end

  # TODO: parameterize limit
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