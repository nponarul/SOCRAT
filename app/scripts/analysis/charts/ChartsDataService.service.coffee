'use strict'

BaseModuleDataService = require 'scripts/BaseClasses/BaseModuleDataService.coffee'

module.exports = class ChartsDataService extends BaseModuleDataService
  @inject '$q', 'app_analysis_charts_msgService'

  # requires renaming message service injection to @msgService
  initialize: () ->
    @msgManager = @app_analysis_charts_msgService
    @getDataRequest = @msgManager.getMsgList().outgoing[0]
    @getDataResponse = @msgManager.getMsgList().incoming[0]

  inferDataTypes: (data, cb) ->
    @post(@msgManager.getMsgList().outgoing[1], @msgManager.getMsgList().incoming[1], data).then (resp) =>
      cb resp

  getMean: (values, cb) ->
    @post(@msgManager.getMsgList().outgoing[3], @msgManager.getMsgList().incoming[3], values).then (resp) =>
      cb resp


  #code below from Selvam's implementation in getData
  getSummary: (data) ->
    @post(@msgManager.getMsgList().outgoing[2], @msgManager.getMsgList().incoming[2], data)
