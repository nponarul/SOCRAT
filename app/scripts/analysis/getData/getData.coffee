'use strict'

getData = angular.module('app_analysis_getData', [
  #The frontend modules (app.getData,app.cleanData etc) should have
  # no dependency from the backend.
  #Try to keep it as loosely coupled as possible
  'ui.bootstrap'
])

.config([
  # ###
  # Config block is for module initialization work.
  # services, providers from ng module (such as $http, $resource)
  # can be injected here.
  # services, providers defined in this module CANNOT be injected
  # in the config block.
  # config block is run before their initialization.
  # ###
    () ->
      console.log 'config block of getData'
])

.factory('app_analysis_getData_constructor', [
  'app_analysis_getData_manager'
  (manager) ->
    (sb) ->

      manager.setSb sb unless !sb?
      _msgList = manager.getMsgList()

      init: (opt) ->
        console.log 'getData init invoked'

      destroy: () ->

      msgList: _msgList
])

.factory('app_analysis_getData_manager', [
  () ->
    _sb = null

    _msgList =
      outgoing: ['save data']
      incoming: ['get data']
      scope: ['getData']

    _setSb = (sb) ->
      _sb = sb

    _getSb = () ->
      _sb

    _getMsgList = () ->
      _msgList

    _getSupportedDataTypes = () ->
      if _sb
        _sb.getSupportedDataTypes()
      else
        false

    getSb: _getSb
    setSb: _setSb
    getMsgList: _getMsgList
    getSupportedDataTypes: _getSupportedDataTypes
])

# ###
# @name: app_analysis_getData_inputCache
# @type: service
# @description: Caches data. Changes to handsontable is stored here
# and synced after some time. Changes in db is heard and reflected on
# handsontable.
# ###
.service('app_analysis_getData_inputCache',[
  'app_analysis_getData_manager'
  '$q'
  '$stateParams'
  '$rootScope'
  '$timeout'
  (manager, $q, $stateParams, $rootScope, $timeout) ->

    DATA_TYPES = manager.getSupportedDataTypes()
    sb = manager.getSb()
    _data = {}
    _timer = null
    _ht = null

    _getData = ->
      _data

    _saveDataToDb = (data, deferred) ->

      msgEnding = if data.dataType is DATA_TYPES.FLAT then ' as 2D data table' else ' as hierarchical object'

      $rootScope.$broadcast 'app:push notification',
        initial:
          msg: 'Data is being saved in the database...'
          type: 'alert-info'
        success:
          msg: 'Successfully loaded data into database' + msgEnding
          type: 'alert-success'
        failure:
          msg: 'Error in Database'
          type: 'alert-error'
        promise: deferred.promise

      sb.publish
        msg: 'save data'
        data:
          dataFrame: data
          tableName: $stateParams.projectId + ':' + $stateParams.forkId
          promise: deferred
        msgScope: ['getData']
        callback: ->
          console.log 'handsontable data updated to db'

    _setData = (data) ->
      console.log '%c inputCache set called for the project' + $stateParams.projectId + ':' + $stateParams.forkId,
        'color:steelblue'

      # TODO: fix checking existance of parameters to default table name #SOCR-140
      if data? or $stateParams.projectId? or $stateParams.forkId?
        _data = data unless data is 'edit'

        # clear any previous db update broadcast messages
        clearTimeout _timer
        _deferred = $q.defer()
        _timer = $timeout ((data, deferred) -> _saveDataToDb(data, deferred))(_data, _deferred), 1000
        true

      else
        console.log "no data passed to inputCache"
        false

    _pushData = (data) ->
      this.ht.loadData data

    get: _getData
    set: _setData
    push: _pushData
])


