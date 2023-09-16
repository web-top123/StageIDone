resizeToolTip = ->
  $(window).resize()

$ ->
  # State variables of user visiting this page
  _state = {
    selectedDates: [],
    # Variables for implementating user click/drag to toggle selection
    isMouseDown: false,
    isHighlighted: false,
  }

  # Properies which data that doesn't change
  _props = {
    entries: $('#calendar-entries').data('content'),
    users: $('#users-info').data('content'),
  }

  # Create HTML fragment for showing user info
  userInfoHtml = (userId) ->
    _userInfo = _props.users[userId]
    _userPortraitClass = if _userInfo.portrait_thumbnail_url
                           ''
                         else
                           'blank'
    _userPortraitUrl = if _userInfo.portrait_thumbnail_url
                         _userInfo.portrait_thumbnail_url
                       else
                         ''
    return "<header class='user-day_header'>
              <div class='large portrait square #{_userPortraitClass}'
                  style='background-color:#{_userInfo.profile_color};
                         background-image:url(#{_userPortraitUrl})'>
                  #{_userInfo.full_name_or_something_else_identifying[0]}
              </div>
            </header>"

  # Create HTML fragment for a single entry
  entryHtml = (entryElem) ->
    return "<li class='list-entries-item'>
              <div class='entry-brief'>
                <div class='entry-status'>
                  <div class='disc #{entryElem.status.toLowerCase()}
                    icon small status'></div>
                </div>
                <div class='entry-content'>
                  <div class='entry-body'>
                    #{entryElem.body_formatted}
                  </div>
                </div>
              </div>
            </li>"

  # Create HTML fragment for entries for each user
  entriesHtml = (entries) ->
    # Currently we sort by reverse creation order but in future we
    # can define the sort function
    _sortedEntries =  entries.sort(
      (a, b) -> return new Date(a.created_at) - new Date(b.created_at)
    )
    _entriesHtmls = $.map _sortedEntries, (entry) -> return entryHtml(entry)

    return "<main class='user-day_main'>
              <ol class='list-entries'>
                #{_entriesHtmls.join('')}
              </ol>
            </main>"

  # Create HTML fragment for all entries of users by their statuses
  entriesByUserHtml = (entriesByUser) ->
    _htmlFragments = $.map entriesByUser, (entries, userId) ->
      return "<section class='section-standard section-entries'>
                <div class='user-day'>
                  #{userInfoHtml(userId)}
                  #{entriesHtml(entries)}
                </div>
              </section>"
    _return = if (_htmlFragments && _htmlFragments.length > 0)
                _htmlFragments.join('')
              else
                '<div>None</div>'
    return _return

  displayEntries = (elemId) -> 
    # Clear all entries since we are redrawing the element each time
    $(elemId).text('')

    _sortedDates = _state.selectedDates.sort().reverse()

    _htmlStrs = $.map _sortedDates, (dateElem) ->
      _entriesByUser = _props.entries[dateElem]

      _dateObj = moment(dateElem)
      return "<h2 class='left'>#{_dateObj.format("dddd, MMMM D")}</h2>
              #{entriesByUserHtml(_entriesByUser)}"

    $(elemId).html(_htmlStrs.join(''))

  getDateValue = (e) ->
    _value = $(e.currentTarget).data('value')
    return _value

  addDateData = (e) ->
    _dateValue = getDateValue(e)
    _index = _state.selectedDates.indexOf(_dateValue)
    if _index < 0
      _state.selectedDates.push(_dateValue)
    displayEntries('#entries')

  removeDateData = (e) ->
    _dateValue = getDateValue(e)
    _index = _state.selectedDates.indexOf(_dateValue)
    if _index >= 0
      _state.selectedDates.splice(_index, 1)
    displayEntries('#entries')

  if $('[data-bind="datePicker"]').length
    Tipped.create('[data-bind="datePicker"]', {
      position: 'bottom',
      showOn: 'click',
      hideOn: 'click',
      hideOnClickOutside: true
    })

  if $('.calendar[role="input"]').length
    $('[data-bind="datePicker"]').on 'click', (e) ->
      cal = $('.calendar[role="input"]:first')
      $.get $(e.currentTarget).data('current_date'), (data) ->
        cal.html(data)
        resizeToolTip()

    $('.calendar[role="input"]').on 'click', '[data-action="pickDate"]', (e) ->
      e.preventDefault()
      window.location.href = window.location.pathname + '?date=' + $(e.currentTarget).data('value')

    $('.calendar[role="input"]').on 'click', '[data-action="goToPreviousMonth"]', (e) ->
      e.preventDefault()
      cal = $(e.currentTarget).parents('.calendar[role="input"]:first')
      $.get $('.calendar_body', cal).data('previous_month'), (data) ->
        cal.html(data)
        resizeToolTip()

    $('.calendar[role="input"]').on 'click', '[data-action="goToNextMonth"]', (e) ->
      e.preventDefault()
      cal = $(e.currentTarget).parents('.calendar[role="input"]:first')
      $.get $('.calendar_body', cal).data('next_month'), (data) ->
        cal.html(data)
        resizeToolTip()

  $('div[data-action="toggleDate"]').on(
    'mousedown', (e) ->
      _state.isMouseDown = true
      $(this).toggleClass("highlight")
      _state.isHighlighted = $(this).hasClass("highlight")
      if _state.isHighlighted then addDateData(e) else removeDateData(e)
      return false # prevent text selection
  ).bind 'selectstart', () ->
    return false

  $('div[data-action="toggleDate"]').on(
    'mouseover', (e) ->
      if (_state.isMouseDown)
        $(this).toggleClass("highlight", _state.isHighlighted)
        if _state.isHighlighted then addDateData(e) else removeDateData(e)
  ).bind 'selectstart', () ->
    return false

  $(document).on 'mouseup', (e) ->
    _state.isMouseDown = false
