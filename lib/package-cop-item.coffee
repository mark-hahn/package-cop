###
  lib/package-cop-item.coffee
###

{Emitter} = require 'emissary'
PackageCopItemView = require './package-cop-item-view'

module.exports =
class PackageCopItem
  Emitter.includeInto @
  
  constructor: (@packageCop) ->
  
  getProblems:   -> @packageCop.getProblems()
  getPackages:   -> @packageCop.getPackages()
  saveDataStore: -> @packageCop.saveDataStore()
  setReloadActivateFlag: (val) -> 
    @packageCop.setReloadActivateFlag val
  setReloadedFromThisPackageFlag: (val) -> 
    @packageCop.setReloadedFromThisPackageFlag val
  
  getTitle:     -> 'Package Cop'
  getViewClass: -> PackageCopItemView
    