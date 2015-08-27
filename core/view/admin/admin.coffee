Backbone = require 'backbone'
Cookies = require 'js-cookie'
React = require 'react'
$ = require 'jquery'

AdminDashboard = require './dashboard.jsx'

$.ajaxSetup
  headers:
    'X-Token': Cookies.get('token')

getInitializeProps = ->
  return JSON.parse $('#initialize-props').html()

AdminRouter = Backbone.Router.extend
  routes:
    'admin/dashboard': 'dashboard'

  dashboard: ->
    React.render React.createElement(AdminDashboard, getInitializeProps()), document.querySelector('#main-block')

new AdminRouter()
Backbone.history.loadUrl location.pathname
