{Actor} = require('./Actor.coffee')

class Adder extends Actor
	constructor: ->
		super {debug: true}
		@$start
			call:
				sync_add: @add_sync
			receive:
				async_add: @add_async

	add_sync: (a, b)=>
		a + b

	add_async: (from, msg)=>
		setTimeout =>
			@$send_to from, 'answer',  msg.a + msg.b
			# @$next() # to handle next msg after answering
			@$terminate()
		, 500
		@$next() # to handle next msg immediately

class Asker extends Actor
	constructor: ->
		super
		@$start
			receive:
				answer: (from, v)=>
					@logger.log v
					@$next()
				DOWN: (from, v)=>
					@logger.log 'terminating:', v
					@$terminate()

asker = new Asker()
adder = new Adder()
ref = asker.$monitor adder
asker.$send_to adder, 'async_add',
	a: 3
	b: 5
# asker.$unmonitor ref # to unmonitor
asker.logger.log adder.$call 'sync_add', 4, 6
