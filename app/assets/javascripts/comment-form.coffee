window.init_comment_form = -> 
  focusOnForm = (form) ->
    form.addClass('focus')
    showHintIfNecessary(form)
    autosize($('.emoji-wysiwyg-editor:first[data-expandable="true"]',form))
    $('.emoji-wysiwyg-editor:first',form).focus()

  showHintIfNecessary = (form) ->
    li = $('.emoji-wysiwyg-editor',form).text()
    if li and li.length > 0
      $('.comment-hint', form).show()
    else
      $('.comment-hint', form).hide()

  resetForm = (form) ->
    li = form.parents('.list-comments-item:first')
    for div in $('div',form)
      $('.emoji-wysiwyg-editor').text ''
      $('.emoji-wysiwyg-editor[name="reaction[body]"]').val ''
      autosize.update(div)

    focusOnForm(form)

  submitUpdate = (form) ->
    li = form.parents('.list-comments-item:first')
    commentValue = $('[name="reaction[body]"]',form).val()

    commentData =
      'comment_body': commentValue

    $.ajax
      url: form.attr('action')
      data: commentData
      type: 'PATCH'
      success: (data) ->
        li.html data

  submitNew = (form) ->
    li = form.parents('.list-comments-item:first')
    commentValue = $('[name="reaction[body]"]',form).val()

    commentData =
      'comment_body': commentValue

    return cancelForm(form) if commentData.comment_body.length == 0

    $.post form.attr('action'), commentData, (data) ->
      li.before($("<li class='list-comments-item'>" + data + "</li>"))
      resetForm(form)
      comment_str = li.closest('.list-entries-item').find('.entry-content .entry-options .comment_count').text()
      comment_str = comment_str.replace(/\s+/g, " ")
      comment_count_val = comment_str.replace('Comments (','').replace(')', '')
      comment_count = parseInt(comment_count_val)
      if (isNaN(comment_count))
        comment_count = 0
      comment_count = comment_count + 1
      comment_count_set = 'Comments (' + comment_count + ')'
      li.closest('.list-entries-item').find('.entry-content .entry-options .comment_count').text(comment_count_set)

  cancelForm = (form) ->
    if form.data('id')
      li = form.parents('.list-comments-item:first')
      $.get '/r/' + form.data('id'), (data) ->
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

  bindHiddenAtWho = (textarea) ->
    $(textarea).on 'hidden.atwho', ->
      $(textarea).data('hiddenatwho', true)
      setTimeout (->
        $(textarea).data('hiddenatwho', false)
        return
      ), 75
      return 
      
  if $('.list-entries').length

    $('.list-entries').on 'keydown', '.comment-form', (e) ->
      bindAutocompletionToTextarea $('.emoji-wysiwyg-editor',$('.comment-form'))
      autosize($('.emoji-wysiwyg-editor[data-expandable="true"]','.comment-form'))
      bindHiddenAtWho $('.emoji-wysiwyg-editor',$('.comment-form'))
      if e.keyCode == 13 && !e.shiftKey

        $('.emoji-wysiwyg-editor[name="reaction[body]"]').blur()
        e.preventDefault()
        form = $(e.currentTarget)
        textArea = $('.emoji-wysiwyg-editor',form)
        focusOnForm(form)
        
        if !textArea.data('hiddenatwho')
          e.stopPropagation()
          $('.emoji-wysiwyg-editor').blur()
          if form.hasClass 'persisted'
            submitUpdate(form)
          else
            submitNew(form)

    $('.list-entries').on 'DOMNodeInserted', (e) ->
      # if a new Entry is added or a current Comment is edited
      if $(e.target).is('.list-entries-item') or $(e.target).is('.comment-form')
        focusOnForm $(e.target)
        bindAutocompletionToTextarea $('.emoji-wysiwyg-editor', $(e.target))
        autosize($('.emoji-wysiwyg-editor[data-expandable="true"]',$(e.target)))
        bindHiddenAtWho $('.emoji-wysiwyg-editor', $(e.target))

    $('.list-entries').on 'keyup', '.comment-form .emoji-wysiwyg-editor', (e) ->
      commentInput = $(e.currentTarget)
      commentForm  = commentInput.parents('.comment-form:first')

      showHintIfNecessary(commentForm)

      if e.which == 27
        cancelForm(commentForm)

window.delete_comment = ->   
  $('.list-entries').on 'click', '[data-action="delete"]', (e) ->
    comment_str = $(e.currentTarget).closest('.list-entries-item').find('.entry-content .entry-options .comment_count').text()
    comment_str = comment_str.replace(/\s+/g, " ")
    comment_count_val = comment_str.replace('Comments (','').replace(')', '')
    comment_count = parseInt(comment_count_val)
    comment_count = comment_count - 1
    comment_count_set = 'Comments (' + comment_count + ')'

    if confirm("Permanently delete this?")  
      e.stopPropagation()
      $.ajax
        url: '/e/' + $(e.currentTarget).data('entry_id') + '/reactions/' + $(e.currentTarget).data('id')
        type: 'DELETE'
        success: (data) ->
          $(e.currentTarget).closest('.list-entries-item').find('.entry-content .entry-options .comment_count').text(comment_count_set)
          $(e.currentTarget).parents('.comment:first').remove()
          

$ ->
  init_comment_form()
  delete_comment()