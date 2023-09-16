window.init_entry_option = ->
  Tipped.create '[data-action="archive"]', 'Archiving a goal means you will no longer be prompted to complete it.<br>Good for things that are not complete, but are no longer goals.',
    position: 'bottom'
    size: 'x-small'

  Tipped.create '.entry-brief .entry-status .done', 'Completed',
    position: 'bottom'
    size: 'x-small'

  Tipped.create '.entry-brief .entry-status .goal', 'Goal',
    position: 'bottom'
    size: 'x-small'

  Tipped.create '.entry-brief .entry-status .blocked', 'Blocked',
    position: 'bottom'
    size: 'x-small'

  $('.list-entries').on 'click', '.entry-body.editable', (e) ->
    eid = $(e.currentTarget).parents('[data-bind="entry"]:first').data('id')
    li = $(e.currentTarget).parents('.list-entries-item:first')
    e.stopPropagation()
    $.get '/e/' + eid + '/edit', (data) ->
      li.html(data)

  $('.list-entries').on 'click', '[data-action="toggleLike"]', (e) ->
    e.stopPropagation()
    $.post '/e/' + $(e.currentTarget).data('id') + '/toggle_like', (data) ->
      $(e.currentTarget).parents('.list-entries-item:first').html(data)

  $('.list-entries').on 'click', '[data-action="markDone"]', (e) ->
    e.stopPropagation()
    $.post '/e/' + $(e.currentTarget).data('id') + '/mark_done', (data) ->
      $(e.currentTarget).parents('.list-entries-item:first').html(data)

  $('.list-entries').on 'click', '[data-action="archive"]', (e) ->
    e.stopPropagation()
    $.post '/e/' + $(e.currentTarget).data('id') + '/archive', (data) ->
      $(e.currentTarget).parents('.list-entries-item:first').remove()

  $('.list-entries').on 'click', '[data-action="edit"]', (e) ->
    li = $(e.currentTarget).parents('.list-entries-item:first')
    e.stopPropagation()
    $.get '/e/' + $(e.currentTarget).data('id') + '/edit', (data) ->
      li.html(data)

  $('.list-entries').on 'click', '[data-action="comment"]', (e) ->
    li = $(e.currentTarget).parents('.list-entries-item:first')
    e.stopPropagation()
    $('.entry-comments',li).show()
    $('.entry-comments [type="text"]:first',li).focus()

  if $('.sortable').length
    $('.sortable').railsSortable cancel: 'li.ui-sortable-handle.do-not-drag, li.ui-sortable-handle .do-not-drag'

$ ->
  init_entry_option()