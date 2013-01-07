# This a weirdo file. We don't create a Window class, we just add stuff to
# the DOM window.

Native = require 'native'
fs = require 'fs'
_ = require 'underscore'
$ = require 'jquery'
{CoffeeScript} = require 'coffee-script'
Config = require 'config'
Syntax = require 'syntax'
RootView = require 'root-view'
Pasteboard = require 'pasteboard'
require 'jquery-extensions'
require 'underscore-extensions'
require 'space-pen-extensions'

windowAdditions =
  rootViewParentSelector: 'body'
  rootView: null
  keymap: null
  platform: $native.getPlatform()

  # This method runs when the file is required. Any code here will run
  # in all environments: spec, benchmark, and application
  startup: ->
    @config = new Config
    @syntax = new Syntax
    @setUpKeymap()
    @pasteboard = new Pasteboard

    $(window).on 'core:close', => @close()
    $(window).command 'window:close', => @close()

  # This method is intended only to be run when starting a normal application
  # Note: RootView assigns itself on window on initialization so that
  # window.rootView is available when loading user configuration
  attachRootView: (pathToOpen) ->
    if rootViewState = atom.getRootViewStateForPath(pathToOpen)
      RootView.deserialize(rootViewState)
    else
      new RootView(pathToOpen)

    $(@rootViewParentSelector).append(@rootView)
    $(window).focus()
    $(window).on 'beforeunload', =>
      @shutdown()
      false

  shutdown: ->
    @rootView.deactivate()
    $(window).unbind('focus')
    $(window).unbind('blur')
    $(window).off('before')

  setUpKeymap: ->
    Keymap = require 'keymap'

    @keymap = new Keymap()
    @keymap.bindDefaultKeys()
    @keymap.loadDirectory(require.resolve('keymaps'))

    @_handleKeyEvent = (e) => @keymap.handleKeyEvent(e)
    $(document).on 'keydown', @_handleKeyEvent

  stylesheetElementForId: (id) ->
    $("head style[id='#{id}']")

  requireStylesheet: (path) ->
    unless fullPath = require.resolve(path)
      throw new Error("Could not find a file at path '#{path}'")
    window.applyStylesheet(fullPath, fs.read(fullPath))

  removeStylesheet: (path) ->
    unless fullPath = require.resolve(path)
      throw new Error("Could not find a file at path '#{path}'")
    window.stylesheetElementForId(fullPath).remove()

  applyStylesheet: (id, text) ->
    unless window.stylesheetElementForId(id).length
      $('head').append "<style id='#{id}'>#{text}</style>"

  reload: ->
    if rootView?.getModifiedBuffers().length > 0
      atom.confirm(
        "There are unsaved buffers, reload anyway?",
        "You will lose all unsaved changes if you reload",
        "Reload", (-> Native.reload()),
        "Cancel"
      )
    else
      Native.reload()

  onerror: ->
    atom.showDevTools()

  measure: (description, fn) ->
    start = new Date().getTime()
    fn()
    result = new Date().getTime() - start
    console.log description, result

window[key] = value for key, value of windowAdditions
window.startup()

requireStylesheet 'reset.css'
requireStylesheet 'atom.css'

if nativeStylesheetPath = require.resolve("#{platform}.css")
  requireStylesheet(nativeStylesheetPath)
