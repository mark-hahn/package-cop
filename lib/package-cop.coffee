
# lib/package-cop.coffee

fs = require 'fs'

PackageCopItem = require './package-cop-item'
DataStore      = require './data-store'

module.exports =
    
  activate: -> 
    @dataStore = new DataStore

    atom.packages.onDidActivateAll =>
      console.log 'onDidActivateAll'
      @dataStore.chkReloadActivateFlag()
    
    if @dataStore.chkReloadedFromThisPackage() 
      setTimeout (=>@openItem()), 100
      
    atom.workspaceView.command 'package-cop:open', => @openItem()
      
  openItem: ->
      @dataStore.reload yes
      workspace = atom.workspace
      for pane in workspace.getPanes()
        for item in pane.getItems()
          if item instanceof PackageCopItem 
            pane.destroyItem item
      @packageCopItem = new PackageCopItem @
      workspace.activePane.activateItem @packageCopItem
      
  getProblems:   -> @dataStore.getProblems()
  getPackages:   -> @dataStore.getPackages()
  saveDataStore: -> @dataStore.saveDataStore()
  setReloadActivateFlag: (val) -> 
    @dataStore.setReloadActivateFlag val
  setReloadedFromThisPackageFlag: (val) -> 
    @dataStore.setReloadedFromThisPackageFlag val

  deactivate: ->
    @packageCopItem.destroy()
    
