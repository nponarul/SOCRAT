'use strict'

charts = angular.module('app_analysis_charts', [])

.factory('app_analysis_charts_constructor', [
  'app_analysis_charts_manager'
  (manager)->
    (sb)->

      manager.setSb sb unless !sb?
      _msgList = manager.getMsgList()

      init: (opt) ->
        console.log 'charts init called'

      destroy: () ->

      msgList: _msgList
])

.factory( 'app_analysis_charts_manager', [
  ()->
    _sb = null

    _msgList =
      outgoing: ['get table']
      incoming: ['take table']
      scope: ['charts']

    _setSb = (sb) ->
      _sb = sb

    _getSb = () ->
      _sb

    _getMsgList = () ->
      _msgList

    getSb: _getSb
    setSb: _setSb
    getMsgList: _getMsgList
])

.controller('mainchartsCtrl', [
  'app_analysis_charts_manager'
  '$scope'
  'showGraph'
  (ctrlMngr,$scope, showGraph) ->
    console.log 'mainchartsCtrl executed'
    _chart_data = null
    try
      _showGraph = new showGraph(['barchart',
      'bubblechart',
      'histogram',
      'piechart'
      'scatterplot'], $scope)
    catch e
      console.log e.message

    _updateData = () ->
      $scope.chartData = _chart_data

    $scope.tabs = []
    $scope.$on 'charts:graphDiv', (event, data) ->
      _chart_data = data
      _showGraph.set _chart_data.name
      console.log data
      $scope.tabs.push {
        name: _chart_data.name
        id: _chart_data.name.substr(0,2).toLowerCase()
      }
      console.log $scope.tabs
      _updateData()
])


# Helps sidebar accordion to keep in sync with the main div.
.factory('showGraph', ->
  (obj, scope) ->
    if arguments.length is 0
#return false if no arguments are provided
      return false
    _obj = obj

    # create a showGraph variable and attach it to supplied scope
    scope.showGraph = []
    for i in obj
      scope.showGraph[i] = true

    # index is the array key.
    set: (graphType) ->
      switch graphType
        when 'Bar Chart'
          key = 'barchart'
        when 'Bubble Chart'
          key = 'bubblechart'
        when 'Histogram'
          key = 'histogram'
        when 'Pie Chart'
          key = 'piechart'
        when 'Scatter Plot'
          key = 'scatterplot'
      if scope.showGraph[key]?
        for i in _obj
          if i is key
            scope.showGraph[i] = false
          else
            scope.showGraph[i] = true
)

.directive('myTabs', () ->
  return {
  replace: false,
  transclude: true,
  template: '<li><a data-toggle = "tab" href="{{t as t.name for t in tabs}}">{{t as t.name for t in tabs}}</a></li>'
  }
)
.directive('tabBody', () ->
  return {
  template: '<div id="{{t as t.name for t in tabs}}" class = "tab-pane fade" ><svg style="width:500px, height:500px"></svg></div>'
  }
)

.controller('sidechartsCtrl',[
  'app_analysis_charts_manager'
  '$scope'
  '$rootScope'
  '$stateParams'
  '$q'
  'app_analysis_charts_dataTransform'
  (ctrlMngr, $scope, $rootScope, $stateParams, $q, dataTransform) ->
    console.log 'sidechartsCtrl executed'
    _chartData = null
    _headers = null
    #_graphInfo = null
    $scope.selector1={};
    $scope.selector2={};
    $scope.graphInfo = {graph:"", x:"", y:""}
    $scope.graphs = [{name:'Bar Graph', value:0},{name:'Scatter Plot', value:1},{name:'Histogram', value:2},{name:'Bubble Chart', value:3},{name:'Pie Chart', value:4}]
    $scope.graphSelect = {}

    $scope.change = (selector,headers, ind) ->
      for h in headers
        if selector.value is h.value then $scope.graphInfo[ind] = parseFloat h.key

    $scope.createGraph = (results) ->
      results = {
        xVar: _chartData[$scope.graphInfo.x]
        xLab: _headers[$scope.graphInfo.x]
        yVar: _chartData[$scope.graphInfo.y]
        yLab: _headers[$scope.graphInfo.y]
        name: $scope.graphInfo.graph
      }
      #_graphInfo = results
      #[_chartData[$scope.graphInfo.x], _chartData[$scope.graphInfo.y]]
      $rootScope.$broadcast 'charts:graphDiv', results

    $scope.change1 = ()->
      $scope.graphInfo.graph = $scope.graphSelect.name


    sb = ctrlMngr.getSb()

    # deferred = $q.defer()

    token = sb.subscribe
      msg:'take table'
      msgScope:['charts']
      listener: (msg, _data) ->
        _headers = d3.entries _data.header
        $scope.headers = _headers
        _chartData = dataTransform.format(_data.data)

    sb.publish
      msg:'get table'
      msgScope:['charts']
      callback: -> sb.unsubscribe token
      data:
        tableName: $stateParams.projectId + ':' + $stateParams.forkId


])

