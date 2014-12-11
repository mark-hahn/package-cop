
# lib/package-cop.coffee

fs = require 'fs'

PackageCopItem = require './package-cop-item'
DataStore      = require './data-store'

module.exports =
    
  configDefaults:
    showHelpText: yes
    
  activate: -> 
    @dataStore = new DataStore
    
    atom.workspaceView.command "package-cop:open", =>
      @dataStore.reload()
      workspace  = atom.workspace
      for pane in workspace.getPanes()
        for item in pane.getItems()
          if item instanceof PackageCopItem 
            pane.destroyItem item
      @packageCopItem = new PackageCopItem @
      workspace.activePane.activateItem @packageCopItem
      
      # setTimeout =>
      #   debugger
      #   atom.packages.activatePackage 'find-selection'
      # , 3000

  getProblems:   -> @dataStore.getProblems()
  getPackages:   -> @dataStore.getPackages()
  saveDataStore: -> @dataStore.saveDataStore()

  deactivate: ->
    @packageCopItem.destroy()
    
