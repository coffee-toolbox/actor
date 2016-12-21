{Actor} = require('./Actor.coffee')

class TestActor extends Actor
	constructor: ->
		super

	start: ->
		@$start (
			call:
				show: @show
			receive:
				test: @receive
		)

	show: =>
		@logger.log this

	receive: (from, msg)=>
		from
		@$next()

	return: (from, msg)=>
		@$next()

a = new TestActor()
b = new TestActor()

a.start()
b.start()
setTimeout ->
	b.$send_to a, 'test', {something: "later test string"}
, 2000
a.$call 'show'
setTimeout ->
	b.$send_to a, 'test', {something: "earlier test string"}
, 1000

