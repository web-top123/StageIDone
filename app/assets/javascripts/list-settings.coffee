$ ->
  $('.list-settings-items').on 'click', '[data-action="removeFromTeam"]', (e) ->
    li = $(e.currentTarget).parents('li:first')
    team_id = $(e.currentTarget).data('team')
    e.stopPropagation()
    $.ajax
      url: '/t/' + team_id + '/memberships/' + $(e.currentTarget).data('id')
      data: {}
      type: 'DELETE'
      success: (data) ->
        li.html data

  $('.list-settings-items').on 'click', '[data-action="addToTeam"]', (e) ->
    li = $(e.currentTarget).parents('li:first')
    team_id = $(e.currentTarget).data('team')
    user_id = $(e.currentTarget).data('id')
    e.stopPropagation()
    $.ajax
      url: '/t/' + team_id + '/memberships'
      data: { user_id: user_id }
      type: 'POST'
      success: (data) ->
        li.html data

  $('.list-settings-items').on 'change', '.inline-form select', (e) ->
    form = $(e.currentTarget).parents('form:first')
    $.ajax
      url: form.attr('action')
      data: form.serialize()
      type: 'PATCH'
      success: (data) ->
        true