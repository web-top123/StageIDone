updateLinkForExportForm = (form) ->
  startDateDay = $('[name="start_date[day]"]', form).val()
  startDateMonth = $('[name="start_date[month]"]', form).val()
  startDateYear = $('[name="start_date[year]"]', form).val()
  startDateStr = startDateYear + '-' + startDateMonth + '-' + startDateDay
  endDateDay = $('[name="end_date[day]"]', form).val()
  endDateMonth = $('[name="end_date[month]"]', form).val()
  endDateYear = $('[name="end_date[year]"]', form).val()
  endDateStr = endDateYear + '-' + endDateMonth + '-' + endDateDay

  newLinkUrl = $('.actions a:last', form).data('base_path') + ".csv?start_date=" + startDateStr + "&end_date=" + endDateStr

  $('.actions a:last', form).attr 'href', newLinkUrl

$ ->
  if $('[data-bind="exportToggle"]').length
    Tipped.create('[data-bind="exportToggle"]', {
      position: 'bottom',
      showOn: 'click',
      hideOn: 'click',
      hideOnClickOutside: true
    })

  if $('.form-export').length
    $('.actions a:last', '.form-export').on 'click', (e) ->
      updateLinkForExportForm($(e.currentTarget).parents('form:first'))
