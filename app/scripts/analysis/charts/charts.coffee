'use strict'

charts = angular.module('app_analysis_charts', [])

.factory('app_analysis_charts_constructor', [
  'app_analysis_charts_manager'
  (manager)->
    (sb)->

      manager.setSb sb unless !sb?
      _msgList = manager.getMsgList()

      init: (opt) ->
        console.log '%cCHARTS: charts init called'

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

.controller('mainChartsCtrl', [
  'app_analysis_charts_manager'
  '$scope'
  (ctrlMngr,$scope) ->
    _chart_data = null

    _updateData = () ->
      $scope.chartData = _chart_data

    $scope.$on 'charts:graphDiv', (event, data) ->
      _chart_data = data
      _updateData()
])



.controller('sideChartsCtrl',[
  'app_analysis_charts_manager'
  '$scope'
  '$rootScope'
  '$stateParams'
  '$q'
  'app_analysis_charts_dataTransform'
  (ctrlMngr, $scope, $rootScope, $stateParams, $q, dataTransform) ->
    _chartData = null
    _headers = null

    $scope.selector1 = {}
    $scope.selector2 = {}
    $scope.selector3 = {}


    $scope.graphInfo =
      graph: ""
      x: ""
      y: ""
      z: ""

    $scope.graphs = [
      name: 'Bar Graph'
      value: 0
      x: true
      y: true
      z: false
      message: "Use option x to choose a numerical or categorical variable, or choose one categorical variable and one numerical variable."
    ,
      name: 'Scatter Plot'
      value: 1
      x: true
      y: true
      z: false
      message: "Choose an x variable and a y variable."
    ,
      name: 'Histogram'
      value: 2
      x: true
      y: false
      z: false
      message: "Choose an x variable. Use the slider below the histogram to adjust the number of bins."
    ,
      name: 'Bubble Chart'
      value: 3
      x: true
      y: true
      z: true
      message: "Choose an x variable, a y variable and a radius variable."
    ,
      name: 'Pie Chart'
      value: 4
      x: true
      y: false
      z: false
      message: "Choose one variable to put into a pie chart."
    ,
      name: 'Area Chart'
      value: 5
      x: true
      y: true
      z: false
      message: "Pick date variable for x and numerical variable for y"
#    ,
#      name: 'Stream Graph'
#      value: 5
#      x: true
#      y: true
#      z: false
#      message: "Choose two numerical variables"

    ]
    $scope.graphSelect = {}



    $scope.createGraph = () ->
      graphFormat = () ->
        obj = []
        len = _chartData[0].length

        if $scope.graphInfo.y is "" and $scope.graphInfo.z is ""
          obj = []

          for i in [1...len] by 1
            tmp =
              x:  _chartData[$scope.graphInfo.x][i].value
            obj.push tmp

        else if $scope.graphInfo.y isnt "" and $scope.graphInfo.z is ""
          obj = []

          for i in [1...len] by 1
            tmp =
              x:  _chartData[$scope.graphInfo.x][i].value
              y:  _chartData[$scope.graphInfo.y][i].value
            obj.push tmp

        else
          obj = []

          for i in [1...len] by 1
            tmp =
              x:  _chartData[$scope.graphInfo.x][i].value
              y:  _chartData[$scope.graphInfo.y][i].value
              z:  _chartData[$scope.graphInfo.z][i].value
            obj.push tmp

        return obj
      send = graphFormat()
      results =
        data: send
        xLab: _headers[$scope.graphInfo.x],
        yLab: _headers[$scope.graphInfo.y],
        zLab: _headers[$scope.graphInfo.z],
        name: $scope.graphInfo.graph

      $rootScope.$broadcast 'charts:graphDiv', results

    $scope.labelVar = false
    $scope.labelCheck = null
    $scope.changeName = () ->
      $scope.graphInfo.graph = $scope.graphSelect.name


      $scope.createGraph()

    $scope.changeVar = (selector,headers, ind) ->
      for h in headers
        if selector.value is h.value then $scope.graphInfo[ind] = parseFloat h.key
      $scope.createGraph()


    sb = ctrlMngr.getSb()

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


.factory 'scatterPlot', [
  () ->
    _drawScatterPlot = (data,ranges,width,height,_graph,container,gdata) ->

      x = d3.scale.linear().domain([ranges.xMin,ranges.xMax]).range([ 0, width ])
      y = d3.scale.linear().domain([ranges.yMin,ranges.yMax]).range([ height, 0 ])
      xAxis = d3.svg.axis().scale(x).orient('bottom')
      yAxis = d3.svg.axis().scale(y).orient('left')

      # values
      xValue = (d)->parseFloat d.x
      yValue = (d)->parseFloat d.y

      # map dot coordination
      xMap = (d)-> x xValue(d)
      yMap = (d)-> y yValue(d)

      # set up fill color
      #cValue = (d)-> d.y
      #color = d3.scale.category10()

      # x axis
      _graph.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call xAxis
      .append('text')
      .attr('class', 'label')
      .attr('transform', 'translate(' + (width / 2) + ',' + 40 + ')')
      .text gdata.xLab.value

      # y axis
      _graph.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr('class', 'label')
      .attr("transform", "rotate(-90)")
      .attr('y', -50 )
      .attr('x', -(height / 2))
      .attr("dy", ".71em")
      .text gdata.yLab.value

      # add the tooltip area to the webpage
      tooltip = container
      .append('div')
      .attr('class', 'tooltip')

      # draw dots
      _graph.selectAll('.dot')
      .data(data)
      .enter().append('circle')
      .attr('class', 'dot')
      .attr('r', 5)
      .attr('cx', xMap)
      .attr('cy', yMap)
      .style('fill', 'DodgerBlue')
      .attr('opacity', '0.5')
      .on('mouseover', (d)->
        tooltip.transition().duration(200).style('opacity', .9)
        tooltip.html('<div style="background-color:white; padding:5px; border-radius: 5px">(' + xValue(d)+ ',' + yValue(d) + ')</div>')
        .style('left', d3.select(this).attr('cx') + 'px').style('top', d3.select(this).attr('cy') + 'px'))
      .on('mouseout', (d)->
        tooltip. transition().duration(500).style('opacity', 0))

    drawScatterPlot: _drawScatterPlot
]

.factory 'histogram',[
  () ->
    _drawHist = (_graph,data,container,gdata,width,height,ranges) ->
      container.append('input').attr('id', 'slider').attr('type','range').attr('min', '1').attr('max','10').attr('step', '1').attr('value','5')

      bins = null
      dataHist = null

      arr = data.map (d) -> parseFloat d.x
      x = d3.scale.linear().domain([ranges.xMin, ranges.xMax]).range([0,width])

      plotHist = (bins) ->
        $('#slidertext').remove()
        container.append('text').attr('id', 'slidertext').text('Bin Slider: '+bins).attr('position','relative').attr('left', '50px')
        dataHist = d3.layout.histogram().bins(bins)(arr)

        y = d3.scale.linear().domain([0,d3.max dataHist.map (i) -> i.length]).range([height,0])

        yAxis = d3.svg.axis().scale(y).orient("left")
        xAxis = d3.svg.axis().scale(x).orient("bottom")

        _graph.selectAll('g').remove()
        _graph.select('.x axis').remove()
        _graph.select('.y axis').remove()

        # x axis
        _graph.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call xAxis
        .append('text')
        .attr('class', 'label')
        .attr('transform', 'translate(' + (width / 2) + ',' + 40 + ')')
        .text gdata.xLab.value

        # y axis
        _graph.append("g")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr('class', 'label')
        .attr("transform", "rotate(-90)")
        .attr('y', -50 )
        .attr('x', -(height / 2))
        .attr("dy", ".71em")
        .text "Count"

        bar = _graph.selectAll('.bar')
        .data(dataHist)

        bar.enter()
        .append("g")

        rect_width = width/bins
        bar.append('rect')
        .attr('x', (d) -> x d.x)
        .attr('y', (d) -> height - y d.y)
        .attr('width', rect_width)
        .attr('height', (d) -> y d.y)
        .attr("stroke","white")
        .attr("stroke-width",1)
        .on('mouseover', () -> d3.select(this).transition().style('fill', 'orange'))
        .on('mouseout', () -> d3.select(this).transition().style('fill', 'steelblue'))

        bar.append('text')
        .attr('x', (d) -> x d.x)
        .attr('y', (d) -> height - y d.y)
        .attr('dx', (d) -> .5*rect_width)
        .attr('dy', '20px')
        .attr('fill', '#fff')
        .attr('text-anchor', 'middle')
        .attr('z-index', 1)
        .text (d) -> d.y

      plotHist(5) #pre-set value of slider

      d3.select('#slider')
      .on('change', () ->
        bins = parseInt this.value
        plotHist(bins)
      )
    drawHist: _drawHist
]

.factory 'pie', [
  () ->
    valueSum = 0
    makePieData = (data) ->
      valueSum = 0
      counts = {}
      if(!isNaN(data[0].x)) # data is number
        pieMax = d3.max(data, (d)-> parseFloat d.x)
        pieMin = d3.min(data, (d)-> parseFloat d.x)
        maxPiePieces = 7  # set magic constant to variable
        rangeInt = Math.ceil((pieMax - pieMin) / maxPiePieces)
        counts = {}
        for val in data
          index = Math.floor((val.x - pieMin) / rangeInt)
          groupName = index + "-" + (index + rangeInt)
          #console.log groupName
          counts[groupName] = counts[groupName] || 0
          counts[groupName]++
          valueSum++
      else # data is string
        for i in [0..data.length-1] by 1
          currentVar = data[i].x
          counts[currentVar] = counts[currentVar] || 0
          counts[currentVar]++
          valueSum++

      obj = d3.entries counts
      return obj

    _drawPie = (data,width,height,_graph) ->
      radius = Math.min(width, height) / 2
      arc = d3.svg.arc()
      .outerRadius(radius)
      .innerRadius(0)

      #color = d3.scale.ordinal().range(["#ffffcc","#c7e9b4","#7fcdbb","#41b6c4","#1d91c0","#225ea8","#0c2c84"])
      color = d3.scale.category20c()
      arcOver = d3.svg.arc()
      .outerRadius(radius + 10)

      pie = d3.layout.pie()
      .value((d)-> d.value)
      .sort(null)

      formatted_data = makePieData(data)

      arcs = _graph.selectAll(".arc")
      .data(pie(formatted_data))
      .enter()
      .append('g')
      .attr("class", "arc")

      arcs.append('path')
      .attr('d', arc)
      .attr('fill', (d) -> color(d.data.value))
      .on('mouseenter', (d) -> d3.select(this).attr("stroke","white") .transition().attr("d", arcOver).attr("stroke-width",3))
      .on('mouseleave', (d) -> d3.select(this).transition().attr('d', arc).attr("stroke", "none"))

      arcs.append('text')
      .attr('id','tooltip')
      .attr('transform', (d) -> 'translate('+arc.centroid(d)+')')
      .attr('text-anchor', 'middle')
      .text (d) -> d.data.key + ': ' + parseFloat(100*d.data.value/valueSum).toFixed(2) + '%'

    drawPie: _drawPie
]

.factory 'bubble', [
  () ->
    _drawBubble = (ranges,width,height,_graph,data,gdata,container) ->
      x = d3.scale.linear().domain([ranges.xMin,ranges.xMax]).range([ 0, width ])
      y = d3.scale.linear().domain([ranges.yMin,ranges.yMax]).range([ height, 0 ])
      xAxis = d3.svg.axis().scale(x).orient('bottom')
      yAxis = d3.svg.axis().scale(y).orient('left')

      zIsNumber = !isNaN(data[0].z)

      r = 0
      rValue = 0
      if(zIsNumber)
        r = d3.scale.linear()
        .domain([d3.min(data, (d)-> parseFloat d.z), d3.max(data, (d)-> parseFloat d.z)])
        .range([3,15])
        rValue = (d) -> parseFloat d.z
      else
        r = d3.scale.linear()
        .domain([5, 5])
        .range([3,15])
        rValue = (d) -> d.z

      tooltip = container
      .append('div')
      .attr('class', 'tooltip')

      color = d3.scale.category10()

      # x axis
      _graph.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
      .append('text')
      .attr('class', 'label')
      .attr('transform', 'translate(' + (width / 2) + ',' + 40 + ')')
      .text gdata.xLab.value

      # y axis
      _graph.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr('class', 'label')
      .attr("transform", "rotate(-90)")
      .attr('y', -50 )
      .attr('x', -(height / 2))
      .attr("dy", ".71em")
      .text gdata.yLab.value

      # create circle
      _graph.selectAll('.circle')
      .data(data)
      .enter().append('circle')
      .attr('fill',
        if(zIsNumber)
          'yellow'
        else
          (d) -> color(d.z))
      .attr('opacity', '0.7')
      .attr('stroke',
        if(zIsNumber)
          'orange'
        else
          (d) -> color(d.z))
      .attr('stroke-width', '2px')
      .attr('cx', (d) -> x d.x)
      .attr('cy', (d) -> y d.y)
      .attr('r', (d) ->
        if(zIsNumber) # if d.z is number, use d.z as radius
          r d.z
        else # else, set radius to be 8
          8)
      .on('mouseover', (d) ->
        tooltip.transition().duration(200).style('opacity', .9)
        tooltip.html('<div style="background-color:white; padding:5px; border-radius: 5px">'+gdata.zLab.value+': '+ rValue(d)+'</div>')
        .style('left', d3.select(this).attr('cx') + 'px').style('top', d3.select(this).attr('cy') + 'px'))
      .on('mouseout', () ->
        tooltip. transition().duration(500).style('opacity', 0))
    drawBubble: _drawBubble
]

.factory 'bar', [
  () ->
    _setAxisPar = (x,y,xAxis,yAxis,type, width, height) ->
      ord = d3.scale.ordinal()
      lin = d3.scale.linear()

      switch type
        when "xCat" or "xCatAndyNum"
          x = ord.rangeRoundBands([0, width], .1)
          y = lin.range([ height, 0 ])
        when "xNum" or "xNumAndyCat"
          x = lin.range([ 0, width ])
          y = ord.rangeRoundBands([height, 0], .1)
        when "xNumAndyNum"
          x = lin.range([ 0, width ])
          y = lin.range([ height, 0 ])
        else
          alert "Two categorical variables"


      xAxis = d3.svg.axis().scale(x).orient('bottom')
      yAxis = d3.svg.axis().scale(y).orient('left')

    _drawBar = (width,height,data,_graph,gdata) ->
      x = d3.scale.linear().range([ 0, width ])
      y = d3.scale.linear().range([ height, 0 ])


      xAxis = d3.svg.axis().scale(x).orient('bottom')
      yAxis = d3.svg.axis().scale(y).orient('left')
      x.domain([d3.min(data, (d)->parseFloat d.x), d3.max(data, (d)->parseFloat d.x)])
      y.domain([d3.min(data, (d)->parseFloat d.y), d3.max(data, (d)->parseFloat d.y)])

      #without y
      if !data[0].y
        #Works
        if isNaN data[0].x
          counts = {}
          for i in [0..data.length-1] by 1
            currentVar = data[i].x
            counts[currentVar] = counts[currentVar] || 0
            counts[currentVar]++
          counts = d3.entries counts
#          console.log counts
          x = d3.scale.ordinal().rangeRoundBands([0, width], .1)
          xAxis = d3.svg.axis().scale(x).orient('bottom')
          x.domain(counts.map (d) -> d.key)
          y.domain([d3.min(counts, (d)-> parseFloat d.value), d3.max(counts, (d)-> parseFloat d.value)])

          _graph.append('g')
          .attr('class', 'x axis')
          .attr('transform', 'translate(0,' + height + ')')
          .call xAxis
          .append('text')
          .attr('class', 'label')
          .attr('transform', 'translate(' + (width / 2) + ',' + 40 + ')')
          .text gdata.xLab.value

          _graph.append('g')
          .attr('class', 'y axis')
          .call yAxis
          .append('text')
          .attr('transform', 'rotate(-90)')
          .attr('y', -50 )
          .attr('x', -(height / 2))
          .attr('dy', '1em')
          .text "Count"

          # create bar elements
          _graph.selectAll('rect')
          .data(counts)
          .enter().append('rect')
          .attr('class', 'bar')
          .attr('x',(d)-> x d.key  )
          .attr('width', x.rangeBand())
          .attr('y', (d)-> y d.value )
          .attr('height', (d)-> Math.abs(height - y d.value))
          .attr('fill', 'steelblue')


        else #data is numerical and only x. height is rect width, width is x of d.x,
          #y becomes the categorical
          y = d3.scale.ordinal().rangeRoundBands([height, 0], .1)
          yAxis = d3.svg.axis().scale(y).orient('left')

          y.domain((d) -> d.x)

          _graph.append('g')
          .attr('class', 'x axis')
          .attr('transform', 'translate(0,' + height + ')')
          .call xAxis
          .append('text')
          .attr('class', 'label')
          .attr('transform', 'translate(' + (width / 2) + ',' + 40 + ')')
          .text gdata.xLab.value

          _graph.append('g')
          .attr('class', 'y axis')
          .call yAxis
          .append('text')
          .attr('transform', 'rotate(-90)')
          .attr('y', -50 )
          .attr('x', -(height / 2))
          .attr('dy', '1em')
          .text "Null"

          rectWidth = height/data.length
          # create bar elements
          _graph.selectAll('rect')
          .data(data)
          .enter().append('rect')
          .attr('class', 'bar')
          #.attr('x',(d)-> x d.x )
          .attr('width', (d)-> x d.x)
          .attr('y', (d,i)-> i*rectWidth)
          .attr('height', rectWidth)
          .attr('fill', 'steelblue')



      #with y
      else
        #y is categorical
        if isNaN data[0].y

          y = d3.scale.ordinal().rangeRoundBands([0, height], .1)
          y.domain(data.map (d) -> d.y)
          yAxis = d3.svg.axis().scale(y).orient('left')

          _graph.append('g')
          .attr('class', 'x axis')
          .attr('transform', 'translate(0,' + height + ')')
          .call xAxis
          .append('text')
          .attr('class', 'label')
          .attr('x', width-80)
          .attr('y', 30)
          .text gdata.xLab.value

          _graph.append('g')
          .attr('class', 'y axis')
          .call yAxis
          .append('text')
          .attr('transform', 'rotate(-90)')
          .attr("x", -80)
          .attr("y", -40)
          .attr('dy', '1em')
          .text gdata.yLab.value

          _graph.selectAll('rect')
          .data(data)
          .enter().append('rect')
          .attr('class', 'bar')
          #.attr('x',(d)-> x d.x  )
          .attr('width', (d) -> Math.abs(x d.x))
          .attr('y', (d)-> y d.y )
          .attr('height', y.rangeBand())
          .attr('fill', 'steelblue')


        else if !isNaN data[0].y
          if isNaN data[0].x
            console.log "xCat and yNum"
            x = d3.scale.ordinal().rangeRoundBands([0, width], .1)
            x.domain(data.map (d) -> d.x)
            xAxis = d3.svg.axis().scale(x).orient('bottom')
            #y.domain([d3.min(data, (d)-> parseFloat d.y), d3.max(data, (d)-> parseFloat d.y)])

            _graph.append('g')
            .attr('class', 'x axis')
            .attr('transform', 'translate(0,' + height + ')')
            .call xAxis
            .append('text')
            .attr('class', 'label')
            .attr('transform', 'translate(' + (width / 2) + ',' + 40 + ')')
            .text gdata.xLab.value

            _graph.append('g')
            .attr('class', 'y axis')
            .call yAxis
            .append('text')
            .attr('transform', 'rotate(-90)')
            .attr('y', -50 )
            .attr('x', -(height / 2))
            .attr('dy', '1em')
            .text "Count"

            # create bar elements
            _graph.selectAll('rect')
            .data(data)
            .enter().append('rect')
            .attr('class', 'bar')
            .attr('x',(d)-> x d.x  )
            .attr('width', x.rangeBand())
            .attr('y', (d)-> y d.y )
            .attr('height', (d)-> Math.abs(height - y d.y))
            .attr('fill', 'steelblue')
          else

        #else if !isNaN data[0].y and !isNaN data[0].x
            rectWidth = width / data.length

            _graph.append('g')
            .attr('class', 'x axis')
            .attr('transform', 'translate(0,' + height + ')')
            .call xAxis
            .append('text')
            .attr('class', 'label')
            .attr('x', width-80)
            .attr('y', 30)
            .text gdata.xLab.value

            _graph.append('g')
            .attr('class', 'y axis')
            .call yAxis
            .append('text')
            .attr('transform', 'rotate(-90)')
            .attr("x", -80)
            .attr("y", -40)
            .attr('dy', '1em')
            .text gdata.yLab.value


            # create bar elements
            _graph.selectAll('rect')
            .data(data)
            .enter().append('rect')
            .attr('class', 'bar')
            .attr('x',(d)-> x d.x  )
            .attr('width', rectWidth)
            .attr('y', (d)-> y d.y )
            .attr('height', (d)-> Math.abs(height - y d.y) )
            .attr('fill', 'steelblue')



    drawBar: _drawBar
]

.factory 'streamGraph', [
  () ->

    _randomSample  = (data, n) ->
      #take an array of objects, and the desired number of random ones. return array of objects
      for d in data
        d.x = +d.x
        d.y = +d.y

      random = []
      for i in [0...n-1] by 1
        random.push(data[Math.floor(Math.random() * data.length)])
      return random

    _streamGraph = (data,ranges,width,height,_graph) ->
      n = 20
      m = 100
      stack = d3.layout.stack().offset('wiggle')
      layers = stack(d3.range(n).map () -> _randomSample(data,m))
      console.log layers
      x = d3.scale.linear()
        .domain([0, m - 1])
        .range([0, width]);

      y = d3.scale.linear()
          .domain([0, d3.max(layers, (layer)-> d3.max(layer, (d) -> return d.y0 + d.y))])
          .range([height, 0])

      color = d3.scale.linear()
        .range(["#aad", "#556"])

      area = d3.svg.area()
              .x((d) -> x d.x)
              .y0((d) -> y d.y0)
              .y1((d) -> y(d.y0 + d.y))

      _graph.selectAll("path")
          .data(layers)
          .enter().append("path")
          .attr("d", area)
          .style("fill", () -> color(Math.random()))

    streamGraph: _streamGraph
]


.factory 'area',[
  ()->
    _drawArea = (height,width,_graph, data) ->
      parseDate = d3.time.format("%d-%b-%y").parse

      for d in data
        d.x = parseDate d.x
        d.y = +d.y
      x = d3.time.scale().range([ 0, width ])
      y = d3.scale.linear().range([ height, 0 ])
      xAxis = d3.svg.axis().scale(x).orient("bottom")
      yAxis = d3.svg.axis().scale(y).orient("left")
      area = d3.svg.area().x((d) ->
        x d.x
      ).y0(height).y1((d) ->
        y d.y
      )
    #  svg = d3.select("body").append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")

      x.domain d3.extent(data, (d) ->
          d.x
        )
      y.domain [ 0, d3.max(data, (d) ->
          d.y
        ) ]
      _graph.append("path").datum(data).attr("class", "area").attr "d", area
      _graph.append("g").attr("class", "x axis").attr("transform", "translate(0," + height + ")").call xAxis
      _graph.append("g").attr("class", "y axis").call(yAxis).append("text").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", ".71em").style("text-anchor", "end").text "Price ($)"

    drawArea: _drawArea
]

.directive 'd3Charts', [
  'scatterPlot',
  'histogram',
  'pie',
  'bubble',
  'bar',
  'streamGraph',
  'area'
  (scatterPlot,histogram,pie,bubble,bar,streamGraph, area) ->
    restrict: 'E'
    template: "<div class='graph-container' style='height: 600px'></div>"
    link: (scope, elem, attr) ->
      margin = {top: 10, right: 40, bottom: 50, left:80}
      width = 750 - margin.left - margin.right
      height = 500 - margin.top - margin.bottom
      svg = null
      data = null
      _graph = null
      container = null
      gdata = null
      ranges = null

      scope.$watch 'chartData', (newChartData) ->
        if newChartData
          gdata = newChartData
          data = newChartData.data
#          _label = null

          console.log data

          #id = '#'+ newInfo.name
          container = d3.select(elem.find('div')[0])
          container.selectAll('*').remove()
          console.log "test"
          svg = container.append('svg').attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom)
          #svg.select("#remove").remove()
          _graph = svg.append('g').attr("transform", "translate(" + margin.left + "," + margin.top + ")")

          ranges =
            xMin: d3.min data, (d) -> parseFloat d.x
            yMin: d3.min data, (d) -> parseFloat d.y

            xMax: d3.max data, (d) -> parseFloat d.x
            yMax: d3.max data, (d) -> parseFloat d.y

#          $scope.on 'Charts: labels y', (events, data) ->
#            _label = data

          switch gdata.name
            when 'Bar Graph'
              bar.drawBar(width,height,data,_graph,gdata)
            when 'Bubble Chart'
              bubble.drawBubble(ranges,width,height,_graph,data,gdata,container)
            when 'Histogram'
              histogram.drawHist(_graph,data,container,gdata,width,height,ranges)
            when 'Pie Chart'
              _graph = svg.append('g').attr("transform", "translate(300,250)").attr("id", "remove")
              pie.drawPie(data,width,height,_graph)
            when 'Scatter Plot'
              scatterPlot.drawScatterPlot(data,ranges,width,height,_graph,container,gdata)
            when 'Stream Graph'
              streamGraph.streamGraph(data,ranges,width,height,_graph)
            when 'Area Chart'
              area.drawArea(height,width,_graph, data)
]
