isOverflowed = (element) ->
  if element.prop('scrollTop') > 0
    element.addClass('overflowed-top')
  else
    element.removeClass('overflowed-top')
  if element.prop('scrollHeight') > (element.prop('clientHeight') + element.prop('scrollTop'))
    element.addClass('overflowed-bottom')
  else
    element.removeClass('overflowed-bottom')

$ ->
  if $('.scrollable').length
    for scrollable in $('.scrollable')
      isOverflowed $(scrollable)

    $('.scrollable').bind 'scroll', (e) ->
      isOverflowed $(e.currentTarget)