# jsonParser gets json based on url
#
# @type: factory
# @description: jsonParser parses the json url input by the user.
# @dependencies : $q, $rootscope, $http
.factory('app_analysis_getData_jsonParser', [
  '$http'
  '$q'
  '$rootScope'
  ($http, $q, $rootScope) ->
    (opts) ->
      return null if not opts?

      # test json : https://graph.facebook.com/search?q=ucla
      deferred = $q.defer()
      console.log deferred.promise

      switch opts.type

        when 'worldBank'
          # create the callback
          cb = (data, status) ->
            # obj[0] will contain meta deta
            # obj[1] will contain array
            _col = []
            _column = []
            tree = []

            count = (obj) ->
              try
                if typeof obj is 'object' and obj isnt null
                  for key in Object.keys obj
                    tree.push key
                    count obj[key]
                    tree.pop()
                else
                  _col.push tree.join('.')
                return _col
              catch e
                console.log e.message
              return true

            # generate titles and references
            count data[1][0]
            # format data
            for c in _col
              _column.push
                data: c

            # return object
            data: data
            columns: _column
            columnHeader: _col
            # purpose is helps in pin pointing which
            # handsontable directive to update.
            purpose: 'json'

        else
          #default implementation
          cb = (data, status) ->
            console.log data
            return data

      # using broadcast because msg sent from rootScope
      $rootScope.$broadcast 'app:push notification',
        initial:
          msg: 'Asking worldbank...'
          type: 'alert-info'
        success:
          msg: 'Successfully loaded data.'
          type: 'alert-success'
        failure:
          msg: 'Error in the call.'
          type: 'alert-error'
        promise: deferred.promise

      # make the call using the cb we just created
      $http.jsonp(
        opts.url
        )
        .success((data, status) ->
          console.log 'deferred.promise'
          formattedData = cb data, status
          deferred.resolve formattedData
          #$rootScope.$apply()
        )
        .error((data, status) ->
            console.log 'promise rejected'
            deferred.reject 'promise is rejected'
        )

      deferred.promise
])

# ###
# getDataSidebarCtrl is the ctrl that talks to the view.
# ###
.controller('getDataSidebarCtrl', [
  '$q'
  '$scope'
  'app_analysis_getData_manager'
  'app_analysis_getData_jsonParser'
  '$stateParams'
  'app_analysis_getData_inputCache'
  ($q, $scope, eventManager, jsonParser, $stateParams, inputCache) ->
    $scope.jsonUrl = ''
    flag = true
    $scope.selected = null

    DATA_TYPES = eventManager.getSupportedDataTypes()

    passReceivedData = (data) ->
      if data.dataType is DATA_TYPES.NESTED
        inputCache.set data
      else
        # default data type is 2d 'flat' table
        data.dataType = DATA_TYPES.FLAT
        # pass a message to update the handsontable div
        # data is the formatted data which plugs into the
        #  handontable.
        # TODO: getData module shouldn't know about controllers listening for handsontable update
        $scope.$emit 'update handsontable', data

    # showGrid
    $scope.show = (val) ->
      switch val
        when 'grid'
          $scope.selected = 'getDataGrid'
          if flag is true
            flag = false
            #initial the div for the first time
            data =
              default: true
              purpose: 'json'
            passReceivedData data
          $scope.$emit 'change in showStates', 'grid'

        when 'socrData'
          $scope.selected = 'getDataSocrData'
          $scope.$emit 'change in showStates', 'socrData'

        when 'worldBank'
          $scope.selected = 'getDataWorldBank'
          $scope.$emit 'change in showStates', 'worldBank'

        when 'generate'
          $scope.selected = 'getDataGenerate'
          $scope.$emit 'change in showStates', 'generate'

        when 'jsonParse'
          $scope.selected = 'getDataJson'
          $scope.$emit 'change in showStates', 'jsonParse'

    # getJson
    $scope.getJson = ->
      console.log $scope.jsonUrl

      if $scope.jsonUrl is ''
        return false

      jsonParser
        url: $scope.jsonUrl
        type: 'worldBank'
      .then(
        (data) ->
          # Pass a message to update the handsontable div.
          # data is the formatted data which plugs into the
          # handontable.
          passReceivedData data
          $scope.$emit 'get Data from handsontable', inputCache
        ,
        (msg) ->
          console.log 'rejected'
        )

    # get url data
    $scope.getUrl = ->

    $scope.getGrid = ->
])

