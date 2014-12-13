"""
  lib/data-store.coffee
"""        

fs       = require 'fs'
pathUtil = require 'path'

Problem = require './problem'
Package = require './package'

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
    data = try
      JSON.parse fs.readFileSync dataPath, 'utf8'
    catch e
      if not firstLoad
        console.log 'package-cop: unable to load stored data', e.message
      {problems: {}, packages: {}}
      
    @problems = data.problems
    for problemId, problemData of @problems
      @problems[problemId] = new Problem problemData
      
    @packages = data.packages
    for packageId, packageData of @packages
      @packages[packageId] = new Package packageData
    @packages = Package.removeUninstalled @packages
    
    @reloadActivateFlag          = data.reloadActivateFlag
    @reloadedFromThisPackageFlag = data.reloadedFromThisPackageFlag
  
  getProblems: -> @problems
  getPackages: -> @packages
  
  setReloadActivateFlag: (val) -> 
    @reloadActivateFlag = val
    @saveDataStore()
    
  setReloadedFromThisPackageFlag: (val) ->
    @reloadedFromThisPackageFlag = val
    @saveDataStore()
    
  saveDataStore: ->
    data = {@problems, packages: {}, \
            @reloadActivateFlag, @reloadedFromThisPackageFlag}
    for packageId, pkg of @packages
      data.packages[packageId] = pkg.trimPropertiesForSave()
    try
      fs.writeFileSync dataPath, JSON.stringify data
    catch e
      atom.confirm 
        message: 'package-cop: error saving test data'
        detailedMessage: e.message
        buttons: ['OK']
  
    
  