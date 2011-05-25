PK ?= {}

# define a handler for Trip management
PK.Trip = do ($) ->
  tripData = trip = contacts = null
  
  text = 
    send: "send card"
    sendAgain: "send another card"
    sending: "sending"
    sent: "sent!"
    error: "error!"
    cardSent: "Saved!  Moving up to sent cards..."
  
  renderList = () ->
    contacts = PK.UserData.contacts
    renderUnsentContacts()
    renderSentContacts()
    $(".sendCard").button().click(sendCard)
    
  renderUnsentContacts = () ->
    contactDictionary = contacts
    recipients = trip.recipients
    listHTML = for contact in (PK.UserData.contactsByName || [])
      PK.render("trip_contact", {contact: contact, sent: false, text: text}) unless contact._id in recipients
    
    if listHTML.length > 0
      $("#tripContacts").append(listHTML.join(""))
    else
      $("#tripContacts").append(PK.render("trip_no_contacts"))
    
  renderSentContacts = () ->
    contactDictionary = contacts
    recipients = trip.recipients
    recipientHTML = for recipient in recipients
      PK.render("trip_contact", {contact: r, sent: true, text: text}) if r = contactDictionary[recipient]      
    
    if recipientHTML.length > 0
      $("#tripRecipients").append(recipientHTML.join(""))
    else
      $("#tripRecipients").append(PK.render("trip_no_contacts"))
  
  sendCard = () ->
    console.log("Sending!")
    unless PK.mobile
      link = $(this).button({label: "sending...", disabled: true}).addClass("sending").removeClass("sent").removeClass("errored")
    
    $.ajax({
      url: "/trip/send_card"
      type: "post"
      data:
        contact_id: link.data("contact-id")
        trip_id: trip._id
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
      contactNode.append(PK.render("trip_card_sent", {text: text, contact: contact}))
      
      setTimeout(() -> 
        contactNode.slideUp()
        # need to update trip in localStorage
        trip.recipients.push(contactID)
        $(PK.render("trip_contact", {contact: contacts[contactID], sent: true, text: text})).hide().appendTo("#recipients").slideDown()
      , trip.animationInterval)
      
  cardError = () ->
    alert "Error!"
    
  init = (tripInfo) ->
    # render everything as soon as we can
    tripData = tripInfo
    $("body").bind PK.UserData.userLoadSuccessEvent, () -> 
      trip = PK.UserData.trips[tripData._id]
      $("#tripName").html(trip.description)
      renderList()

  {
    init: init
    animationInterval: 2500
  } 