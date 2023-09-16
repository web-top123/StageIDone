$ ->
  $(document).on 'click', (e) ->
    switcher = $('[data-bind="teamSwitcher"]:first')
    menu = $('.team-options:first', switcher)
    switcher.removeClass('active')

  $('[data-bind="teamSwitcher"] .team-current').on 'click', (e) ->
    switcher = $(e.currentTarget).parents('[data-bind="teamSwitcher"]:first')
    menu = $('.team-options:first', switcher)

    e.preventDefault()
    e.stopPropagation()
    switcher.toggleClass('active')