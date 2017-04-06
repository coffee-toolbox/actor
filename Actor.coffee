'use strict'
{Logger} = require('@coffee-toolbox/logger')
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
		delete @$dictionary[k]

class Actor extends Dict
	constructor: (config)->
		super
		@$id = if config?.id
			@constructor.name + ' ' + config.id
		else
			@constructor.name
		@logger = if config?.debug
			new Logger @$id
		else
			new Logger @$id, Logger.ASSERT
		@$msg_handlers = null
		@$call_handlers = null
		@$mail_box = []
		@$monitors = new Map()
		@$monitoring = new Map()
		@$waited_next = null

	# when `t` is down, `this` receive a msg:
	#     DOWN, {ref: ref, reason: reason}
	# from `t`
	$monitor: (t)->
		ref = Symbol("#{@$id} monitoring #{t.$id}")
		if not t.$monitors?
			@logger.warn 'monitoring a terminated actor'
			null
		else if not @$monitors?
			@logger.warn 'a terminated actor monitoring'
			null
		else
			t.$monitors.set ref, this
			@$monitoring.set ref, t
			ref

	$unmonitor: (ref)->
		if @$monitoring?
			t = @$monitoring.get ref
			if t?
				@logger.assert t instanceof Actor
				@$monitoring.delete ref
				if t.$monitors?
					t.$monitors.delete ref

	# reg ::
	#	'receive': ReceiveReg
	#	'call': CallReg
	# ReceiveReg :: { MsgType: MsgHandler }
	# CallReg :: { CallName: CallHandler }
	# MsgType :: string
	# CallName :: string
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
		read_mail = =>
			f = @$mail_box.shift()
			Promise.resolve().then f
		if @$mail_box.length > 0
			read_mail()
		else if @$waited_next?
			@logger.error 'repeated $next()!'
		else
			@$waited_next = ->
				read_mail()

	$call: (name, args...)->
		@logger.assert @$call_handlers[name]?, name, 'not registered'
		@$call_handlers[name] args...

	$send_to: (t, type, value)->
		@logger.assert type?, 'msg type is not defined'
		@logger.debug "=> #{t.$id}:\n  #{type}\n :", value
		if t.$mail_box?
			t.$mail_box.push =>
				t.logger.assert t.$msg_handlers[type]?, type, 'not registered'
				t.logger.debug "<= #{@$id}:\n  #{type}\n :", value
				t.$msg_handlers[type] this, value
		else
			@logger.warn 'sending to a terminated actor', type, value

		if t.$waited_next?
			f = t.$waited_next
			t.$waited_next = null
			f()

	$terminate: (reason)->
		reason ?= 'normal'
		# flush all messages
		@$waited_next = null
		@$mail_box = null
		# cleanup all handles
		@$msg_handlers = null
		@$call_handlers = null
		# sending out messages
		@$monitoring.forEach (t, ref)=>
			@$unmonitor ref
		@$monitors.forEach (t, ref)=>
			@$send_to t, 'DOWN', {ref: ref, reason: reason}
		@$monitors = null


module.exports =
	Actor: Actor
