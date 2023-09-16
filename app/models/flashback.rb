class Flashback
  attr_reader :date, :entries

  def self.date_map
    {
      1.week.ago.to_date   => "one week",
      1.month.ago.to_date  => "one month",
      3.months.ago.to_date => "three months",
      6.months.ago.to_date => "six months",
      1.year.ago.to_date   => "one year"

    }
  end

  def self.get(user, team)
    generate_flashbacks(user, team).sample
  end

  def self.generate_flashbacks(user, team)
    get_dones_grouped_by_occurred_on(user, team).collect do |date, entries|
      Flashback.new(date, entries)
    end
  end

  def self.get_dones_grouped_by_occurred_on(user, team)
    user.entries.where(team_id: team.id, occurred_on: date_map.keys, status: 'done').group_by(&:occurred_on)
  end

  def initialize(date, entries)
    @date    = date
    @entries = entries
  end

  def distance_as_words
    "#{Flashback.date_map[date]} ago"
  end

  def date_str
    date.strftime("%A, %B %d, %Y")
  end

  def title
    distance_as_words.capitalize
  end

  def description
    "This is what you got done on this day #{distance_as_words}, #{date_str}"
  end
end

