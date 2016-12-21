# actor
Actor model in Coffeescript

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

`Actor` has following method for Sync call and Async Call:

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
# Start the Actor by waiting on async messages.
# `reg.receive` is for registration of async message handlers.
# A handler should be end by a @$next() call to handle next message.
# `reg.call` is just for registration of normal sync methods.
$start: (reg)-> ignored
# Wait for the next async message and handler it by registered handler.
# Usually, there's only one `$next` waiting for message. Two or more are likely
# to be a memory leak. There will be a warning for that.
$next: -> ignored
```
