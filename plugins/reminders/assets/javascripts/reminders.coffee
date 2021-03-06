#= require reminders/on_reminders
#= require_tree ./reminders/.

# We do the check again so tests don't trigger this initialization
onReminders -> if $('#reminders-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/reminders/)
  collectionId = parseInt(match[1])

  window.model = new MainViewModel(collectionId)
  ko.applyBindings(window.model)

  $.get '/repeats.json', (data) ->
    window.model.repeats $.map data, (repeat) -> new Repeat repeat

    $.get "/plugin/reminders/collections/#{collectionId}/reminders.json", (data) ->
      window.model.reminders $.map data, (reminder) ->
        reminder.repeat = window.model.findRepeat repeatId if repeatId = reminder.repeat_id
        new Reminder reminder

  $('.hidden-until-loaded').show()
