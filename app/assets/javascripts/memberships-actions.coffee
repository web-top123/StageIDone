$ ->
  $('.membership-summary').on 'change', 'select', (e) ->
    form = $(e.currentTarget).parents('form:first')
    form.submit()