.factory('app_analysis_charts_dataTransform',[
  () ->

    _transpose = (data) ->
      data[0].map (col, i) -> data.map (row) -> row[i]

    _transform = (data) ->
      for col in data
        obj = {}
        for value, i in col
          obj[i] = value
        d3.entries obj

    _format = (data) ->
      return _transform(_transpose(data))

    transform: _transform
    transpose:_transpose
    format: _format

])





.directive('bubblechart', [
  '$window'
  '$rootScope'
  ($window, $rootScope) ->
    restrict: 'EA'
    transclude: true
    template: "<div class='graph-container' width='100%' height='600'></div>"

    replace: true #replace the directive element with the output of the template.

# actual d3 graph
    link: (scope, element, attr)->
      margin = {top: 10, right: 30, bottom: 30, left: 30}
      width = 960 - margin.left - margin.right
      height = 500 - margin.top - margin.bottom

      # Listen to the changing in x, y variable
      scope.$watch 'chartData', (newChartData) ->
      #$rootScope.$on  'update X Y variable', (obj,xIndex, yIndex)->
        if newChartData
          d3.select(element[0]).selectAll('*').remove()
          x = d3.scale.linear().range([ 0, width ])
          y = d3.scale.linear().range([ height, 0 ])
          r = d3.scale.linear().range([0,5])
          xAxis = d3.svg.axis().scale(x).orient('bottom')
          yAxis = d3.svg.axis().scale(y).orient('left')

          # Create SVG element
          svg = d3.select(element[0])
          .append("svg")
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

          #scope.x = $rootScope.dataT2[xIndex]
          #scope.xLabel =scope.x[0].value
          #scope.y = $rootScope.dataT2[yIndex]
          #scope.yLabel = scope.y[0].value

          scope.x1 = scope.chartData.xVar
          scope.xLabel1 = scope.chartData.xLab
          scope.y1 = scope.chartData.yVar
          scope.yLabel1 = scope.chartData.yLab

          #console.log xIndex
          #console.log yIndex
          #console.log $rootScope.dataT2

          #construct scope.data, will be used in svg.data()
          scope.data = []
          i=1
          while i < scope.x1.length
            tmp = {}
            tmp = JSON.stringify({x: scope.x1[i].value , y:scope.y1[i].value})
            scope.data.push(JSON.parse(tmp))
            i++
          #console.log scope.data

          x.domain([d3.min(scope.data, (d)->d.x), d3.max(scope.data, (d)->d.x)])
          y.domain([d3.min(scope.data, (d)->d.x), d3.max(scope.data, (d)->d.y)])
          r.domain([0, d3.max(scope.data, (d)->d.y)])

          # x axis
          svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate(0," + height + ")")
          .call xAxis
          .append('text')
          .attr('class', 'label')
          .attr('x', width)
          .attr('y', -6)
          .style('text-anchor', 'end')
          .text scope.xLabel

          # y axis
          svg.append("g")
          .attr("class", "y axis")
          .call(yAxis)
          .append("text")
          .attr('class', 'label')
          .attr("transform", "rotate(-90)")
          .attr("y", 6)
          .attr("dy", ".71em")
          .style("text-anchor", "end")
          .text scope.yLabel

          # add the tooltip area to the webpage
          tooltip = d3.select(element[0])
          .append('div')
          .attr('class', 'tooltip')
          .style('opacity', 0)

          # create circle
          svg.selectAll('.circle')
          .data(scope.data)
          .enter().append('circle')
          .attr('fill', 'yellow')
          .attr('opacity', '0.7')
          .attr('stroke', 'orange')
          .attr('stroke-width', '2px')
          .attr('cx', (d)->x d.x)
          .attr('cy', (d)->y d.y)
          .attr('r', (d)-> Math.sqrt(Math.abs(height - d.y)/10))



        console.log 'bubble directive linked'
])


