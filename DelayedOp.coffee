###
DelayedOp
Version 0.1.3
###

DelayedOpPrivate =
	pending_ops: {} #operations that haven't fired yet
	next_id: 0
	addOp: (op) -> @pending_ops[op.id = @next_id++] = op #add to the operations table
	removeOp: (op) -> delete @pending_ops[op.id] #remove from the operations table
	ready_tag: '<ready() not called>' #private tag for ready
	defaultTag: '<No Tag>'
	defaultName: '<Unnamed Operation>'

class DelayedOp
	###
	constructor:
		name: A name for this operation, useful for debugging (optional, but must be string if specified)
		log_delay: A delay, in seconds, before the operation will log its unbalanced tags (optional)
	###
	constructor: (@name = DelayedOpPrivate.defaultName, @log_delay) ->
		#If name is a number, that means the name was omitted but log_delay was specified
		if @name.constructor is Number
			@log_delay = @name
			@name = DelayedOpPrivate.defaultName
		@total = 0
		@tags = {}
		DelayedOpPrivate.addOp @
		@wait DelayedOpPrivate.ready_tag

	###
	wait: Wait for a balancing call to 'ok' before the operation can fire
		tag: A string to tag this wait with. If you use the simple call style, the same tag must be 
			passed to the `ok` method call that balances this wait. (optional)
		callback: Optional callback that is called immediately and passed a single-use 'ok' function curried
			with 'tag'

		return:
			A single-use 'ok' function, curried with 'tag'
	###
	wait: (tag = DelayedOpPrivate.defaultTag, callback) ->
		#handle ommitted tag argument if callback passed
		[tag, callback] = ['', tag] if typeof tag == 'function'
		#put the tag in the tag bag
		@tags[tag] ?= 0
		@tags[tag]++
		@total++

		onceOK = => #create OK function that can only be called once
			@ok tag #pass tag to the callback
			onceOK = -> throw new DelayedOpError tag #rewrite the ok function 
		
		#Pass ok function caller to the callback
		callback? -> onceOK()
		return -> onceOK() #return ok function caller
	
	###
	ok: Balance a call to 'wait'
		tag: The string passed to 'wait', if any
	###
	ok: (tag = DelayedOpPrivate.defaultTag) ->
		#Decrement tag count
		@tags[tag] ?= 0
		@tags[tag]--
		#Check for too many calls with this tag
		throw new DelayedOpError tag if @tags[tag] < 0 
		@fire() unless --@total #fire if we hit zero

	###
	ready: Finalize the operation
		cb: the callback to attach
	###
	ready: (@cb) =>
		#Set timeout to log unbalanced tags
		if @log_delay?
			logForTimeout = => console.log 'DelayedOp Timeout: ' + @getDebugInfo() unless @hasFired
			@log_timeout = setTimeout logForTimeout, @log_delay*1000
		@ok DelayedOpPrivate.ready_tag

	#Private instance members and methods
	fire: ->
		clearTimeout @log_timeout if @log_timeout?
		@hasFired = true
		@cb()
		DelayedOpPrivate.removeOp @
	
	#Get debug string info consisting of this operation's name and the number of opens for its unbalanced tags
	#	(formatted for printing)
	getDebugInfo: => "#{@name}\n" + ("    #{tag}: #{count}" for own tag, count of @tags when count).join '\n'

	###
	logPending: (class method)
		Calls 'logInfo' an all unfired ops
	###
	@logPending: ->
		console.log '\n' + (op.getDebugInfo() for own id, op of DelayedOpPrivate.pending_ops).join '\n\n'


class DelayedOpError extends Error
	constructor: (tag) -> @message = "ok() callback called too many times (tag: '#{tag}') "
	name: 'DelayedOpError'

root = exports ? this
root.DelayedOp = DelayedOp
