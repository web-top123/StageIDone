validateEmail = (email) ->
  pat = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  pat.test email

updateHiddenInput = (invitationsPanel) ->
  invitees = []
  for emailLi in $('.invitations-panel_potential-invitations_list li.active', invitationsPanel)
    invitees.push $(emailLi).data('email_address')
  $('[data-bind="emailAddresses"]', invitationsPanel).val invitees

updateSubmitLabel = (invitationsPanel) ->
  invitationsNum = $('.invitations-panel_potential-invitations_list li.active', invitationsPanel).length
  buttonEl = $('.invitations-panel_actions input', invitationsPanel)
  invitationVerb = buttonEl.data('verb')
  if invitationsNum == 1
    buttonEl.val invitationVerb
  else
    buttonEl.val invitationVerb + ' ' + invitationsNum + ' people'

updateEmptyIndicatorVisibility = (invitationsPanel) ->
  if $('.invitations-panel_potential-invitations_list li.active', invitationsPanel).length
    $('.empty', invitationsPanel).hide()
    $('.invitations-panel_actions', invitationsPanel).slideDown(75)
  else
    $('.empty', invitationsPanel).show()
    $('.invitations-panel_actions', invitationsPanel).hide()

$ ->
  $('.invitations-panel').on 'click', '[data-action="addToTeam"]', (e) ->
    panel = $('.invitations-panel')
    li = $(e.currentTarget).parents('li:first')
    li.addClass('active')
    updateEmptyIndicatorVisibility(panel)
    updateHiddenInput(panel)
    updateSubmitLabel(panel)

  $('.invitations-panel').on 'click', '[data-action="removeFromTeam"]', (e) ->
    panel = $('.invitations-panel')
    li = $(e.currentTarget).parents('li:first')
    li.removeClass('active')
    updateEmptyIndicatorVisibility(panel)
    updateHiddenInput(panel)
    updateSubmitLabel(panel)

  $('.invitations-panel').on 'keydown', '[data-bind="addOrInviteByEmailAddress"]', (e) ->
    panel = $('.invitations-panel')

    ul = $('.invitations-panel_potential-invitations_list')
    if (e.keyCode == 13)
      e.preventDefault()
      fieldVal = $(e.currentTarget).val()
      foundMatch = false

      for li in $('.invitations-panel_potential-invitations_list li', panel)
        if !foundMatch and ($(li).data('email_address') is fieldVal)
          foundMatch = true
          $(li).addClass('active')
          $(e.currentTarget).val ''

      if !foundMatch and fieldVal.length and validateEmail(fieldVal)
        ul.prepend $('<li class="active" data-email_address="' + fieldVal + '"><strong>' + fieldVal + '</strong><span class="indicator">Invitation</span><a data-action="removeFromTeam" class="bad-button">Remove</a></li>')
        $(e.currentTarget).val ''

      updateEmptyIndicatorVisibility(panel)
      updateHiddenInput(panel)
      updateSubmitLabel(panel)

  $('.invitations-panel').on 'click', '[data-action="removeInvitee"]', (e) ->
    panel = $('.invitations-panel')
    li = $(e.currentTarget).parents('li:first')
    li.remove()
    updateEmptyIndicatorVisibility(panel)
    updateHiddenInput(panel)
    updateSubmitLabel(panel)

  $('.invitations-panel').on 'keydown', '[data-bind="potentialInvitee"]', (e) ->
    panel = $('.invitations-panel')
    ul = $('.invitations-panel_potential-invitations_list')
    if (e.keyCode == 13)
      e.preventDefault()
      if $(e.currentTarget).val().length && validateEmail($(e.currentTarget).val())
        ul.prepend $('<li class="active" data-email_address="' + $(e.currentTarget).val() + '"><strong>' + $(e.currentTarget).val() + '</strong><a data-action="removeInvitee" class="bad-button">Remove</a></li>')
        $(e.currentTarget).val ''
        updateEmptyIndicatorVisibility(panel)
        updateHiddenInput(panel)
        updateSubmitLabel(panel)