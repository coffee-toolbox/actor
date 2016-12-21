# actor
Actor model in Coffeescript


```
    $start: (reg)->
    reg ::
    	'receive': ReceiveReg
    	'call': CallReg
    ReceiveReg :: { MsgType: MsgHandler }
    CallReg :: { CallName: CallHandler }
    MsgType :: string
    CallNmae :: string
    MsgHandler :: (from, msg)=> ignored
    	There should be a `@$next()` in MsgHandler to handle next Message
    CallHandler :: (args...)=> any
```
