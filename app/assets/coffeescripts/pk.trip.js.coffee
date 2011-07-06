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
    $(".showContact").click(() -> revealContact($(this).data("contact-id"))) if PK.mobile
  
  revealContact = (contactID) ->
    contact = PK.UserData.contacts[contactID]
    dialog = $(PK.render("trip_contact_details", {
      contact: contact
      sent: trip.recipients.indexOf(contact._id) != -1
      text: text
    })).appendTo("body").show().page().dialog().trigger("enhance")
    # manually style and reprogram the close button, because jqm doesn't like our homebrew dialog
    dialog.find(":jqmData(rel=back)").addClass("ui-btn-left").unbind('click').click(() -> dialog.remove(); false )
    # jQm doesn't scroll up for dialogs on long pages
    window.scrollTo(0, 0)
    
    dialog.find(".sendCard").button().click(sendCard)
    false = (args) ->
  
    false # stop regular jQuery mobile actions
    
  renderUnsentContacts = () ->
    contactDictionary = contacts
    listHTML = for contact in (PK.UserData.contactsByName || [])
      PK.render("trip_contact", {contact: contact, sent: false, text: text})
    
    if listHTML.length > 0
      list = $("#tripContacts").append(listHTML.join(""))
    else
      $("#tripContacts").append(PK.render("trip_no_contacts"))
    
  renderSentContacts = () ->
    contactDictionary = contacts
    recipients = (contactDictionary[recipient] for recipient in trip.recipients).sort((c1, c2) -> if c1.last_name < c2.last_name then -1 else 1)
    recipientHTML = for r in recipients
      PK.render("trip_contact", {contact: r, sent: true, text: text})      
    
    if recipientHTML.length > 0
      list = $("#tripRecipients").append(recipientHTML.join(""))
    else
      $("#tripRecipients").append(PK.render("trip_no_recipients"))
  
  sendCard = () ->
    link = $(this).addClass("sending").removeClass("sent").removeClass("errored")
    # disable the link and update its text
    if PK.mobile 
      # also update the button class to show the ajax spinner
      link.unbind("click").closest(".ui-btn").addClass("loading")
    else 
      link.button({label: text.sending, disabled: true})
    
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
      # need to update flags to download new data
      contactID = link.data("contact-id")
      contact = contacts[contactID]
      PK.UserData.cardSent(trip, contact)

      link.removeClass("sending").addClass("sent")
      message = $("<li>#{PK.render("trip_card_sent", {text: text, contact: contact})}</li>");
      newHTML = $(PK.render("trip_contact", {contact: contact, sent: true, text: text}))
      if PK.mobile 
        # add the new sent contact to the sent list, and refresh that
        $("#tripRecipients").append(newHTML).listview('refresh')

        # add the sent notice to the list, and refresh it
        link.click(sendCard).closest("li").after(message).closest("ul").listview("refresh")
        link.closest(".ui-btn").removeClass("loading")
        page = link.closest(".ui-page").bind "pagehide.removeMessage", () -> 
          message.remove()
          page.unbind(".removeMessage")
        
      else
        link.button("option", "label", text.sent)
        contactNode = link.closest("li")
        contactNode.append(PK.render("trip_card_sent", {text: text, contact: contact}))
        setTimeout(() -> 
          newHTML.hide().appendTo("#tripRecipients").slideDown()
        , trip.animationInterval)
      
  cardError = () ->
    alert "Error!"
    
  init = (tripInfo) ->
    # render everything as soon as we can
    tripData = tripInfo
    PK.UserData.whenAvailable () -> 
      trip = PK.UserData.trips[tripData._id]
      $("#tripName").html(trip.description)
      renderList()
    
  {
    init: init
    revealContact: revealContact
    animationInterval: 2500
  } 