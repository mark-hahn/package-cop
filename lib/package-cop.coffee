
# lib/package-cop.coffee

PackageCopItem = require './package-cop-item'

module.exports =
  configDefaults:
    showHelpText: yes
    
  activate: -> 
    atom.workspaceView.command "package-cop:open", =>
      packageCopItem = new PackageCopItem
      atom.workspace.activePane.activateItem packageCopItem

  # deactivate: ->
  #   PackageCopItem.destroyAll()
  #   