.controller('getDataMainCtrl', [
  'app_analysis_getData_manager'
  '$scope'
  'showState'
  'app_analysis_getData_jsonParser'
  'app_analysis_getData_dataAdaptor'
  'app_analysis_getData_inputCache'
  '$state'
  (eventManager, $scope, showState, jsonParser, dataAdaptor, inputCache, state) ->
    console.log 'getDataMainCtrl executed'

    DATA_TYPES = eventManager.getSupportedDataTypes()
    $scope.DATA_TYPES = DATA_TYPES
    $scope.dataType = ''

    passReceivedData = (data) ->
      if data.dataType is DATA_TYPES.NESTED
        $scope.dataType = DATA_TYPES.NESTED
        inputCache.set data
      else
        # default data type is 2d 'flat' table
        data.dataType = DATA_TYPES.FLAT
        $scope.dataType = DATA_TYPES.FLAT
        # pass a message to update the handsontable div
        # data is the formatted data which plugs into the
        #  handontable.
        # TODO: getData module shouldn't know about controllers listening for handsontable update
        $scope.$emit 'update handsontable', data

    # available SOCR Datasets
    $scope.socrDatasets = [
      id: 'IRIS'
      name: 'Iris Flower Dataset'
    ,
      id: 'KNEE_PAIN'
      name: 'Simulated SOCR Knee Pain Centroid Location Data'
    ]
    # select first one by default
    $scope.socrdataset = $scope.socrDatasets[0]

    $scope.getWB = ->
      # default value
      if $scope.size is undefined
        $scope.size = 100
      # default option
      if $scope.option is undefined
        $scope.option = '4.2_BASIC.EDU.SPENDING'

      url = 'http://api.worldbank.org/countries/indicators/' + $scope.option +
          '?per_page=' + $scope.size + '&date=2011:2011&format=jsonp' +
          '&prefix=JSON_CALLBACK'

      jsonParser
        url: url
        type: 'worldBank'
      .then(
        (data) ->
          console.log 'resolved'
          passReceivedData data
        ,
        (msg) ->
          console.log 'rejected:' + msg
        )

    $scope.getSocrData = ->
      switch $scope.socrdataset.id
        # TODO: host on SOCR server
        when 'IRIS' then url = 'https://www.googledrive.com/host//0BzJubeARG-hsMnFQLTB3eEx4aTQ'
        when 'KNEE_PAIN' then url = 'https://www.googledrive.com/host//0BzJubeARG-hsLUU1Ul9WekZRV0U'
        # default option
        else url = 'https://www.googledrive.com/host//0BzJubeARG-hsMnFQLTB3eEx4aTQ'

      d3.text url,
        (dataResults) ->
          if dataResults?.length > 0
            # parse to unnamed array
            dataResults = d3.csv.parseRows dataResults
            _data =
              columnHeader: dataResults.shift()
              data: [null, dataResults]
              # purpose is helps in pin pointing which
              # handsontable directive to update.
              purpose: 'json'
            console.log 'resolved'
            passReceivedData _data
          else
            console.log 'rejected:' + msg

    $scope.getJsonByUrl = (type) ->
      d3.json $scope.jsonUrl,
        (dataResults) ->
          # check that data object is not empty
          if dataResults? and Object.keys(dataResults)?.length > 0
            res = dataAdaptor.jsonToFlatTable dataResults
            # check if JSON contains "flat data" - 2d array
            if res
              _data =
                columnHeader: if res.length > 1 then res.shift() else []
                data: [null, res]
                # purpose is helps in pin pointing which
                # handsontable directive to update.
                purpose: 'json'
                dataType: DATA_TYPES.FLAT
            else
              _data =
                data: dataResults
                dataType: DATA_TYPES.NESTED
            passReceivedData _data
          else
            console.log 'GETDATA: request failed'

    try
      _showState = new showState(['grid', 'socrData', 'worldBank', 'generate', 'jsonParse'], $scope)
    catch e
      console.log e.message

    # adding listeners
    $scope.$on 'update showStates', (obj, data) ->
      _showState.set data
      # TODO: fix this workaround for displaying copy-paste table
      $scope.dataType = DATA_TYPES.FLAT if data is 'grid'

    $scope.$on '$viewContentLoaded', ->
      console.log 'get data main div loaded'
])

# Helps sidebar accordion to keep in sync with the main div
.factory('showState', ->
  (obj, scope) ->
    if arguments.length is 0
      # return false if no arguments are provided
      return false
    _obj = obj

    # create a showState variable and attach it to supplied scope
    scope.showState = []
    for i in obj
      scope.showState[i] = true

    # index is the array key
    set: (index) ->
      if scope.showState[index]?
        for i in _obj
          if i is index
            scope.showState[index] = false
          else
            scope.showState[i] = true
)

