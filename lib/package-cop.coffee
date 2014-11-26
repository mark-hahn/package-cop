
# lib/package-cop.coffee

PackageCopItem = require './package-cop-item'

module.exports =
  activate: -> 
    atom.workspaceView.command "package-cop:open", =>
      atom.workspace.activePane.activateItem new PackageCopItem

