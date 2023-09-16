updateFieldFromVirtualInput = (virtualInput) ->
  bind = virtualInput.data('bind')
  mailer = virtualInput.data('mailer')
  options = $("[data-bind='#{bind}'] [role='inputOption']")
  for option in options
    $(option).parent().find("input").val $(option).hasClass('active')


updateVirtualInputFromField = (field) ->
  $(".day div[role='inputOption']").removeClass('active')
  inputs = $(".day input")
  for input in inputs
    if $(input).val() == "true"
      $(input).parent().find("div").addClass('active')



virtualInputForRealInput = (realInput) ->
  $('[data-bind="' + realInput.attr('name') + '"]:first')

realInputForVirtualInput = (virtualInput) ->
  $('[name="' + virtualInput.data('bind') + '"]:first')

initializeWeekInput = (virtualInput) ->
  realInput = realInputForVirtualInput(virtualInput)
  updateVirtualInputFromField(realInput)

$ ->
  if $('[role="input"].week').length
    for virtualInput in $('[role="input"].week')
      initializeWeekInput($(virtualInput))

    $('.section-settings').on 'DOMNodeInserted', (e) ->
      for virtualInput in $('[role="input"].week')
        initializeWeekInput($(virtualInput))

    $('.section-settings').on 'click', '[role="input"].week [role="inputOption"]', (e) ->
      inputOption = $(e.currentTarget)
      virtualInput = inputOption.parents('[role="input"].week:first')

      e.stopPropagation()
      e.preventDefault()

      $(e.currentTarget).toggleClass('active')
      updateFieldFromVirtualInput(virtualInput)
