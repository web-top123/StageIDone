$ ->
  $('.list-invitations').on 'click', '[data-action="resendInvitation"]', (e) ->
    li = $(e.currentTarget).parents('li:first')
    e.stopPropagation()
    $.post '/i/' + $(e.currentTarget).data('id') + '/resend', (data) ->
      li.html(data)

  $('.list-invitations').on 'click', '[data-action="cancelInvitation"]', (e) ->
    li = $(e.currentTarget).parents('li:first')
    e.stopPropagation()
    $.ajax
      url: '/i/' + $(e.currentTarget).data('id')
      data: {}
      type: 'DELETE'
      success: (data) ->
        li.html data