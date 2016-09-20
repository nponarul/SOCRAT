'use strict'

BaseModuleDataService = require 'scripts/BaseClasses/BaseModuleDataService.coffee'

module.exports = class GraphData extends BaseModuleDataService
  @inject 'app_analysis_charts_msgService',
    'app_analysis_charts_scatterPlot'
    'app_analysis_charts_bubbleChart'
    '$interval'

  initialize: ->
    @msgManager = @app_analysis_charts_msgService
    @scatterplot = @app_analysis_charts_scatterPlot
    @bubblechart = @app_analysis_charts_bubbleChart

    @charts = [@bubblechart, @scatterplot]

  getNames: -> @algorithms.map (alg) -> alg.getName()


  getDataTypes: ->
      @msgService.getSupportedDataTypes()
