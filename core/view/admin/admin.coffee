Backbone = require 'backbone'
React = require 'react'

AdminDashboard = require './dashboard.jsx'

getInitializeProps = ->
  return JSON.parse $('#initialize-props').html()

AdminRouter = Backbone.Router.extend
  routes:
    'admin/dashboard': 'dashboard'

  dashboard: ->
    React.render React.createElement(AdminDashboard, getInitializeProps()), document.querySelector('#main-block')

new AdminRouter()
Backbone.history.loadUrl location.pathname
