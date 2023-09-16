resetForm = (form) ->
  for formInput in $('input', form)
    $(formInput).val ''

submitForm = (form) ->
  li = form.parents('li:first')
  $('[type="submit"]:first', li).val('···')
  $('[type="submit"]:first', li).attr('disabled', true)
  $.ajax
    url: form.attr('action')
    data: form.serialize()
    type: 'POST'
    success: (data) ->
      li.before($("<li class='list-settings-item'>" + data + "</li>"))
      $('[type="submit"]:first', li).val('Sent')
      $('[type="submit"]:first', li).attr('disabled', true)
      setTimeout(->
        $('[type="submit"]:first', li).val('Invite')
        $('[type="submit"]:first', li).attr('disabled', false)
      , 5000)
    failed: (data) ->

$ ->
  if $('.list-item-form').length
    $('.section-settings').on 'submit', '.list-item-form', (e) ->
      e.stopPropagation()
      e.preventDefault()
      submitForm($(e.currentTarget))
      resetForm($(e.currentTarget))