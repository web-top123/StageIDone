window.init_comment_options = ->
  $('.list-entries').on 'dblclick', '.comment .content.editable', (e) ->
    rid = $(e.currentTarget).parents('[data-bind="reaction"]:first').data('id')
    li = $(e.currentTarget).parents('.list-comments-item:first')
    e.stopPropagation()
    $.get '/r/' + rid + '/edit', (data) ->
      li.html(data)
    autosize($('textarea[data-expandable="true"]','.comment-form'))

$ ->
  init_comment_options()

