submitForm = (form) ->
  div = form.parents('div:first')
  btn = $('[type="submit"]:first', div)
  btn.val('···')
  btn.attr('disabled', true)
  $.ajax
    url: form.attr('action')
    data: form.serialize()
    type: 'PATCH'
    success: (data) ->
      div.html data
      btn = $('[type="submit"]:first', div)
      for virtualInput in $('[role="input"].time', div)
        initializeTimeInput($(virtualInput))
      for telInput in $(".tel_input[type=tel]")
        $("input[type=tel]").intlTelInput(
          nationalMode:false, 
          formatOnInit: true,
          initialCountry: "us")
      btn.val('Saved')
      btn.attr('disabled', true)
      setTimeout(->
        $('[type="submit"]:first', div).val(btn.data('text') || 'Save Changes')
        $('[type="submit"]:first', div).attr('disabled', false)
      , 5000)
$ ->
  $('.section-settings').on 'submit', '.settings-form', (e) ->
    if !$(e.currentTarget).hasClass('static')
      e.stopPropagation()
      e.preventDefault()
      submitForm($(e.currentTarget))

  $('.section-settings').on 'click', '[data-action="copier"]', (e) ->
    $(e.currentTarget).select()

  $('.section-settings').on 'click', '[data-action="showTemplate"]', (e) ->
    button = $(e.currentTarget)
    div = button.parents('[data-bind="asyncTemplate"]')
    e.stopPropagation()
    e.preventDefault()
    $.get button.data('template'), (data) ->
      div.html(data)
