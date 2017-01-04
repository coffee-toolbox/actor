# Actor
Actor model in Coffeescript

## Actor as a dictionary

`Actor` has following method for dictionary operations:

```coffeescript
# k :: string
# v :: any

# set value of key `k` as `v`
$set: (k, v)-> v

# get value of key `k`
$get: (k)-> v | undefined

# delete key `k`
$delete: (k) -> true

# list of all keys
$keys: -> [k] | []

# list of value of all keys
$values: -> [v] | []
```

## Actor as a message processing hub

`Actor` has following method for Sync call and Async Call:

`$start: (reg)-> ignored`

Start the Actor by waiting on async messages.

`reg.receive` is for registration of async message handlers.
A handler should be end by a `@$next()` call to handle next message.
`reg.call` is just for registration of normal sync methods.

```coffeescript
# reg ::
# 	'receive': ReceiveReg
# 	'call': CallReg
# ReceiveReg :: { MsgType: MsgHandler }
# CallReg :: { CallName: CallHandler }
# MsgType :: string
# CallNmae :: string
# MsgHandler :: (from, msg)=> ignored
# 	There should be a `@$next()` in MsgHandler to handle next Message
# CallHandler :: (args...)=> any
```
`$next: -> ignored`

Wait for the next async message and handler it by registered handler.

Usually, there's only one `$next` waiting for message. Two or more are likely
to be a memory leak. There will be a warning for that.

`$call: (name, args...)-> any`

Invoke methods registered with `reg.call` in `$start`

`$send_to: (target, type, value)-> ignored`

Send message to target.
The message would be handled by functions registered with `reg.receive` in
`$start`. The function is asynchronously called once `$next()` is called.

## Other
`$id` used as Logger prefix. Default is class name.
`logger` a Logger with prefix `$id`

# Example Usage:

```coffeescript
{Actor} = require '@coffee-toolbox/actor'

class Adder extends Actor
	constructor: ->
		super
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

asker = new Asker()
adder = new Adder()
asker.$send_to adder, 'async_add',
	a: 3
	b: 5
asker.logger.log adder.$call 'sync_add', 4, 6

# Asker => Adder:
#   async_add
#  : { a: 3, b: 5 }
# Asker 10
# Adder <= Asker:
#   async_add
#  : { a: 3, b: 5 }
# Adder => Asker:
#   answer
#  : 8
# Asker <= Adder:
#   answer
#  : 8
# Asker 8
```
