'use strict'

BaseCtrl = require 'scripts/BaseClasses/BaseController.coffee'

module.exports = class ChartsSidebarCtrl extends BaseCtrl
  @inject '$q',
    '$stateParams',
    'app_analysis_charts_dataTransform',
    'app_analysis_charts_list',
    'app_analysis_charts_sendData',
    'app_analysis_charts_checkTime',
    'app_analysis_charts_dataService'

  initialize: ->
    @dataService = @app_analysis_charts_dataService
    @dataTransform = @app_analysis_charts_dataTransform
    @list = @app_analysis_charts_list
    @sendData = @app_analysis_charts_sendData
    @checkTime = @app_analysis_charts_checkTime
    @DATA_TYPES = @dataService.getDataTypes()

    @chartData = null
    @headers = null

    # dataset-specific
    @dataFrame = null
    @dataType = null
    @cols = []
    @xCol = null
    @yCol = null
    @labelCol = null

    @selector1 = {}
    @selector2 = {}
    @selector3 = {}
    @selector4 = {}
    @stream = false

    @streamColors = [
      name: "blue"
      scheme: ["#045A8D", "#2B8CBE", "#74A9CF", "#A6BDDB", "#D0D1E6", "#F1EEF6"]
    ,
      name: "pink"
      scheme: ["#980043", "#DD1C77", "#DF65B0", "#C994C7", "#D4B9DA", "#F1EEF6"]
    ,
      name: "orange"
      scheme: ["#B30000", "#E34A33", "#FC8D59", "#FDBB84", "#FDD49E", "#FEF0D9"]
    ]

    @graphInfo =
      graph: ""
      x: 1
      y: 2
      z: 3

    @graphs = @list.getFlat()
    @graphSelect = {}
    @labelVar = false
    @labelCheck = null

    @dataService.getData().then (obj) =>
      if obj.dataFrame and obj.dataFrame.dataType?
        dataFrame = obj.dataFrame
        console.log obj.dataFrame
        console.log @numericalCols
        switch dataFrame.dataType
          when @DATA_TYPES.FLAT
            @graphs = @list.getFlat()
            @dataType = @DATA_TYPES.FLAT
            @headers = d3.entries dataFrame.header
            @chartData = @dataTransform.format dataFrame.data
            @parseData(dataFrame.data)
            if @checkTime.checkForTime @chartData
              @graphs = @list.getTime()
          when @DATA_TYPES.NESTED
            @graphs = @list.getNested()
            @data = dataFrame.data
            @dataType = @DATA_TYPES.NESTED
            @header = {key: 0, value: "initiate"}

  changeName: () ->
    @graphInfo.graph = @graphSelect.name

    if @graphSelect.name is "Stream Graph"
      @stream = true
    else
      @stream = false

    if @dataType is "NESTED"
      @graphInfo.x = "initiate"
      @sendData.createGraph @data, @graphInfo, {key: 0, value: "initiate"}, @dataType, @selector4.scheme
    else
      @sendData.createGraph @chartData, @graphInfo, @headers, @dataType, @selector4.scheme

  changeVar: (selector, headers, ind) ->
    console.log @selector4.scheme
    #if scope.graphInfo.graph is one of the time series ones, test variables for time format and only allow those when ind = x
    #only allow numerical ones for ind = y or z
    for h in headers
      if selector.value is h.value then @graphInfo[ind] = parseFloat h.key
    @sendData.createGraph(@chartData, @graphInfo, @headers, @dataType, @selector4.scheme)

  updateDataPoints: (data=null, means=null, labels=null) ->
    if data
      xCol = data.header.indexOf @xCol
      yCol = data.header.indexOf @yCol
      data = ([row[xCol], row[yCol]] for row in data.data)
    @msgService.broadcast 'charts:updateDataPoints',
      dataPoints: data
      means: means
      labels: labels

# update data-driven sidebar controls
  updateSidebarControls: (data) ->
    @cols = data.header
    @numericalCols = (col for col, idx in @cols when data.types[idx] in ['integer', 'number'])
    @categoricalCols = (col for col, idx in @cols when data.types[idx] in ['string', 'integer'])
#     console.log @numericalCols, @categoricalCols
    # make sure number of unique labels is less than maximum number of clusters for visualization
#    if @algParams.k
#      [minK, ..., maxK] = @algParams.k
#      colData = d3.transpose(data.data)
#      @categoricalCols = @categoricalCols.filter (x, i) =>
#        @uniqueVals(colData[i]).length > maxK
    [@xCol, @yCol, ..., lastCol] = @numericalCols
#    @clusterRunning = off
#    if @useLabels
#      @numUniqueLabels = @detectK data
    @$timeout =>
      @updateDataPoints data

  parseData: (data) ->
    @dataService.inferDataTypes data, (resp) =>
      if resp and resp.dataFrame
        console.log resp.dataFrame
        @updateSidebarControls(resp.dataFrame)
        @updateDataPoints(resp.dataFrame)
#        @ready = on
