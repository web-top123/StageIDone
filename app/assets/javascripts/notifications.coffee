window.all_archived_notifications = false
$ ->
  $('.notifications-section input').on 'click', ->
    href = undefined
    table = undefined
    tr = undefined
    tr = $(this).parent().parent()
    table = tr.parent()
    tr.hide 300
    href = tr.find('a').attr('href')
    $.ajax
      type: 'DELETE'
      url: '/notifications/' + $(this).val()
      contentType: 'application/json;charset=utf-8'
    setTimeout (->
      notifications = $($('table')[0]).find('tr:visible').length
      if !notifications
        $($('table')[0]).hide()
        $('.no-notifications').show 300
      return
    ), 500
    reload_archived_notifications()
  
  $('#show_all_notifications').click (e)->
    window.all_archived_notifications = true
    reload_archived_notifications()
    e.target.setAttribute('onclick',null)

@reload_archived_notifications = ->
  url = '/notifications/reload_archived'
  if !$('#show_all_notifications').length || window.all_archived_notifications
    url += '?all=true'
  setTimeout ( ->
    $.ajax
      type: 'GET'
      url:  url
      contentType: 'application/json;charset=utf-8'
      complete: (response, status)->
        $('#archived-notifications-section').html(response.responseText)
  ), 500
