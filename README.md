# Actor
Actor model in Coffeescript

### NOTE
Do NOT download from npm!

Just add the dependency that use https git repo url as a version.

    "@coffee-toolbox/actor": "https://github.com/coffee-toolbox/actor.git"

npm is evil that it limit the publish of more than one project.
And its restriction on version number is terrible for fast development that
require local reference. (npm link sucks!)
[why npm link sucks](https://github.com/webpack/webpack/issues/554)

It ruined my productivity for a whole three days!

For any one who values his life, please be away from npm.

----

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

### Start an actor
`$start: (reg)-> ignored`

Start the Actor by waiting on async messages.

`reg.receive` is for registration of async message handlers.
A handler should be end by a `@$next()` call to handle next message.
Fail to do so will result in a unresponsive actor. The development
version reports the sending and receving of the message for debugging.
`reg.call` is just for registration of normal sync methods.

```coffeescript
# reg ::
# 	'receive': ReceiveReg
# 	'call': CallReg
# ReceiveReg :: { MsgType: MsgHandler }
# CallReg :: { CallName: CallHandler }
# MsgType :: string
# CallName :: string
# MsgHandler :: (from, msg)=> ignored
# 	There should be a `@$next()` in MsgHandler to handle next Message
# CallHandler :: (args...)=> any
```
### Receive message:
`$next: -> ignored`

Wait for the next async message and handler it by registered handler.

Usually, there's only one `$next` waiting for message. Two or more is likely
to be a memory leak. There will be a error reporting that.

### Calling
`$call: (name, args...)-> any`

Invoke methods registered with `reg.call` in `$start`

### Send message
`$send_to: (target, type, value)-> ignored`

The message would be handled by functions registered with `reg.receive` in
`$start`. The function is asynchronously called once `$next()` is called.

### Monitor the target.
`$monitor: (target)-> ref`

When `target` is terminated, a message of
    DOWN, reason
will be send from target.
The `ref` is used to unmonitor.

### Unmonitor by ref
`$unmonitor: (ref)-> ignored`
Clean out the monitor

## Other
A `config` object can be passed to the Actor's constructor.
`config.id` is used as suffix of `@$id`.
`config.debug` is a boolean to enable debug printing.
`@$id` used as Logger prefix. Default is `@constructor.name + config.id`.
`@logger` a Logger with prefix `$id`.

# Example Usage:

```coffeescript
{Actor} = require '@coffee-toolbox/actor'

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

###
Asker 10
Adder <= Asker:
  async_add
 : { a: 3, b: 5 }
Adder => Asker:
  answer
 : 8
Adder => Asker:
  DOWN
 : normal
Asker 8
Asker terminating: normal
###
```
