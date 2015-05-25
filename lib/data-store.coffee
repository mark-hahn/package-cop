"""
  lib/data-store.coffee
"""        

fs       = require 'fs'
pathUtil = require 'path'

Problem = require './problem'
Package = require './package'
_       = require 'underscore'

home =
  if process.platform is 'win32' then process.env.USERPROFILE
  else process.env.HOME
dataPath = pathUtil.join(home, '.atom', '.package-cop.json')

module.exports =
class DataStore
  
  constructor: () -> 
    
  chkReloadActivateFlag: ->
    @reload()
    if @reloadActivateFlag
      Package.activateAllLoaded()
      delete @reloadActivateFlag
      @saveDataStore()
      
  chkReloadedFromThisPackage: ->
    @reload()
    if (res = @reloadedFromThisPackageFlag)
      delete @reloadedFromThisPackageFlag
      @saveDataStore()
    res
    
  reload: (firstLoad) ->
    # console.log 'start reload'
    
    data = try
      JSON.parse fs.readFileSync dataPath, 'utf8'
    catch e
      if not firstLoad
        console.log 'package-cop: unable to load stored data', e.message
      {problems: {}, packages: {}}
    
    @problems ?= {}
    for problemId, problemData of data.problems
      @problems[problemId] = new Problem problemData
      
    @packages ?= {}
    for packageId, packageData of data.packages
      @packages[packageId] = new Package packageData
    Package.removeUninstalled @packages
    
    @reloadActivateFlag          = data.reloadActivateFlag
    @reloadedFromThisPackageFlag = data.reloadedFromThisPackageFlag
    @hideHelpFlag                = data.hideHelpFlag
    @saveDataStore()
    
    # console.log 'end reload'
  
  getProblems: ->
    @problems
    
  getPackages: -> @packages
  
  getHideHelpFlag: -> @reload(); @hideHelpFlag
    
  setHideHelpFlag: (val) -> 
    @hideHelpFlag = val
    @saveDataStore()
  
  setReloadActivateFlag: (val) -> 
    @reloadActivateFlag = val
    @saveDataStore()
    
  setReloadedFromThisPackageFlag: (val) ->
    @reloadedFromThisPackageFlag = val
    @saveDataStore()
    
  saveDataStore: ->
    data = {
      @problems
      packages: {}
      @reloadActivateFlag
      @reloadedFromThisPackageFlag
      @hideHelpFlag
    }
    for packageId, pkg of @packages
      data.packages[packageId] = pkg.trimPropertiesForSave()
    try
      fs.writeFileSync dataPath, JSON.stringify data
    catch e
      atom.confirm 
        message: 'package-cop: error saving data'
        detailedMessage: e.message
        buttons: ['OK']
    