# ###
# @name: app_analysis_getData_table2dataFrame
# @type: factory
# @description: Reformats data from input table format to the universal dataFrame object.
# ###
.factory('app_analysis_getData_dataAdaptor', [
  'app_analysis_getData_manager'
  (eventManager) ->

    DATA_TYPES = eventManager.getSupportedDataTypes()

    # https://coffeescript-cookbook.github.io/chapters/arrays/check-type-is-array
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call(value) is '[object Array]'

    haveSameKeys = (obj1, obj2) ->
      if Object.keys(obj1).length is Object.keys(obj2).length
        res = (k of obj2 for k of obj1)
        res.every (e) -> e is true
      else
        false

    isNumStringArray = (arr) ->
      console.log arr
      arr.every (el) -> typeof el in ['number', 'string']

    # accepts handsontable table as input and returns dataFrame
    _toDataFrame = (tableData, nSpareCols, nSpareRows) ->

      # using pop to remove empty last row
      tableData.data.pop()
      # and column
      row.pop() for row in tableData.data

      # remove empty last column for header
      tableData.header.pop()

      # by default data types are not known at this step
      #  and should be defined at Clean Data step
      colTypes = ('symbolic' for [1...tableData.nCols - nSpareCols])

      dataFrame =
        data: tableData.data
        header: tableData.header
        nRows: tableData.nRows - nSpareRows
        nCols: tableData.nCols - nSpareCols
        dataType: DATA_TYPES.FLAT

    _toHandsontable = () ->
      # TODO: implement for poping up data when coming back from analysis tabs

    # tries to convert JSON to 2d flat data table,
    #  assumes JSON object is not empty - has values,
    #  returns coverted data or false if not possible
    _jsonToFlatTable = (data) ->
      # check if JSON contains "flat data" - 2d array
      if data? and typeof data is 'object'
        if typeIsArray data
          # non-empty array
          if not (data.every (el) -> typeof el is 'object')
            # 1d array of strings or numbers
            if (data.every (el) -> typeof el in ['number', 'string'])
              data
          else
            # array of arrays or objects
            if (data.every (el) -> typeIsArray el)
              # array of arrays
              if (data.every (col) -> col.every (el) -> typeof el in ['number', 'string'])
                # array of arrays of (numbers or strings)
                data
              else
                # non-string values
                false
            else
              # array of arbitrary objects
              # http://stackoverflow.com/a/21266395/1237809
              if (not not data.reduce((prev, next) ->
                # check if objects have same keys
                if haveSameKeys prev, next
                  prevValues = Object.keys(prev).map (k) -> prev[k]
                  nextValues = Object.keys(prev).map (k) -> next[k]
                  # check that values are numeric/string
                  if ((prevValues.length is nextValues.length) and
                    (isNumStringArray prevValues) and
                    (isNumStringArray nextValues)
                  )
                    next
                  else NaN
                else NaN
              ))
                # array of objects with the same keys - make them columns
                cols = Object.keys data[0]
                # reorder values according to keys order
                data = (cols.map((col) -> row[col]) for row in data)
                # insert keys as a header
                data.splice 0, 0, cols
                data
              else
                false
        else
          # arbitrary object
          ks = Object.keys(data)
          vals = ks.map (k) -> data[k]
          if (vals.every (el) -> typeof el in ['number', 'string'])
            # 1d object
            data = [ks, vals]
          else if (vals.every (el) -> typeof el is 'object')
            # object of arrays or objects
            if (vals.every (row) -> typeIsArray row) and
            (vals.every (row) -> row.every (el) -> typeof el in ['number', 'string'])
              # object of arrays
              vals = (t[i] for t in vals for i of vals)  # transpose
              vals.splice 0, 0, ks  # add header
              vals
            else
              # object of arbitrary objects
            if (not not vals.reduce((prev, next) ->
              # check if objects have same keys
              if haveSameKeys prev, next
                prevValues = Object.keys(prev).map (k) -> prev[k]
                nextValues = Object.keys(prev).map (k) -> next[k]
                # check that values are
                if ((prevValues.length is nextValues.length) and
                  (isNumStringArray prevValues) and
                  (isNumStringArray nextValues)
                )
                  next
                else NaN
              else NaN
            ))
              subKs = Object.keys vals[0]
              data = ([sk].concat(vals.map((val)-> val[sk])) for sk in subKs)
              # insert keys as a header
              data.splice 0, 0, [""].concat ks
              data
          else false

    toDataFrame: _toDataFrame
    toHandsontable: _toHandsontable
    jsonToFlatTable: _jsonToFlatTable
])


