addEmail = (form) ->
  div = form.parents('div:first')

  $('[type="submit"]:first', div).val('...')
  $('[type="submit"]:first', div).attr('disabled', true)
  $.ajax
    url: form.attr('action')
    data: form.serialize()
    type: 'POST'
    success: (data) ->
      div.html data
      $('[type="submit"]:first', div).val('Add')
      $('[type="submit"]:first', div).attr('disabled', false)
    error: (data) ->
      form.html data.responseText
      $('[type="submit"]:first', div).val('Add')
      $('[type="submit"]:first', div).attr('disabled', false)

removeEmail = (target) ->
  div = target.parents('div:first')

  $.ajax
    url: '/alternate_emails/' + target.data('id')
    data: {}
    type: 'DELETE'
    success: (data) ->
      div.html data

$ ->
  $('.section-settings').on 'submit', '.alternate-email-form', (e) ->
    e.stopPropagation()
    e.preventDefault()
    addEmail($(e.currentTarget))

  $('.section-settings').on 'click', '[data-action="removeAlternateEmail"]', (e) ->
    e.preventDefault()
    removeEmail($(e.currentTarget))

