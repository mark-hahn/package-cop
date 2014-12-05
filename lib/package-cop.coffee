
# lib/package-cop.coffee

fs = require 'fs'

PackageCopItem = require './package-cop-item'
PackageVersion = require './package-version'

module.exports =
    
  configDefaults:
    showHelpText: yes
    
  activate: -> 
    @testDataPath = atom.packages.resolvePackagePath('package-cop') + '/.test-data.json'
    @getTestData()
    atom.workspaceView.command "package-cop:open", =>
      workspace  = atom.workspace
      for pane in workspace.getPanes()
        for item in pane.getItems()
          if item instanceof PackageCopItem 
            pane.destroyItem item
      @packageCopItem = new PackageCopItem @
      workspace.activePane.activateItem @packageCopItem

  getTestData: ->
    @testData ?= try
      PackageVersion.deserialize fs.readFileSync @testDataPath, 'utf8'
    catch e
      console.log 'package-cop: unable to load test data (ok on first load)', e.message
      {}
  
  putTestData: ->
    try
      fs.writeFileSync @testDataPath, PackageVersion.serialize @testData
    catch e
      atom.confirm 
        message: 'package-cop: error saving test data'
        detailedMessage: e.message
        buttons: ['OK']

  deactivate: ->
    @packageCopItem.destroy()
    
