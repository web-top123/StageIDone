jQuery ->
  $('#edit-user-details').parent().parent().css("overflow","visible")
  $('.tel_input[type=tel]').parent().css("overflow","visible")
  $('.tel_input[type=tel]').intlTelInput(
    nationalMode:false, 
    formatOnInit: true,
    initialCountry: "us")
