
# lib/package-cop.coffee

fs             = require 'fs'
SubAtom        = require 'sub-atom'
PackageCopItem = require './package-cop-item'
DataStore      = require './data-store'

module.exports =
    
  activate: -> 
    # console.log 'activate p cop'
    
    @subs      = new SubAtom
    @dataStore = new DataStore

    @subs.add atom.packages.onDidActivateInitialPackages =>
      @dataStore.chkReloadActivateFlag()
    
    if @dataStore.chkReloadedFromThisPackage() 
      setTimeout (=>@openItem()), 100
      
    @subs.add atom.commands.add 'atom-workspace', 'package-cop:open': => @openItem()
    
  openItem: ->
      @dataStore.reload yes
      workspace = atom.workspace
      for pane in workspace.getPanes()
        for item in pane.getItems()
          if item instanceof PackageCopItem 
            pane.destroyItem item
      @packageCopItem = new PackageCopItem @
      workspace.getActivePane().activateItem @packageCopItem
      
  getProblems:   -> @dataStore.getProblems()
  getPackages:   -> @dataStore.getPackages()
  saveDataStore: -> @dataStore.saveDataStore()
  
  setReloadActivateFlag: (val) -> 
    @dataStore.setReloadActivateFlag val
  setReloadedFromThisPackageFlag: (val) -> 
    @dataStore.setReloadedFromThisPackageFlag val
  setHideHelpFlag: (val) -> 
    @dataStore.setHideHelpFlag val
  getHideHelpFlag: -> 
    @dataStore.getHideHelpFlag()

  deactivate: ->
    @packageCopItem?.destroy()
    @subs.dispose()
    