.directive('scatterplot', [
  () ->
    restrict: 'EA'
    transclude: true
    template: "<div class='graph-container' height ='600' width = '100%'></div>"

    replace: true #replace the directive element with the output of the template.

# actual d3 graph
    link: (scope, element, attr)->
      margin = {top: 10, right: 30, bottom: 30, left: 30}
      width = 960 - margin.left - margin.right
      height = 500 - margin.top - margin.bottom

      # Listen to the changing in x, y variable
      scope.$watch 'chartData', (newChartData) ->
#$rootScope.$on  'update X Y variable', (obj,xIndex, yIndex)->
        if newChartData
          d3.select(element[0]).selectAll('*').remove()
          x = d3.scale.linear().range([ 0, width ])
          y = d3.scale.linear().range([ height, 0 ])
          xAxis = d3.svg.axis().scale(x).orient('bottom')
          yAxis = d3.svg.axis().scale(y).orient('left')

          # Create SVG element
          svg = d3.select(element[0])
          .append("svg")
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
          .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

          #scope.x = $rootScope.dataT2[xIndex]
          #scope.xLabel =scope.x[0].value
          #scope.y = $rootScope.dataT2[yIndex]
          #scope.yLabel = scope.y[0].value

          scope.x1 = scope.chartData.xVar
          scope.xLabel1 = scope.chartData.xLab
          scope.y1 = scope.chartData.yVar
          scope.yLabel1 = scope.chartData.yLab

          #console.log xIndex
          #console.log yIndex
          #console.log $rootScope.dataT2

          #construct scope.data, will be used in svg.data()
          scope.data = []
          i=1
          while i < scope.x1.length
            tmp = {}
            tmp = JSON.stringify({x: scope.x1[i].value , y:scope.y1[i].value})
            scope.data.push(JSON.parse(tmp))
            i++


          console.log scope.data

          x.domain([d3.min(scope.data, (d)->d.x), d3.max(scope.data, (d)->d.x)])
          y.domain([d3.min(scope.data, (d)->d.x), d3.max(scope.data, (d)->d.y)])

          # values
          xValue = (d)->d.x
          yValue = (d)->d.y

          # map dot coordination
          xMap = (d)-> x xValue(d)
          yMap = (d)-> y yValue(d)

          # set up fill color
          cValue = (d)-> d.y
          color = d3.scale.category10()

          # x axis
          svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate(0," + height + ")")
          .call xAxis
          .append('text')
          .attr('class', 'label')
          .attr('x', width)
          .attr('y', -6)
          .style('text-anchor', 'end')
          .text scope.xLabel1

          # y axis
          svg.append("g")
          .attr("class", "y axis")
          .call(yAxis)
          .append("text")
          .attr('class', 'label')
          .attr("transform", "rotate(-90)")
          .attr("y", 6)
          .attr("dy", ".71em")
          .style("text-anchor", "end")
          .text scope.yLabel1

          # add the tooltip area to the webpage
          tooltip = d3.select(element[0])
          .append('div')
          .attr('class', 'tooltip')
          .style('opacity', 0)

          # draw dots
          svg.selectAll('.dot')
          .data(scope.data)
          .enter().append('circle')
          .attr('class', 'dot')
          .attr('r', 5)
          .attr('cx', xMap)
          .attr('cy', yMap)
          .style('fill', (d)->color cValue(d))
          .on('mouseover', (d)->
            tooltip.transition().duration(200).style('opacity', .9)
            tooltip.html('<br/>(' + xValue(d)+ ',' + yValue(d) + ')')
            .style('left', d3.select(this).attr('cx') + 'px').style('top', d3.select(this).attr('cy') + 'px'))
          .on('mouseout', (d)->
            tooltip.transition().duration(500).style('opacity', 0))

          # draw legend
          legend = svg.selectAll('.legend')
          .data(color.domain())
          .enter().append('g')
          .attr('class', 'legend')
          .attr('transform', (d, i)-> 'translate(0,' + i * 20 + ')')
          #.text scope.yLabel1

          # draw legend colored rectangles
          legend.append('rect')
          .attr('x', width - 18)
          .attr('width', 18)
          .attr('height', 18)
          .style('fill', color)

          # draw legend text
          legend.append('text')#
          .attr('x', width - 24)
          .attr('y', 9)
          .attr('dy', '.35em')
          .style('text-anchor', 'end')
          .text((d)-> d)

      console.log 'scatter plot directive linked'
])


