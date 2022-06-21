# Private Events

This is a project meant to make a clone of the EventBrite website using Ruby on Rails.

Several models that would have relationships between eachother to mimic EventBrite behavior.

Those models are:

Events

- can be private OR public.
- have a name, description, time and place.
- only users can create these, only the creator can modify the event.
  -has_one creator, who is a user
- users can create many events
- users can be invited to many events, events can have many users invited to them (many_to_many)
- have information that may or may not be provided based on settings
  - events attendees
  - pending invites
  - event itself (can choose to not list it on index page)

AttendedEvents (invites?)

- invites can be accepted or not
- only the user recieving the invite can accept it
- only the creator of an event can extend invites to it
- only one invite can exist between user and event

Users

- has personal data: username, name, email
- can follow other users? maybe allow following events?
- has privacy settings for events they are joining

The models use several privacy settings:

- public - anyone can see info
- protected - some can see (undecided on who? maybe followers and those invited?)
- private - only owner and those invited

For the website several important views are implemented:

events:

    - index - shows all future and past events that user has permissions to view
        - events show are based on event privacy settings
        - maybe add some form of filters?
        - each event can be joined from index or can be redirected to event page
            - TODO: show join and leave buttons contextually? or too resource intensive
    - show - shows the individual event
        - has option to join or leave event contextually
        - amount of info shown based on event settings
        - has moderator tools for creator to invite people or revoke invites

users:

    - show - shows the page of a user (amount of info based on privacy settings)
        - events the user is invited to / is attending
        - social media links

To-do List:

- move the bottom bar to a layout? not sure if that is best way to go about it.
- move more complex controller functions to helper functions (use concerns?)
- make join and leave buttons contextual
- clean up views to be more DRY, shove more stuff into partials
  - resource vs locals : {}
- implement alert for unimplemented functionalities
