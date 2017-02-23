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
# CallNmae :: string
# MsgHandler :: (from, msg)=> ignored
# 	There should be a `@$next()` in MsgHandler to handle next Message
# CallHandler :: (args...)=> any
```
`$next: -> ignored`

Wait for the next async message and handler it by registered handler.

Usually, there's only one `$next` waiting for message. Two or more is likely
to be a memory leak. There will be a error reporting that.

`$call: (name, args...)-> any`

Invoke methods registered with `reg.call` in `$start`

`$send_to: (target, type, value)-> ignored`

Send message to target.
The message would be handled by functions registered with `reg.receive` in
`$start`. The function is asynchronously called once `$next()` is called.

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

###
Asker 10
Adder <= Asker:
  async_add
 : { a: 3, b: 5 }
Adder => Asker:
  answer
 : 8
Asker 8
###
```
