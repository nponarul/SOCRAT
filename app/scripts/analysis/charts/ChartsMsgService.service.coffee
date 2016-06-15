'use strict'

ModuleMessageService = require 'scripts/BaseClasses/ModuleMessageService.coffee'

module.exports = class ChartsMsgService extends ModuleMessageService
  @msgList:
    outgoing: ['save data']
    incoming: ['get data']
    scope: ['charts']
