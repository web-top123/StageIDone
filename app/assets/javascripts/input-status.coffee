window.init_input_status = ->

  resetPromptForForm = (form) ->
    statusVal = $('[name="entry[status]"]:first', form).val()
    newPrompt = $('.entry-content:first', form).data('prompt-' + statusVal)
    $('[name="entry[body]"]:first', form).attr 'placeholder', newPrompt

  $(document).on 'click', (e) ->
    if $('[role="input"].status').length
      for switcher in $('[role="input"].status')
        $(switcher).removeClass('active')

  $('.list-entries').on 'mouseover', '[role="input"].status', (e) ->
    switcher = $(e.currentTarget)
    switcher.addClass('active')
    e.preventDefault()
    e.stopPropagation()

  $('.list-entries').on 'mouseleave', '[role="input"].status', (e) ->
    switcher = $(e.currentTarget)
    switcher.removeClass('active')
    e.preventDefault()
    e.stopPropagation()

  $('.list-entries').on 'change', '[name="entry[status]"]', (e) ->
    val = $(e.currentTarget).val()
    icon_div = $(e.currentTarget).parent().find('.status-current')
    $(icon_div).data('value',val)
    icon = $(icon_div).children()
    icon.removeClass('done')
    icon.removeClass('goal')
    icon.removeClass('blocked')
    icon.addClass(val)

    resetPromptForForm($(e.currentTarget).parents('form:first'))

  $('.list-entries').on 'click', '[role="input"].status .status-options li', (e) ->
    option = $(e.currentTarget)
    switcher = option.parents('[role="input"].status:first')
    switcher.toggleClass('active')
    form = option.parents('form:first')

    $('[name="entry[status]"]', form).val(option.data('value'))
    $('[name="entry[status]"]', form).change()

    e.preventDefault()
    e.stopPropagation()

$ ->
  init_input_status()