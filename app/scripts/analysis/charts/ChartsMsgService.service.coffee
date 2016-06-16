'use strict'

ModuleMessageService = require 'scripts/BaseClasses/ModuleMessageService.coffee'

module.exports = class ChartsMsgService extends ModuleMessageService
  @msgList:
    outgoing: ['get table']
    incoming: ['take table']
    scope: ['charts']
