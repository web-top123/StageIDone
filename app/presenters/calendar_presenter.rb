class CalendarPresenter
  def initialize(date_str, team)
    @date_str = date_str
    @team = team
  end

  def month
    @date_str ?  Date.parse(@date_str).beginning_of_month : Date.current.beginning_of_month
  end

  def previous_month
     (month - 1.month).beginning_of_month
  end

  def next_month
    (month + 1.month).beginning_of_month
  end

  def month_beginning
    month.beginning_of_month
  end

  def month_ending
    month.end_of_month
  end

  def entries
    @team.entries.for_month(month)
  end
end
