
# lib/package-cop.coffee

PackageCopItem = require './package-cop-item'

module.exports =
  configDefaults:
    showHelpText: yes
    
  activate: -> 
    atom.workspaceView.command "package-cop:open", =>
      atom.workspace.activePane.activateItem new PackageCopItem

