# [Private Events](http://34.203.167.251:3000/) <!-- omit in toc -->

- [Project Overview](#project-overview)
  - [The Technology stack](#the-technology-stack)
- [Personal Reflection](#personal-reflection)
  - [Connecting users to events](#connecting-users-to-events)
  - [Inviting Users to Events](#inviting-users-to-events)
    - [My solution](#my-solution)
    - [Current Design](#current-design)
  - [Big Front End Redesign](#big-front-end-redesign)
    - [AlpineJS sprinkles](#alpinejs-sprinkles)
  - [Testing Revamp](#testing-revamp)
    - [Systems Tests, Capybara and Accessibility](#systems-tests-capybara-and-accessibility)
      - [Accessibility concerns](#accessibility-concerns)
  - [Path to Production](#path-to-production)
    - [Starting off with AWS](#starting-off-with-aws)
    - [Ruby on Whales (I wish)](#ruby-on-whales-i-wish)
    - [Capybara and Debug](#capybara-and-debug)
    - [Launching the Site](#launching-the-site)
  - [Final Reflection](#final-reflection)
- [Actual Readme](#actual-readme)
  - [Models](#models)
    - [Model Structure](#model-structure)
    - [Model Associations](#model-associations)
      - [Further association details](#further-association-details)
    - [Model Validations](#model-validations)
  - [Routing and Controllers](#routing-and-controllers)
  - [Potential Improvements](#potential-improvements)

## Project Overview

Project site: <http://35.243.197.55/>

Eventbrite is a website that is based around events, users can create events, join events and invite others to events. From what I can gather Eventbrite is built with a Django framework, uses React in the front end, a MySQL database and is hosted on AWS.

The Private Events project is based off an assignment from the Odin Project to make an Eventbrite-esque website. I decided to take that a step further and make as close to a clone of as possible.

### The Technology stack

Vanilla HTML, mix of vanilla CSS and Tailwind CSS, mix of vanilla Javascript and AlpineJS, Ruby on Rails framework, amazon managed RDS PostgreSQL database, Docker container running on an Amazon EC2 instance

## Personal Reflection

[**Think of this section as one of those crappy stories before a recipe, click this to skip to an actual description of the site. Although, if you actually found this repository it was probably from my resume and you would be interested. I will probably turn this part into a blog post or something. IDK**](#actual-readme)

The project was initially a super basic Rails CRUD site. However, the server-side has largely been unchanged since the first iteration. There were two main challenges I had to solve to arrive at this first MVP:

### Connecting users to events

Users can attend many events and events can be attended by many users, what is the best way to associate those models (I had at this point decided that User and Event would be models).

I chose to solve this issue by using a many-to-many-through association, which resulted in the slightly oddly named `UserEventPermission` model connecting users to events. But soon I was faced with another task as part of the project

### Inviting Users to Events

While this may seem like a super trivial problem at face value its actually surprisingly difficult to decide on a way to allow user to sign up for events but also receive an invite to an event and then accept that invite.
![Screenshot for extra credit from odin](https://i.imgur.com/MCWt7Vj.png)

I went a bit further than this request and allowed event creators to either set their Event to public or private. Public events anyone could sign up for but private events needed an invite. Thus, I to create permissions in such a way that:

- The attendance of an event could only be **created** by the user attending. Billy cannot sign up on behalf of Johnny.
- An invite to an event can be extended to anyone by anyone will sufficient permissions
- The invite can **only** be accepted by the target of the invite

#### My solution

I ended up considering two potential approaches: giving permissions an property to indicated if they were accepted or creating separate permissions for accepted invites and attendances. I decided on the latter, to create multiple types of permissions which included a permission of type `accept_invite` for an extended invite and a permission of type `attend` for attendances.

My approach also meant that I could create additional permissions of `owner` and `moderate` which was nice. But largely I felt that I wanted to keep my approach as close to Rails as possible. I could not figure out a good way approach accepting invite without going outside Rails.

With the approach I took I set up a callback to destroy `accept_invite` if it got accepted. I also created a uniqueness validation to ensure a user was not invited to an event they were already attending.

The only issue I ran into is I could not find a good way outside of injecting the current user from the controller into the model to check which user is actually creating a permission. Checking who is creating a permission is central to ensuring users cannot create attendances on behalf of others.

I briefly considered the approach of giving each permission a creator and checking if that user had the permissions for creation. I quickly ran into the issue when I needed to destroy that permission since the ability to revoke permissions is much more open than creating them.

#### Current Design

Thus, I arrived at the current design. The `UserEventPermission` class validates uniqueness across event id, user id and type of permission to prevent duplicates. It uses a custom validation to ensure a user cannot both attend and have an invite. Finally, permissions themselves are created and destroyed using calls to class methods that take the current user as a parameter.

### Big Front End Redesign

While I was working on the site I came across a suggestion that one way to show my ability to implement a design was to take a design and implement it perfectly, that is pixel perfectly. Thus, I decided to try to reproduce the actual Eventbrite website as pixel perfect as possible.

Index page:
![Index page](https://i.imgur.com/dKZnvMk.png)
Event page:
![Event page](https://i.imgur.com/25yWgLL.png)

I also tried to maintain the same consistency across screen sizes:
![Event Creation Small screen comp](https://i.imgur.com/RFQAHae.png)

Overall, I think I did a very good job, some of the minor differences come from me attempting to make certain parts to conform to accessibility but I will discuss that later. Some other minor changes were made simply because I thought the design was better such as in the above screen shot. It made no sense for the menu to have as much white space as it did.

#### AlpineJS sprinkles

When trying to make the website pixel perfect I ran into multiple minor visual features that I simply could not code using only CSS and HTML. For example:

![Price for event moving](https://media0.giphy.com/media/AXNapLTRxrKYdq3COu/giphy.gif)

As we can see in the above gif, when the bar for the event reaches the top of the page it becomes sticky but also the price of tickets gets added to it (or becomes visible in our case). Having looked into the problem I was unable to find a way to achieve this effect with just CSS, I had to reach for JavaScript.

I decided to use AlpineJs because I wanted to try something new and it markets itself as Tailwind for JavaScript. The way it works is that you can simply drop in a single script in your application view and it will just work.

The actual for making the price move looks something like this:

```html
<nav x-data>
  <div x-show="! $store.user_in_view">
    <span><%= resource.price %></span>
  </div>
</nav>
```

Not to get too into the details but `x-data` marks the element and its children as alpine objects and `x-show` declares the property that will indicate whether or not to to show the price. The actual code to define `user_in_view` is sound elsewhere in place into the global store for use in this view. (To get even more specific the Alpine provides an intersect observer I used to check if the user partial is in view.)

I sprinkled in Alpine in a few other places such as dropdown menus or the password strength bar

![Password Strength](https://media4.giphy.com/media/wWEv4B3bU8HqP1QN85/giphy.gif)

### Testing Revamp

As I kept going with the site I kept reading about best practices and one of the books I read was _Practical Object Oriented Design in Ruby_. That book had quite a detailed section about writing the minimal amount of tests and writing tests that were decoupled. I recommend the book but to summarize: test only the public interface, verify that values are correct for incoming messages and only verify that outgoing messages are sent if they modify the state of object under test.

Armed with new approach I had to figure out how to decouple my tests and I ended up landing on using FactoryBot in combination with Faker for actual values. FactoryBot is a gem that allows you to set up Factories for each model you have and it greatly reduces the setup needed in the tests.

To make sure my system was fully tested I created model, request and systems tests. The systems tests actually resulted in quite a few issues.

#### Systems Tests, Capybara and Accessibility

Setting up systems tests was actually fairly simple as soon as I figured the command for them with RSpec. It was my first time setting them up but I spent most of my time in the debugger sending commands to the browser, then writing them down in the tests.

One of the larger issues that I ran into with systems tests and one I could not solve is for some reason headless chrome kept hanging after the completion of the tests. I never figured out the issue and unfortunately that left some of my tests in a state where they pop up a chrome window to execute.

##### Accessibility concerns

But as I was creating the tests I also ran accessibility scans on each of the pages and I found a ton of issues.

![Contrast problem](https://i.imgur.com/bY4rmaU.png)![Contrast Example](https://i.imgur.com/gvScD0K.png)

Largely, this was expected, I had never dealt with accessibility before but to my astonishment many of the problems existed on the actual Eventbrite page as well. Thus, I had to make changes to my website that made it more dissimilar to the original to improve quality.

### Path to Production

At this point my project pixel perfect, fully tested and ready to ship for production. Quick and easy right? Wrong. Right about the time that I wanted to have an actual site for my project Heroku decided that it was getting rid of its free tier. There went my quick and free serving of the project so I had to explore further.

I explored a bunch of different options including Linode, Netlify, Render, Railway, Cyclic and others. I decided that for the sake of experience I wanted to create my project on one of the big commonly used platforms with an extensive free tier: AWS.

#### Starting off with AWS

My first foray with launching my project on AWS had me trying to set up the project on Elastic Beanstalk since that already had images with Ruby running. I was never able to get that up and running. Based on what I found the Ruby image has a very out of date PostgreSQL dependency (something like version 9) and I was never able to connect to a database.

I spent a long time trying to get that to work, however, I had little visibility into the actual instance running so I only could try to fix issues by tailing logs and waiting for 10+ minutes between launches of instances. I decided that I needed a way to make sure I had all the dependencies I needed without relying on the server, thus Docker.

#### Ruby on Whales (I wish)

I dove into attempting to put my website fully on docker mainly following _Docker for Rails Developers_ and Docker on Whales (an Evil Martians blog post - all credit to them for the witty title). I got most of the set up, a Dockerfile for development, production as well as docker-compose for both.

At this point I should note, I have been a bit misleading, much of my process getting systems tests going happened at the same time as me trying to get Docker set up. From that stemmed my issues, I simply did not know enough about networking to correctly set up testing and trouble shooting the way that I wanted.

#### Capybara and Debug

The way both Capybara and the debug gem work is that you can designate some port that you can connect to them on (at least I think, I could be totally wrong). I set up port mappings in docker-compose and made those ports available in the with debug and capybara but I could not get them to work.

I wanted to connect my VSCode as a debugger and I was able to do that outside of docker-compose but using the port connection did not work for me. Capybara on the other hand I simply could not get to work. There were a few blog posts I looked at but they had so many changes I would need to make that I decided that this approach was not worth it given I could not even get debugging to work.

#### Launching the Site

After much trial and error I can to a solution that seemed good enough. I built a production docker image of the site and pushed it to Docker hub. From there I simply set up an Amazon EC2 instance to pull that image down and run it on restart.

Thus, I ended up will a very ghetto build process of pushing to dockerhub and then restarting the EC2 instance to update the website. I can also just sign in and manually pull down the image and launch but I added the restart option in case the instance restarted.

### Final Reflection

Completing this Private Events website took me something like six months from the first commit to actually finishing this Readme and having the site up. The whole time I was working on the site I was constantly reading and learning more and more things. I ran headfirst into the issue of scope creep, at some point I simply had to decide that the site had enough features. I decided to not add anymore features when I saw I would be using those technologies in upcoming Odin projects.

I really wanted to add many Hotwire features to the application to speed up load times and reduce the amount of page reloads. I also found out then that the Rails way of sprinkling in JavaScript was with Stimulus, another technology that was new to me.

Over the course of this project I learned a lot through trying to solve problems and just by learning on the side. I came to the conclusion that the most important thing to know is what you don't know. By understanding my weaknesses in many areas over the course of this project I think I became a much better developer.

Its not only important to know how to use some technology say Docker or AlpineJs or Tailwind. It is equally important to know **of** technologies. I don't know how Docker Swarm or Kubernetes works but I know now that they are container orchestration tools that can be user to scale out the infrastructure of a site. In this project I learned how to use Tailwind and Alpine but I also learned of other solutions like Sass, PostCss, Sitmulus, Lit, view components. While I don't know how to use any of them yet, I can always learn and I am aware of them enough to potentially decide to reach for them.

## Actual Readme

### Models

I approached the problem with just three basic rails models: `Event`, `User` and `Permission` (more specifically `UserEventPermission`).

#### Model Structure

The models have fairly basic fields: name, date, location, etc. Some fields worth noting:

- `Event` - has fields `display_privacy` and `event_privacy` to determine who can join and see events, those can be set to `public, protected and private`
- `UserEventPermission` - has the `permission_types`: `accept_invite, attend, moderate, owner`
  - each permission connection is unique per event (a user can only have 1 attend permission to a particular event, 1 owner, etc)
  - the `owner` permission is given automatically to the user that creates an event
  - the moderator permission largely does nothing at the moment, but could be used to give elevated permissions to users
  - the `attend` permission is meant to represent that a user is attending an event
  - the `accept_invite` permission is meant to represent that a user has been invited to an event but has not yet accepted said invite
    - accept and attending permissions compete for the same spot, meaning you can only have one or the other. To attend you must get rid of the invite and you cannot be invited if you are attending
- `User` - has authentication done with Devise but with custom `Users/Registrations` controllers

#### Model Associations

The behaviors are pretty self explanatory: a `User` can create an `Event`, a `User` has `Permissions` for a particular `Event`. Thus, this all gets represented in models:

- `Event`
  - belongs to a `User` (creator)
  - has many `Permissions`
- `User`
  - has many `Permissions`
- `Permissions`
  - belong to a `User`
  - belong to a `Event`

##### Further association details

The interactions on the website are built around a many-to-many-through association with `UserEventPermission` connecting users to events. Permissions have various types and both users and events have associations to filter for particular types: `events_attended`, `users_attending`, etc.

#### Model Validations

The model validations are all fairly basic with simply a few required fields for several of the models. The only validations worth noting are a few uniqueness validations to ensure no duplicate permissions but allowing a user to have multiple types of permissions.

### Routing and Controllers

Typically on a Rails site using Devise for user authentication the creation of user accounts and sessions would all be done by Devise controllers. I was forced to change this to better mimic certain behaviors of the Eventbrite site. Thus, registrations are handled by `users/registrations`.

Permission creation and deletion is handled by sending POST and DELETE requests to the `user_event_permissions` route. That in turned calls `UserEventPermission.create` or `.delete` with the current user and request parameters to decide what to create and if the current user has permission for that action.

### Potential Improvements

With any project or piece of software at some point you need to decide that it is good enough to ship. While I think this project is good enough to ship there are many improvements I would have liked to add to it:

- General code refactoring
  - the `UserEventPermssion` model could use refactoring, it has multiple code smells and is too tightly coupled to users and events with a permission is created
    - There is likely some design pattern that could be used to clean up the code but I did not know it
  - By using TailwindCSS my HTML has a lot of duplicated info and just frankly crap in it.
    - I learned fairly late into the project about using `@apply` to reuse styling
    - Also, maybe just BEM and PostCSS would have been a better approach
  - the `view_component` gem likely would have helped clean up many of my duplicated views
- Page Reloads - too many of my post requests force a full reload, that should not be the case
  - HTML over the wire (hotwire) would likely have helped in some places
- User profile page - while users can receive invite, and certain events can only be joined with invites I don't actually do much with the invites. This could be extended.
- Rich text descriptions for events
