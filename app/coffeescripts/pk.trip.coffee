PK ?= {}

# define a handler for Trip management
PK.Trip = do ($) ->
  tripData = contacts = null
  
  text = 
    send: "send card"
    sending: "sending"
    sent: "sent!"
    error: "error!"
    cardSent: "Saved!  Moving up to sent cards..."
  
  renderList = () ->
    contacts = PK.UserData.contacts
    renderUnsentContacts()
    renderSentContacts()
    
  renderUnsentContacts = () ->
    contactDictionary = contacts
    recipients = tripData.recipients
    listHTML = for contact in (PK.UserData.contactsByName || [])
      JST.trip_contact({contact: contact, sent: false, text: text}) unless contact._id in recipients
    
    if listHTML.length > 0
      $("#contacts").html(listHTML.join(""))
    else
      $("#contacts").html(JST.trip_no_contacts())
    
  renderSentContacts = () ->
    contactDictionary = contacts
    recipients = tripData.recipients
    recipientHTML = for recipient in recipients
      JST.trip_contact({contact: r, sent: true, text: text}) if r = contactDictionary[recipient]      
    
    if recipientHTML.length > 0
      $("#recipients").html(recipientHTML.join(""))
      $(".sendCard").button().click(sendCard)
    else
      $("#recipients").html(JST.trip_no_contacts())
  
  sendCard = () ->
    link = $(this).button({label: "sending...", disabled: true}).addClass("sending").removeClass("sent").removeClass("errored")
    $.ajax({
      url: "/trip/send_card"
      type: "post"
      data:
        contact_id: link.data("contact-id")
        trip_id: tripData._id
      success: (results) -> cardSent(results, link)
      error: (results) -> cardError(results, link)
    })
    
    # don't jump to top after click
    false

  cardSent = (results, link) ->
    if results.result
      link.button("option", "label", text.sent).removeClass("sending").addClass("sent")
      # get the parent list item
      contactID = link.data("contact-id")
      contact = contacts[contactID]

      contactNode = link.closest("li")
      contactNode.append(JST.trip_card_sent({text: text, contact: contact}))
      
      setTimeout(() -> 
        contactNode.slideUp()
        tripData.recipients.push(contactID)
        $(JST.trip_contact({contact: contacts[contactID], sent: true, text: text})).hide().appendTo("#recipients").slideDown()
      , trip.animationInterval)
      
  cardError = () ->
    alert "Error!"
    
  init = (tripInfo) ->
    # immediately render the trip name, etc.
    tripData = tripInfo
    $("#tripName").html(tripData.location_name)
    $("body").bind(PK.UserData.userLoadSuccessEvent, renderList)

  trip =
    init: init
    animationInterval: 2500