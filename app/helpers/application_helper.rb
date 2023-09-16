module ApplicationHelper
  def dashboard_date(date)
    case date
    when Date.today
      'Today'
    when Date.today - 1.day
      'Yesterday'
    when Date.today + 1.day
      'Tomorrow'
    else
      date.strftime '%b %d'
    end
  end

  def wday_to_str(wday)
    case wday
    when 0 then 'sunday'
    when 1 then 'monday'
    when 2 then 'tuesday'
    when 3 then 'wednesday'
    when 4 then 'thursday'
    when 5 then 'friday'
    when 6 then 'saturday'
    end
  end

  def month_to_str(month)
    case month
    when 1 then 'january'
    when 2 then 'february'
    when 3 then 'march'
    when 4 then 'april'
    when 5 then 'may'
    when 6 then 'june'
    when 7 then 'july'
    when 8 then 'august'
    when 9 then 'september'
    when 10 then 'october'
    when 11 then 'november'
    when 12 then 'december'
    end
  end

  def format_cents(cents)
    number_to_currency(cents / 100.0).gsub(/\.00$/, "")
  end

  def domain_from_email(email)
    email.split('@',2).last
  end

  # TODO: Fredrik, this is the y-axis height for the frequency chart
  # it needs to be a roundish number that's greater than the max number of dones
  # completed in a single day in the range (cday minus tdays)
  # i can imagine you love my code:
  def scale_for_frequency(entries, start_date, end_date)
    max_freq = entries.for_period(start_date, end_date).group_by(&:occurred_on).map { |d,e| e.size }.max
    return 10 unless max_freq
    scale = "1#{ '0' * max_freq.to_s.size }".to_i

    # TODO fredrik, forgive me

    loop do
      return scale if ((scale * 0.5) <= max_freq)

      scale = scale * 0.5
    end
  end
end
