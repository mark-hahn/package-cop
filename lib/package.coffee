"""
  li./package.coffee
  
  There is a different one of these for each pkg version
"""        

shell      = require 'shell'
{execSync} = require 'child_process'
Problem    = require './problem'

module.exports = 
class Package
  
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
    packagesOut = {}
    allNames = atom.packages.getAvailablePackageNames().concat 'Atom'
    for id, pkg of packages when pkg.name in allNames
      packagesOut[id] = pkg
    packagesOut
    
  constructor: (@name, @version) ->
    if typeof @name is 'object'
      {@name, @version, @repoURL, @states} = @name
    else
      @states = {}
    @packageId = Package.packageIdFromNameVersion @name, @version
    @title     = Package.titleizeName @name
  
  addVersionToTitle: -> 
    if not @titleHasVersion
      @title += ' (' + @version + ')'
      @titleHasVersion = yes
      
  trimPropertiesForSave: -> {@name, @version, @repoURL, @states}
      
  uninstall: ->
    if @name is 'Atom' then return
    uninstall = atom.confirm
      message: 'Package Cop: Confirm Uninstall\n'
      detailedMessage: 'Are you sure you want to uninstall the pkg ' + @name +
          '? The pkg will be removed along with all package-cop test results.'
      buttons: ['Cancel', 'Uninstall']
    if uninstall is 0 then return false
    try
      console.log execSync 'apm uninstall ' + @name, encoding: 'utf8'
    catch e
      atom.confirm
        message: 'Package Cop: Error During Uninstall\n'
        detailedMessage: e.message
        buttons: ['OK']
      return false
    true
    
  openURL: ->
    url = @repoURL ? 'https://atom.io/packages/' + @name
    if atom.webBrowser
      atom.webBrowser.createPage url
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
  
  getEnabled: -> 
    @enabled = (not @oldVersion and 
                not atom.packages.isPackageDisabled @name)
  getEnabledIfChanged: ->
    prevEnabled = @enabled
    if @getEnabled() isnt prevEnabled then @enabled
    
  enable:     -> if not @oldVersion then atom.packages.enablePackage     @name
  disable:    -> if not @oldVersion then atom.packages.disablePackage    @name
  load:       -> if not @oldVersion then atom.packages.loadPackage       @name
  unload:     -> if not @oldVersion then atom.packages.unloadPackage     @name
  activate:   -> if not @oldVersion then atom.packages.activatePackage   @name
  deactivate: -> if not @oldVersion then atom.packages.deactivatePackage @name
  
