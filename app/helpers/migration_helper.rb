module MigrationHelper
  def pretty_name
    if @org
      @org[:name]
    elsif only_personal
      n = "#{@user[:first_name]} #{@user[:last_name]}".strip
      n.blank? ? @username : n
    elsif non_personal_teams && non_personal_teams.length == 1
      non_personal_teams.first[:name]
    else
      "Upgrade"
    end
  end

  # TODO: I (BF) added that check for @source_data's existence to address an exception.
  # Don't really know that that's correct because I don't know where source data
  # comes from. 💃💃💃💃
  def only_personal
    @source_data && (@source_data[:teams].length == 1 && @source_data[:teams].first[:type] == 'PERSONAL')
  end

  def non_personal_teams
    @source_data && @source_data[:teams].select{|t| t[:type] == 'TEAM'}
  end
end
