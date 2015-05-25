"""
  li./package.coffee
  
  There is a different one of these for each pkg version
"""        

shell      = require 'shell'
{execSync} = require 'child_process'

module.exports = 
class Package
  
  @activateAllLoaded = ->
    for pack in atom.packages.getLoadedPackages()
      if not pack.mainActivated
        pack.activationDeferred ?= resolve:(->), reject:(->)
        pack.activateNow()
    null
    
  @nameIsValid = (name) ->
    if name is 'Atom' then return yes
    if /[^\-\w]/.test name
      console.log 'package-cop: ignoring package with invalid name: "' + name + '"'
      return no
    yes
    
  @packageIdFromNameVersion = (name, version) -> 
    versParts = version.split '.'
    for versPart, idx in versParts
      versPart = versPart.replace /[^\d]/g, ''
      while versPart.length < 4 then versPart = '0' + versPart
      versParts[idx] = versPart
    name = if name is 'Atom' then '--atom' else 'pkg-' + name
    name + '-' + versParts.join ''
    
  @nameFromPackageId = (packageId) -> 
    if packageId[0..5] is '--atom' then 'Atom'
    else /^pkg-(.*)-\d+$/.exec(packageId)[1]
    
  @titleizeName = (name) ->
    title = name.toLowerCase().replace /-/g, ' '
    regex = new RegExp '(^|\\W)\\w', 'g'
    while (match = regex.exec title)
      title = title[0...match.index] + 
              match[0].toUpperCase() + 
              title[regex.lastIndex...] 
    title
    
  @removeUninstalled = (packages) ->
    allNames = atom.packages.getAvailablePackageNames().concat 'Atom'
    for id, pkg of packages
      if pkg.name not in allNames then delete packages[id]
    
  constructor: (@name, @version) ->
    if typeof @name is 'object'
      {@name, @version, @repoURL, @states, @savedState} = @name
    @packageId   = Package.packageIdFromNameVersion @name, @version
    @title       = Package.titleizeName @name
    @states     ?= {}
    if not @savedState then @saveState()
  
  addVersionToTitle: -> 
    if not @titleHasVersion
      @title += ' (' + @version + ')'
      @titleHasVersion = yes
      
  trimPropertiesForSave: -> 
    {@name, @version, @repoURL, @states, @savedState}
      
  uninstall: ->
    if @name is 'Atom' then return
    uninstall = atom.confirm
      message: 'Package Cop: Confirm Uninstall\n'
      detailedMessage: 'Are you sure you want to uninstall the pkg ' + @name +
          '? The pkg will be removed along with all package-cop test results.'
      buttons: ['Cancel', 'Uninstall']
    if uninstall is 0 then return false
    try
      execSync 'apm uninstall ' + @name, encoding: 'utf8'
    catch e
      atom.confirm
        message: 'Package Cop: Error During Uninstall\n'
        detailedMessage: e.message
        buttons: ['OK']
      return false
    true
    
  openURL: ->
    url = @repoURL ? 'https://atom.io/packages/' + @name
    if atom.packages.isPackageLoaded 'web-browser'
      atom.workspace.open url
    else
      shell.openExternal url

  setOldVersion: -> @oldVersion = yes
  getOldVersion: -> @oldVersion
  
  getPackageId: -> @packageId
  getTitle:     -> @title
  getStates:    -> @states
  
  loaded:    -> (not @oldVersion and 
                (@name is 'Atom' or atom.packages.isPackageLoaded @name))
  activated: -> (not @oldVersion and 
                (@name is 'Atom' or atom.packages.isPackageActive @name))
  getState: -> @state = 
    if   @activated() then 'activated'
    else if @loaded() then 'loaded'
    else                   'unloaded'
  getStateIfChanged: ->
    prevState = @state
    if @getState() isnt prevState then @state
  
  saveState: -> @savedState = {state: @getState(), enabled: @getEnabled()}
  getSavedState: -> @savedState
  restoreState: -> 
    {state, enabled} = @savedState
    @enableDisable enabled
    if enabled then @enable() 
    else            @disable()
    @savedState
  
  getEnabled: -> 
    @enabled = (not @oldVersion and 
                not atom.packages.isPackageDisabled @name)
  getEnabledIfChanged: ->
    prevEnabled = @enabled
    if @getEnabled() isnt prevEnabled then @enabled
    
  enableDisable: (enable) ->
    if enable
      @load()
      @enable()
      @activate()
    else 
      @deactivate()
      @disable()
      @unload()
      
  fail: (e, action) ->
    console.log 'package-cop: package', @name, 'failed to', action + '.',
                 e.message + '. Please submit an issue to the package repo.'
  
  enable:     -> if not @oldVersion and @name isnt 'Atom' and not @getEnabled()
                  atom.packages.enablePackage @name
  disable:    -> if not @oldVersion and @name isnt 'Atom' and @getEnabled()
                  atom.packages.disablePackage @name
  load:       -> if not @oldVersion and @name isnt 'Atom' and not @loaded()
                  try
                    atom.packages.loadPackage @name
                  catch e
                    @fail e, 'load'
  unload:     -> if not @oldVersion and @name isnt 'Atom' and @loaded()
                  @deactivate()
                  try
                    atom.packages.unloadPackage @name
                  catch e
                    @fail e, 'unload'
  activate:   -> if not @oldVersion and @name isnt 'Atom'
                  setTimeout =>
                    if not @activated()
                      @load()
                      try
                        pack = atom.packages.getLoadedPackage @name
                        pack.activationDeferred ?= resolve:(->), reject:(->)
                        pack.activateNow()
                      catch e
                        @fail e, 'activate'
                  , 500
  deactivate: -> if not @oldVersion and @name isnt 'Atom' and @activated()
                  try
                    atom.packages.deactivatePackage @name
                  catch e
                    @fail e, 'deactivate'
  
  