.directive 'handsontable', [
  'app_analysis_getData_manager'
  'app_analysis_getData_inputCache'
  'app_analysis_getData_dataAdaptor'
  '$exceptionHandler'
  '$timeout'
  (eventManager, inputCache, dataAdaptor, $exceptionHandler, $timeout) ->

    restrict: 'E'
    transclude: true

    # to the name attribute on the directive element.
    # the template for the directive.
    template: "<div class='hot-scroll-container' style='height: 300px; width: 100%'></div>"

    #the controller for the directive
    controller: ($scope) ->

    replace: true #replace the directive element with the output of the template.

    # the link method does the work of setting the directive
    #  up, things like bindings, jquery calls, etc are done in here
    #  It is run before the controller
    link: (scope, elem, attr) ->

      $timeout ->
        N_SPARE_COLS = 1
        N_SPARE_ROWS = 1
        # from handsontable defaults
        # https://docs.handsontable.com/0.24.1/demo-stretching.html
        DEFAULT_ROW_HEIGHT = 23
        DEFAULT_COL_WIDTH = 47

        # useful to identify which handsontable instance to update
        scope.purpose = attr.purpose

        # retrieves data from handsontable object
        _format = (obj) ->
          data = obj.getData()
          header = obj.getColHeader()
          nCols = obj.countCols()
          nRows = obj.countRows()

          table =
            data: data
            header: header
            nCols: nCols
            nRows: nRows

        scope.update = (evt, arg) ->
          console.log 'handsontable: update called'

          DATA_TYPES = eventManager.getSupportedDataTypes()

          currHeight = elem[0].offsetHeight
          currWidth = elem[0].offsetWidth

          #check if data is in the right format
  #        if arg? and typeof arg.data is 'object' and typeof arg.columns is 'object'
          if arg? and typeof arg.data is 'object' and arg.dataType is DATA_TYPES.FLAT
            # TODO: not to pass nested data to ht, but save in db
            obj =
              data: arg.data[1]
  #            startRows: Object.keys(arg.data[1]).length
  #            startCols: arg.columns.length
              colHeaders: arg.columnHeader
  #            columns: arg.columns
              minSpareRows: N_SPARE_ROWS
              minSpareCols: N_SPARE_COLS
              allowInsertRow: true
              allowInsertColumn: true
              stretchH: "all"
          else if arg.default is true
            obj =
              data: [
                ['Copy', 'paste', 'your', 'data', 'here']
              ]
              colHeaders: true
              minSpareRows: N_SPARE_ROWS
              minSpareCols: N_SPARE_COLS
              allowInsertRow: true
              allowInsertColumn: true
              rowHeaders: false
          else
            $exceptionHandler
              message: 'handsontable configuration is missing'

          obj['change'] = true
          obj['afterChange'] = (change, source) ->
            # saving data to be globally accessible.
            #  only place from where data is saved before DB: inputCache.
            #  onSave, data is picked up from inputCache.
            if source is 'loadData' or 'paste'
              ht = $(this)[0]
              tableData = _format ht
              dataFrame = dataAdaptor.toDataFrame tableData, N_SPARE_COLS, N_SPARE_ROWS
              inputCache.set dataFrame
              ht.updateSettings
                height: Math.max currHeight, ht.countRows() * DEFAULT_ROW_HEIGHT
                width: Math.max currWidth, ht.countCols() * DEFAULT_COL_WIDTH
            else
              inputCache.set source

          try
            # hook for pushing data changes to handsontable
            # TODO: get rid of tight coupling :-/
            ht = $(elem).handsontable obj
            window['inputCache'] = inputCache.ht = $(ht[0]).data('handsontable')
          catch e
            $exceptionHandler e

        # subscribing to handsontable update
        scope.$on attr.purpose + ':load data to handsontable', scope.update
        console.log 'handsontable directive linked'
]