.directive 'd3Charts', [
  () ->
    restrict:'E'
    template:"<svg width='100%' height='600'></svg>"
    link: (scope, elem, attr) ->
      margin = {top: 10, right: 30, bottom: 30, left: 30}
      width = 960 - margin.left - margin.right
      height = 500 - margin.top - margin.bottom
      x = null
      y = null
      xMax = null
      yMax = null
      xMin = null
      yMin = null
      xAxis = null
      yAxis = null
      svg = null
      data = null
      _graph = null
      pairedData = null
      pieData = null

      makePairs = (data) ->
        pairedData = []
        i=1
        while i < data.xVar.length
          tmp = {}
          tmp = JSON.stringify({x: data.xVar[i].value , y:data.yVar[i].value})
          pairedData.push(JSON.parse(tmp))
          i++

      getMax = (data) ->
        max = data[0].value
        for d in data
          val = parseFloat d.value
          if val > max
            max = val
        console.log max
        return max

      getMin = (data) ->
        min = data[0].value
        for d in data
          val = parseFloat d.value
          if val < min
            min = val
        console.log min
        return min

      makepieData = (xVar) ->
        pieMax = getMax(xVar)
        pieMin = getMin(xVar)
        a = 0
        b = 0
        c = 0
        d = 0
        e = 0
        f = 0
        g = 0
        rangeInt = (pieMax - pieMin)/7
        console.log pieMin+rangeInt
        for da in xVar
          val = parseFloat da.value
          console.log val, pieMin+rangeInt
          if val < (pieMin+rangeInt)
            a++
            console.log a
          else if (pieMin+rangeInt) <= val < (pieMin+2*rangeInt)
            b++
            console.log b
          else if (pieMin+2*rangeInt) <= val < (pieMin+3*rangeInt)
            c++
          else if (pieMin+3*rangeInt) <= val < (pieMin+4*rangeInt)
            d++
          else if (pieMin+4*rangeInt) <= val < (pieMin+5*rangeInt)
            e++
          else if (pieMin+5*rangeInt) <= val < (pieMin+6*rangeInt)
            f++
          else if (pieMin+6*rangeInt) <= val < (pieMin+7*rangeInt)
            g++
#          switch val
#            when val < (pieMin+rangeInt) then a++
#            when val >= (pieMin+rangeInt) and val < (pieMin+2*rangeInt) then b++
#            when val >= (pieMin+2*rangeInt) and val < (pieMin+3*rangeInt) then c++
#            when val >= (pieMin+3*rangeInt) and val < (pieMin+4*rangeInt) then d++
#            when val >= (pieMin+4*rangeInt) and val < (pieMin+5*rangeInt) then e++
#            when val >= (pieMin+5*rangeInt) and val < (pieMin+6*rangeInt) then f++
#            when val >= (pieMin+6*rangeInt) and val < (pieMin+7*rangeInt) then g++
        obj = {"first":a, "second":b, "third":c, "fourth":d, "fifth":e, "sixth":f, "seventh":g}
        pieData = d3.entries obj
        console.log pieData
        return pieData

      _drawBar = () ->

        x = d3.scale.linear().range([ 0, width ])
        y = d3.scale.linear().range([ height, 0 ])
        xAxis = d3.svg.axis().scale(x).orient('bottom')
        yAxis = d3.svg.axis().scale(y).orient('left')
        x.domain([d3.min(pairedData, (d)->d.x), d3.max(pairedData, (d)->d.x)])
        y.domain([d3.min(pairedData, (d)->d.x), d3.max(pairedData, (d)->d.y)])

        _graph.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call xAxis
        .append('text')
        .attr('class', 'label')
        .attr('x', width)
        .attr('y', 30)
        .style('text-anchor', 'end')
        .text data.xLab

        _graph.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text data.yLab

        # create bar elements
        _graph.selectAll('rect')
        .data(pairedData)
        .enter().append('rect')
        .attr('class', 'bar')
        .attr('x',(d)-> x d.x  )
        .attr('width', 30)
        .attr('y', (d)-> y d.y )
        .attr('height', (d)-> (height - y d.y) )
        .attr('fill', 'steelblue')

      _drawHist = () ->
        #values = d3.range(1000).map(d3.random.bates(10))
        #console.log values
        arr = []
        for d in data.xVar
          arr.push parseFloat d.value
        console.log arr

        y = d3.scale.linear().domain([0,yMax]).range([height, 0])
        x = d3.scale.linear().domain([0,1]).range([0,width])
        yAxis = d3.svg.axis().scale(y).orient("left")
        xAxis = d3.svg.axis().scale(x).orient("bottom")

        dataHist = d3.layout.histogram().bins(x.ticks(5))(arr)
        console.log dataHist
        yMax = d3.max dataHist, (d) ->
          return d.y

        # x axis
        _graph.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call xAxis
        .append('text')
        .attr('class', 'label')
        .attr('x', width)
        .attr('y', -6)
        .style('text-anchor', 'end')
        .text data.xLab

        # y axis
        _graph.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr('class', 'label')
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text data.yLab

        #_graph.select('g').remove()
        bar = _graph.selectAll('.bar')
        .data(dataHist).enter()
        .append("g")
        .attr("class", "bar")
        .attr("transform",(d) -> return "translate(" + x(d.x) + "," + y(d.y) + ")")
        bar.append('rect')
        .style("fill", "steelblue")
        .attr('x', 1)
        .attr('width', x(dataHist[0].dx) - 1)
        .attr 'height', (d) -> height - y(d.y)


      _drawScatterplot = () ->


        xMin = d3.min pairedData, (d) -> d.x
        yMin = d3.min pairedData, (d) -> d.y

        xMax = d3.max pairedData, (d) -> d.x
        yMax = d3.max pairedData, (d) -> d.y

        x = d3.scale.linear().domain([xMin,xMax]).range([ 0, width ])
        y = d3.scale.linear().domain([yMin,yMax]).range([ height, 0 ])
        xAxis = d3.svg.axis().scale(x).orient('bottom')
        yAxis = d3.svg.axis().scale(y).orient('left')

        #_graphScatter = svg.append("g")
        #.attr("transform", "translate(" + margin.left + "," + margin.top + ")").attr("id", "remove")

        console.log pairedData
        x.domain([d3.min(pairedData, (d)->d.x), d3.max(pairedData, (d)->d.x)])
        y.domain([d3.min(pairedData, (d)->d.x), d3.max(pairedData, (d)->d.y)])

        # values
        xValue = (d)->d.x
        yValue = (d)->d.y

        # map dot coordination
        xMap = (d)-> x xValue(d)
        yMap = (d)-> y yValue(d)

        # set up fill color
        cValue = (d)-> d.y
        color = d3.scale.category10()

        # x axis
        _graph.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call xAxis
        .append('text')
        .attr('class', 'label')
        .attr('x', width)
        .attr('y', -6)
        .style('text-anchor', 'end')
        .text data.xLab

        # y axis
        _graph.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr('class', 'label')
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text data.yLab

        # add the tooltip area to the webpage
        tooltip = svg
        .append('div')
        .attr('class', 'tooltip')
        .style('opacity', 0)

        # draw dots
        _graph.selectAll('.dot')
        .data(pairedData)
        .enter().append('circle')
        .attr('class', 'dot')
        .attr('r', 5)
        .attr('cx', xMap)
        .attr('cy', yMap)
        .style('fill', (d)->color cValue(d))
        .on('mouseover', (d)->
          tooltip.transition().duration(200).style('opacity', .9)
          tooltip.html('<br/>(' + xValue(d)+ ',' + yValue(d) + ')')
          .style('left', d3.select(this).attr('cx') + 'px').style('top', d3.select(this).attr('cy') + 'px'))
        .on('mouseout', (d)->
          tooltip. transition().duration(500).style('opacity', 0))

        # draw legend
        legend = _graph.selectAll('.legend')
        .data(color.domain())
        .enter().append('g')
        .attr('class', 'legend')
        .attr('transform', (d, i)-> 'translate(0,' + i * 20 + ')')
        .text data.yLab

        # draw legend colored rectangles
        legend.append('rect')
        .attr('x', width - 18)
        .attr('width', 18)
        .attr('height', 18)
        .style('fill', color)

        # draw legend text
        legend.append('text')
        .attr('x', width - 24)
        .attr('y', 9)
        .attr('dy', '.35em')
        .style('text-anchor', 'end')
        .text((d)-> d)

      _drawBubble = () ->
        x = d3.scale.linear().range([ 0, width ])
        y = d3.scale.linear().range([ height, 0 ])
        r = d3.scale.linear().range([0,5])
        xAxis = d3.svg.axis().scale(x).orient('bottom')
        yAxis = d3.svg.axis().scale(y).orient('left')

        x.domain([d3.min(pairedData, (d)->d.x), d3.max(pairedData, (d)->d.x)])
        y.domain([d3.min(pairedData, (d)->d.x), d3.max(pairedData, (d)->d.y)])
        r.domain([0, d3.max(pairedData, (d)->d.y)])

        # x axis
        _graph.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call xAxis
        .append('text')
        .attr('class', 'label')
        .attr('x', width)
        .attr('y', -6)
        .style('text-anchor', 'end')
        .text data.xLab

        # y axis
        _graph.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr('class', 'label')
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text data.yLab


        # create circle
        _graph.selectAll('.circle')
        .data(pairedData)
        .enter().append('circle')
        .attr('fill', 'yellow')
        .attr('opacity', '0.7')
        .attr('stroke', 'orange')
        .attr('stroke-width', '2px')
        .attr('cx', (d)->x d.x)
        .attr('cy', (d)->y d.y)
        .attr('r', (d)-> Math.sqrt(Math.abs(height - d.y)/10))

      _drawPie = () ->
        radius = Math.min(width, height) / 2

        arc = d3.svg.arc()
        .outerRadius(radius)
        .innerRadius(0)

        labelArc = d3.svg.arc()
        .outerRadius(radius-10)
        .innerRadius(radius-10)

        color = d3.scale.category20b()

        pie = d3.layout.pie()
        #.value (d) -> d.count
        .value (d) -> parseFloat d.value
        type = (d) ->
          d.y = +d.y
          return d

        _graph.selectAll('path')
              .data(pie(pieData))
              .enter()
              .append('path')
              .attr('d', arc)
              .attr('fill', (d,i) -> color(d.data.key))
#
      #g = _graph.selectAll(".arc")
#        .data(pie(pairedData))
#        .enter().append("g")
#        .attr("class", "arc");
#
#        g.append("path")
#        .attr("d", arc)
        #.style("fill", function(d) { return color(d.data.age); });
        #.style("fill", (d) -> color(d.x))

        #g.append("text")
        #.attr("transform", function(d) { return "translate(" + labelArc.centroid(d) + ")"; })
        #.attr("transform", (d) -> "translate(" + labelArc.centroid(d) + ")")
        #.attr("dy", ".35em")
        #.text(function(d) { return d.data.age; });
        #.text (d) -> d.x

      scope.$watch 'chartData', (newChartData) ->
        if newChartData
          data = newChartData
          console.log data
          makePairs(data)
          makepieData(data.xVar)
          #id = '#'+ newInfo.name
          svg = d3.select(elem.find("svg")[0])
          #svg.select("#remove").remove()
          svg.selectAll('*').remove()
          _graph = svg.append('g').attr("transform", "translate(" + margin.left + "," + margin.top + ")").attr("id", "remove")
#          if data.name is "Histogram"
#            _drawHist()
#          else if data.name is "Scatter Plot"
#            _drawScatterplot()
#          else if data.name is "Bubble Chart"
#            _drawBubble()
#          else if data.name is "Bar Graph"
#            _drawBar()
#          else if data.name is "Pie Chart"
#            _drawPie()

          switch data.name
            when 'Bar Graph'
              _drawBar()
            when 'Bubble Chart'
              _drawBubble()
            when 'Histogram'
              _drawHist()
            when 'Pie Chart'
              _graph = svg.append('g').attr("transform", "translate(300,300)").attr("id", "remove")
              _drawPie()
            when 'Scatter Plot'
              _drawScatterplot()
]