"""
  lib/data-store.coffee
"""        

fs       = require 'fs'
pathUtil = require 'path'

Problem = require './problem'
Package = require './package'

module.exports =
class DataStore
  
  constructor: () ->
    home =
      if process.platform is 'win32' then process.env.USERPROFILE
      else process.env.HOME
    @dataPath = pathUtil.join(home, '.atom', '.package-cop.json')
    data = try
      JSON.parse fs.readFileSync @dataPath, 'utf8'
    catch e
      console.log 'package-cop: unable to load stored data (ok on first load)', e.message
      {problems: {}, packages: {}}
    
    @problems = data.problems
    for problemId, problemData of @problems
      @problems[problemId] = new Problem problemData
      
    @packages = data.packages
    for packageId, packageData of @packages
      @packages[packageId] = new Package packageData
    @packages = Package.removeUninstalled @packages
  
  getProblems: -> @problems
  getPackages: -> @packages
    
  saveDataStore: ->
    data = {@problems, packages: {}}
    for packageId, pkg of @packages
      data.packages[packageId] = pkg.trimPropertiesForSave()
    try
      fs.writeFileSync @dataPath, JSON.stringify data
    catch e
      atom.confirm 
        message: 'package-cop: error saving test data'
        detailedMessage: e.message
        buttons: ['OK']
  
    
  