Event = require 'the-event'

Route = require './route'
Flow = require './flow'

class Router extends Event

  mode: null
  flow: null
  routes: null
  middlware: null

  constructor:( @mode )->
    @routes = []
    if @mode?
      @flow = new Flow @
      @flow.on 'run:pending', ( url )=> @emit 'url:change'

  use:( Middleware )->
    return if @middleware?
    @middleware = new Middleware
    @middleware.on 'url:change', => @route @middleware.get_url()

  init:->
    if @middleware?
      url = @middleware.get_url()
      if url?
        @middleware.push_state url

  get:(pattern, run, destroy, dependency)->
    route = new Route pattern, run, destroy, dependency
    @routes.push route
    return route

  route:( url )->
    url = '/' + url.replace /^[\/]+|[\/]+$/m, ''
    for route in @routes
      if route.matcher.test url
        if @flow?
          @flow.run url, route
        else
          @emit 'url:change', url
          route.run url
        return route

    throw new Error "Route not found for url '#{url}'"

  push:( url, title, state)->
    if @middleware?
      @middleware.push_state url, title, state
    else
      @route url

  replace:( url, title, state, silent )->
    if @middleware?
      @middleware.replace_state url, title, state

module.exports = Router