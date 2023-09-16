loadTemplate = (asyncEl) ->
  $.get $(asyncEl).data('template'), (data) ->
    $(asyncEl).html(data)

$(document).ready ->
  $('.application').on 'click', '[data-action="menuSwitcher"]', (e) ->
    $(e.currentTarget).parents('.application').toggleClass('sidebar-open')

  if $('[data-bind="asyncTemplate"]').length
    for asyncEl in $('[data-bind="asyncTemplate"]')
      loadTemplate(asyncEl)
      
  if $('.org-collapse').length
    $('.org-collapse').click (e) ->
      $(this).next().toggle()