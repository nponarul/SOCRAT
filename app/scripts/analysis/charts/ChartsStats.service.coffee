'use strict'

BaseService = require 'scripts/BaseClasses/BaseService.coffee'

module.exports = class ChartsStats extends BaseService

  initialize: ->

  getMedian: (arr) ->
    for a in arr
      a = parseFloat a
    arr.sort  (a,b) -> return a - b
    half = Math.floor arr.length/2
    if arr.length % 2
      return arr[half]
    else
      return (arr[half-1] + arr[half]) / 2.0

  getMean: (arr) ->
    sum = 0
    sum += parseFloat a for a in arr
    return (sum/arr.length).toFixed 2

  getCount: (arr) ->
    return arr.length

  getStDev: (arr) ->
    x_bar = @getMean(arr)
    n = @getCount(arr)
    num = 0
    for i in arr
      num += (i - x_bar)^2
    num = num/n
    return Math.sqrt(num)

#  getStDev: (arr) ->
#    variance = getVar(arr)
#    return Math.sqrt(variance)

#    getQ1: (arr) ->
#      median = getM
