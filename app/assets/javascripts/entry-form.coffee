window.init_entry_form = -> 
  focusOnForm = (form) ->
    blurAllForms()
    form.addClass('focus')
    showHintIfNecessary(form)
    autosize($('textarea:first[data-expandable="true"]',form))
    $('textarea:first',form).focus()

  showHintIfNecessary = (form) ->
    if $('textarea:first',form).val().length > 0
      $('.entry-hint', form).show()
    else
      $('.entry-hint', form).hide()

  resetForm = (form) ->
    for textArea in $('textarea',form)
      $(textArea).val ''
      if $(textArea).data('expandable')
        autosize.update(textArea)

    enableFormEntry(form)
    blurForm(form)
    focusOnForm(form)

  blurForm = (form) ->
    form.removeClass('focus')

  blurAllForms = ->
    for entryForm in $('.entry-form')
      blurForm $(entryForm)

  disableFormEntry = (form) ->
    $('textarea:first',form).attr("disabled", "disabled")

  enableFormEntry = (form) ->
    $('textarea:first',form).removeAttr("disabled")

  submitUpdate = (form, entryData) ->
    li = form.parents('.list-entries-item:first')
    $.ajax
      url: form.attr('action')
      data: entryData
      type: 'PATCH'
      success: (data) ->
        li.html data

  submitNew = (form, entryData) ->
    li = form.parents('.list-entries-item:first')
    $.post(form.attr('action'), entryData).done((data) ->
      li.before($("<li class='list-entries-item ui-sortable-handle' id='"+data.sortable_id+"'><span class='handle'></span>" + data.entry_brief + "</li>"))
      updatePlaceholders(li.parents('.list-entries:first'))
      resetForm(form)
    ).fail (xhr, textStatus, errorThrown) ->
      li.html xhr['responseText']

  submitForm = (form) ->
    entryData =
      'entry_occurred_on': $('[name="entry[occurred_on]"]',form).val(),
      'entry_status': $('[name="entry[status]"]',form).val(),
      'entry_body': $('[name="entry[body]"]',form).val()

    return cancelForm(form) if entryData.entry_body.length == 0

    disableFormEntry(form)

    if form.hasClass 'persisted'
      submitUpdate(form, entryData)
    else
      submitNew(form, entryData)

  updatePlaceholders = (list) ->
    limit = 5
    while ($('.list-entries-item', list).length > limit) and $('.entry-brief-placeholder', list).length
      placeholder = $('.entry-brief-placeholder:first',list)
      placeholder.parents('.list-entries-item:first').remove()

  cancelForm = (form) ->
    if form.data('id')
      # set the data to existing entry
      li = form.parents('.list-entries-item:first')
      $.get '/e/' + form.data('id') + '/brief', (data) ->
        li.html(data)
    else
      document.forms[form.attr('id')].reset()

  bindAutocompletionToTextarea = (textarea) ->
    users = textarea.data('users')
    tags = textarea.data('tags')
    textarea.atwho(
      at: '@'
      data: users).atwho(
      at: '#'
      data: tags)

  if $('.entry-form').length
    $('.list-users-portraits-item.heard').children().first().addClass('active-user')
  if $('.entry-form').length
    
    bindAutocompletionToTextarea $('textarea',$('.entry-form:first'))

    $(document).on 'click', 'body', (e) ->
      blurAllForms()

    $('.list-entries').on 'click', '.entry-form', (e) ->
      e.stopPropagation()
      focusOnForm $(e.currentTarget)

    $('.list-entries').on 'DOMNodeInserted', (e) ->
      if $(e.target).is('.entry-form')
        focusOnForm $(e.target)
        bindAutocompletionToTextarea $('textarea', $(e.target))

    $('.list-entries').on 'submit', '.entry-form', (e) ->
      e.stopPropagation()
      e.preventDefault()
      submitForm($(e.currentTarget))

    $('.list-entries').on 'click', '[data-action="save"]', (e) ->
      e.stopPropagation()
      form = $(e.currentTarget).parents('[data-bind="entry"]')
      submitForm(form)

    $('.list-entries').on 'click', '[data-action="cancel"]', (e) ->
      e.stopPropagation()
      form = $(e.currentTarget).parents('[data-bind="entry"]')
      cancelForm(form)

    $('.list-entries').on 'click', '.entry-brief-placeholder', (e) ->
      focusOnForm($('.entry-form:first'))

    viewJustHid = false
    $('.entry-form textarea').on 'hidden.atwho', ->
      viewJustHid = true
      setTimeout (->
        viewJustHid = false
        return
      ), 75
      return

    $('.list-entries').on 'keydown', '.entry-form textarea', (e) ->
      if e.keyCode == 13 && !e.shiftKey
        e.preventDefault()
        if !viewJustHid
          e.stopPropagation()
          form = $(e.currentTarget).parents('[data-bind="entry"]')
          submitForm(form)
          return false

    $('.list-entries').on 'keyup', '.entry-form textarea', (e) ->
      entryInput    = $(e.currentTarget)
      entryForm     = entryInput.parents('.entry-form:first')
      body          = entryInput.val()

      if e.which == 27 and body.length
        cancelForm(entryForm)

      showHintIfNecessary(entryForm)

      if body.substring(0,2) == '[]'
        $('[name="entry[status]"]', entryForm).val('goal')
        $('[name="entry[status]"]', entryForm).change()
        entryInput.val body.substring(2)
      else if body.substring(0,3) == '[ ]'
        $('[name="entry[status]"]', entryForm).val('goal')
        $('[name="entry[status]"]', entryForm).change()
        entryInput.val body.substring(3)
      else if body.substring(0,3) == '[x]' || body.substring(0,3) == '[X]' || body.substring(0,3) == '[√]'
        $('[name="entry[status]"]', entryForm).val('done')
        $('[name="entry[status]"]', entryForm).change()
        entryInput.val body.substring(3)
      else if body.substring(0,1) == '!'
        $('[name="entry[status]"]', entryForm).val('blocked')
        $('[name="entry[status]"]', entryForm).change()
        entryInput.val body.substring(1)

$ ->
    init_entry_form()

    $('.list-users-portraits-item.heard').on 'click', '[data-action="listUserEntries"]', (e) ->
      e.stopPropagation()
      team_id = $(e.currentTarget).data('team_id')
      user_id = $(e.currentTarget).data('user_id')
      date = $(e.currentTarget).data('date')
      loader_show()
      $.ajax
        url: '/entry_listing'
        data: {user_id: user_id, id: team_id, date: date}
        type: 'PATCH'
        success: (data) ->
          e.stopPropagation()
          $('.user-day').parent()                    
          main_section = $('.user-day').parent()
          main_section.find('.user-day').remove()
          main_section.append(data)
          $('.list-users-portraits-item.heard').children().removeClass('active-user');
          $(e.currentTarget).addClass('active-user');
          window.init_entry_form()
          window.init_entry_option()
          window.init_comment_form()
          window.delete_comment()
          window.init_comment_options()
          window.init_input_status()
          loader_hide()

loader_show = (argument) ->
  $('#loader').show()
  return

loader_hide = (argument) ->
  $('#loader').hide()
  return