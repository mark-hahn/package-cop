###
  lib/package-cop-item.coffee
###

{Emitter}   = require 'emissary'
PackageCopItemView = require './package-cop-item-view'

module.exports =
class PackageCopItem
  Emitter.includeInto @
  
  constructor: (@packageCop) ->
  
  getTestData: -> @packageCop.getTestData()
  putTestData: -> @packageCop.putTestData()
  
  getTitle:     -> 'Package Cop'
  getViewClass: -> PackageCopItemView
    