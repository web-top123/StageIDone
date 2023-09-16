updateFieldFromVirtualInput = (virtualInput) ->
  calculatedSeconds = 0
  realInput = $('[name="' + virtualInput.data('bind') + '"]:first')

  hours = parseInt($('[data-bind="hours"]', virtualInput).val())
  minutes = parseInt($('[data-bind="minutes"]', virtualInput).val())
  ampm = $('[data-bind="ampm"]', virtualInput).data('value')
  if ampm == 'pm'
    if hours < 12
      hours = hours + 12
  else # am
    if hours >= 12
      hours = hours - 12

  calculatedSeconds = (hours * 60 * 60) + (minutes * 60)

  realInput.val calculatedSeconds

updateVirtualInputFromField = (realInput) ->
  secsSinceMidnight = parseInt(realInput.val())
  hours = Math.floor(secsSinceMidnight / 3600)
  secsSinceMidnight %= 3600
  minutes = Math.floor(secsSinceMidnight / 60)
  if hours >= 12
    ampm = 'pm'
    if hours > 12
      hours = hours - 12
  else
    ampm = 'am'
    if hours < 1
      hours = hours + 12

  virtualInput = $('[data-bind="' + realInput.attr('name') + '"]:first')
  $('[data-bind="hours"]', virtualInput).val formatHours(hours)
  $('[data-bind="minutes"]', virtualInput).val formatMinutes(minutes)
  $('[data-bind="ampm"]', virtualInput).data 'value', ampm
  $('[data-bind="ampm"]', virtualInput).html ampm

formatHours = (digits) ->
  hoursInt = parseInt(digits)
  if hoursInt > 12
    formatDigits(12)
  else if hoursInt < 1
    formatDigits(1)
  else
    formatDigits(hoursInt)

formatMinutes = (digits) ->
  minutesInt = parseInt(digits)
  minutesInt = 5 * Math.round(minutesInt/5)

  if minutesInt == 60
    formatDigits(55)
  else if minutesInt > 59
    formatDigits(0)
  else
    formatDigits(minutesInt)

formatDigits = (digits) ->
  digitsStr = String(digits)
  if digitsStr.length < 2
    ('0' + digitsStr)
  else
    digitsStr

virtualInputForRealInput = (realInput) ->
  $('[data-bind="' + realInput.attr('name') + '"]:first')

realInputForVirtualInput = (virtualInput) ->
  $('[name="' + virtualInput.data('bind') + '"]:first')

@initializeTimeInput = (virtualInput) ->
  realInput = realInputForVirtualInput(virtualInput)
  updateVirtualInputFromField(realInput)

$ ->
  if $('[role="input"].time').length
    for virtualInput in $('[role="input"].time')
      initializeTimeInput($(virtualInput))

    $('.section-settings').on 'blur', '[role="input"].time [type="tel"]', (e) ->
      telInput = $(e.currentTarget)
      telInput.val telInput.val().replace(/[^0-9]/g, '')
      if !telInput.val().length
        telInput.val 0

      if telInput.val().length > 2
        telInput.val telInput.val().substring(1,3)

      if telInput.data('bind') == 'hours'
        telInput.val formatHours(telInput.val())
      else
        telInput.val formatMinutes(telInput.val())

      virtualInput = telInput.parents('[role="input"].time:first')
      updateFieldFromVirtualInput(virtualInput)

    $('.section-settings').on 'click', '[role="input"].time .ampm', (e) ->
      ampmInput = $(e.currentTarget)

      if ampmInput.data('value') == 'am'
        ampmInput.html 'pm'
        ampmInput.data 'value', 'pm'
      else
        ampmInput.html 'am'
        ampmInput.data 'value', 'am'

      virtualInput = ampmInput.parents('[role="input"].time:first')

      updateFieldFromVirtualInput(virtualInput)
