{Logger} = require('@coffee-toolbox/logger')
"use strict"
class Dict
	constructor: ->
		@$dictionary = {}

	$set: (k, v)->
		@$dictionary[k] = v

	$get: (k)->
		if k?
			@$dictionary[k]

	$keys: ->
		Object.keys @$dictionary

	$values: ->
		Object.keys @$dictionary
		.map (k)=>
			@$dictionary[k]

	$delete: (k)->
		if @$dictionary[k]?
			delete @$dictionary[k]

class Actor extends Dict
	constructor: ->
		super
		@$id = @constructor.name
		@logger = new Logger @$id
		@$msg_handlers = null
		@$call_handlers = null
		@$mail_box = []
		@$waiting = []

	# reg ::
	#	'receive': ReceiveReg
	#	'call': CallReg
	# ReceiveReg :: { MsgType: MsgHandler }
	# CallReg :: { CallName: CallHandler }
	# MsgType :: string
	# CallNmae :: string
	# MsgHandler :: (from, msg)=> ignored
	#   There should be a `@$next()` in MsgHandler to handle next Message
	# CallHandler :: (args...)=> any
	$start: (reg)->
		reg.receive ?= {}
		reg.receive = Object.freeze reg.receive

		Object.keys(reg.receive).map (k)->
			reg.receive[k]
		.forEach (msg_handler)=>
			unless msg_handler instanceof Function
				@logger.error 'invalid receive_reg', msg_handler
		@$msg_handlers = reg.receive

		reg.call ?= {}
		reg.call = Object.freeze reg.call
		Object.keys(reg.call).map (k)->
			reg.call[k]
		.forEach (call_handler)=>
			unless call_handler instanceof Function
				@logger.error 'invalid call_reg', call_handler

		@$call_handlers = reg.call
		@$next()

	$next: ->
		f = @$mail_box.shift()
		if f?
			Promise.resolve().then f
		else
			@$waiting.push =>
				Promise.resolve().then @$mail_box.shift()
			if @$waiting.length > 1
				@logger.warn 'repeated $@next()\n
				A memory leak? Queue length:', @$waiting.length

	$call: (name, args...)->
		@logger.assert @$call_handlers[name]?, name, 'not registered'
		@$call_handlers[name] args...

	$send_to: (t, type, value)->
		@logger.assert t instanceof Actor
		@logger.assert type?
		@logger.info "=> #{t.constructor.name}:\n  #{type}\n :", value
		t.$mail_box.push =>
			t.logger.assert t.$msg_handlers[type]?, type, 'not registered'
			t.$msg_handlers[type] this, value
		if t.$waiting.length > 0
			t.$waiting.shift()()

module.exports =
	Actor: Actor
