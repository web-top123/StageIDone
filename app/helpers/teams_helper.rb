module TeamsHelper
  def calendar_indicator_size_for_entries(entries, scale, full, empty)
    (((entries.count / scale.to_f) * (full - empty)) + empty)
  end

  def scale_for_entries(entries)
    max_freq = entries.group_by(&:occurred_on).map { |_k,v| v.size }.max
    return 0 unless max_freq

    scale = "1#{ '0' * max_freq.to_s.size }".to_i

    loop do
      return scale if ((scale * 0.5) <= max_freq)

      scale = scale * 0.5
    end
  end

  def calendar_indicator_colour_for_entries(entries)
    return "#f3f2f1" if entries.nil? or entries.empty?

    done_count = entries.for_status('done').count
    goal_count = entries.for_status('goal').count
    blocked_count = entries.for_status('blocked').count
    saturation_diff = weighted_average_from_hash({d: done_count, g: goal_count, b: blocked_count}, {d: 0, g: 5, b: 25})
    hue_diff = weighted_average_from_hash({d: done_count, g: goal_count, b: blocked_count}, {d: 0, g: 70, b: -140})

    return '#1ecd6e'.paint.spin(hue_diff).saturate(saturation_diff).to_hex
  end

  def weighted_average_from_hash(weights, values)
    weight_sum = weights.inject(0) do |sum, (test, weight)|
      sum += values[test].nil? ? 0 : weight
    end

    # Spread weight equally if no weights provided
    weight_sum = weights.size if weight_sum == 0

    weighted_total = values.inject(0) do |w, (test, score)|
      w += (score.to_f * weights[test])
    end
    weighted_total / weight_sum
  end
end
