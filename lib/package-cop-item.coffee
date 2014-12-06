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
  
  getTitle:     -> 'Package Cop'
  getViewClass: -> PackageCopItemView
    