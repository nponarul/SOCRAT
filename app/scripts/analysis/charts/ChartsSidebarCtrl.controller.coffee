'use strict'

BaseCtrl = require 'scripts/BaseClasses/BaseController.coffee'

module.exports = class ChartsSidebarCtrl extends BaseCtrl
  @inject '$q',
    '$stateParams',
    'app_analysis_charts_dataTransform',
    'app_analysis_charts_list',
    'app_analysis_charts_sendData',
    'app_analysis_charts_checkTime',
    'app_analysis_charts_dataService',
    'app_analysis_charts_msgService',
    'app_analysis_charts_chartsStats',
    '$timeout'

  initialize: ->
    @msgService = @app_analysis_charts_msgService
    @dataService = @app_analysis_charts_dataService
    @dataTransform = @app_analysis_charts_dataTransform
    @list = @app_analysis_charts_list
    @sendData = @app_analysis_charts_sendData
    @checkTime = @app_analysis_charts_checkTime
    @DATA_TYPES = @dataService.getDataTypes()
    @graphs = []
    @selectedGraph = null
    @chartStats = @app_analysis_charts_chartsStats

    # dataset-specific
    @dataFrame = null
    @dataType = null
    @cols = []
    @chosenCols = []
    @numericalCols = []
    @categoricalCols = []
    @xCol = null
    @yCol = null
    @zCol = null

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

    @dataService.getData().then (obj) =>
      if obj.dataFrame and obj.dataFrame.dataType?
        dataFrame = obj.dataFrame
        switch dataFrame.dataType
          when @DATA_TYPES.FLAT
            @graphs = @list.getFlat()
            @selectedGraph = @graphs[0]
            @dataType = @DATA_TYPES.FLAT
            @parseData dataFrame
            @statsData dataFrame
#            @chartData = @dataTransform.format dataFrame.data
            if @checkTime.checkForTime dataFrame.data
              @graphs = @list.getTime()
          when @DATA_TYPES.NESTED
            @graphs = @list.getNested()
            @data = dataFrame.data
            @dataType = @DATA_TYPES.NESTED
            @header = {key: 0, value: "initiate"}

  statsData: (dataFrame) ->
    d = @dataTransform.transpose dataFrame.data
    stats = []
    for i in d
      obj = {}
      obj.mean = @chartStats.getMean(i)
      obj.median = @chartStats.getMedian(i)
      obj.stdev = @chartStats.getStDev(i)
      obj.count = @chartStats.getCount(i)
      stats.push obj
    console.log stats

    #code below from Selvam's implementation in getData
    formattedData = dataFrame.data.map (entry)->
      obj = {}
      dataFrame.header.forEach (h,key)->
        # stats.js lib for a key "indicator.id" checks obj["indicator"]["id"]
        # to fix that, replacing all "." with "_"
        obj[h.replace('.','_')] = entry[key]
      obj

    newDataFrame = Object.assign {}, dataFrame, {data:formattedData}

    @dataService.getSummary newDataFrame, (resp) =>
      if resp? and resp.dataFrame? and resp.dataFrame.data?
        console.log resp.dataFrame.data #nothing in console for this

    # This does not work
#    @dataService.getMean d[0], (resp) =>
#      if resp? and resp.dataFrame? and resp.dataFrame.data?
#        console.log resp.dataFrame.data

  parseData: (data) ->
    df = data
    @dataService.inferDataTypes data, (resp) =>
      if resp? and resp.dataFrame? and resp.dataFrame.data?
        # update data types with inferred
        for type, idx in df.types
          df.types[idx] = resp.dataFrame.data[idx]
        @dataFrame = df
        @updateSidebarControls(df)
        @updateDataPoints(df)

  updateSidebarControls: (data=@dataFrame) ->
    @cols = data.header
    if @selectedGraph.x
      @xCols = (col for col, idx in @cols when data.types[idx] in @selectedGraph.x)
      @xCol = @xCols[0]
    if @selectedGraph.y
      @yCols = (col for col, idx in @cols when data.types[idx] in @selectedGraph.y)
      for yCol in @yCols
        if yCol isnt @xCol
          @yCol = yCol
          break
    if @selectedGraph.z
      @zCols = (col for col, idx in @cols when data.types[idx] in @selectedGraph.z)
      for zCol in @zCols
        if zCol not in [@xCol, @yCol]
          @zCol = zCol
          break
    @$timeout =>
      @updateDataPoints()

  updateDataPoints: (data=@dataFrame) ->
    [xCol, yCol, zCol] = [@xCol, @yCol, @zCol].map (x) -> data.header.indexOf x
    [xType, yType, zType] = [xCol, yCol, zCol].map (x) -> data.types[x]
    data = ([row[xCol], row[yCol], row[zCol]] for row in data.data)
    @msgService.broadcast 'charts:updateGraph',
      dataPoints: data
      graph: @selectedGraph
      labels:
        xLab:
          value: @xCol
          type: xType
        yLab:
          value: @yCol
          type: yType
        zLab:
          value: @zCol
          type: zType

#  changeGraph: () ->
#    if @graphSelect.name is "Stream Graph"
#      @stream = true
#    else
#      @stream = false

#    if @dataType is "NESTED"
#      @graphInfo.x = "initiate"
#      @sendData.createGraph @data, @graphInfo, {key: 0, value: "initiate"}, @dataType, @selector4.scheme
#    else
#      @sendData.createGraph @chartData, @graphInfo, @headers, @dataType, @selector4.scheme

#  changeVar: (selector, headers, ind) ->
#    console.log @selector4.scheme
    #if scope.graphInfo.graph is one of the time series ones, test variables for time format and only allow those when ind = x
    #only allow numerical ones for ind = y or z
#    for h in headers
#      if selector.value is h.value then @graphInfo[ind] = parseFloat h.key
#    @sendData.createGraph(@chartData, @graphInfo, @headers, @dataType, @selector4.scheme)


