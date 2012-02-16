###
	DelayedOp
	Version 0.1.1
###
class DelayedOp
	###
	constructor:
		name: A name for this operation, useful for debugging (optional)
	###
	constructor: (@name = '<Unnamed Operation>') ->
		@total = 0
		@tags = {}
		DelayedOp.addOp @
		@wait DelayedOp.ready_tag

	###
	wait: Wait for a balancing call to 'ok' before the operation can fire
		tag: A string to tag this wait with. If you use the simple call style, the same tag must be 
			passed to the `ok` method call that balances this wait. (optional)
		callback: Optional callback that is called immediately and passed a single-use 'ok' function curried
			with 'tag'

		return:
			An single-use 'ok' function, curried with 'tag'
	###
	wait: (tag = '', callback) ->
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
	ok: (tag = '') ->
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
	ready: (@cb) -> @ok DelayedOp.ready_tag

	#Private instance members and methods
	fire: ->
		@cb()
		DelayedOp.removeOp @
	
	pendingTags: -> (tag for own tag, count of @tags when count)

	###
	logPending: (class method)
		Show all operations that have not fired, and their pending tags
	###
	@logPending: ->
		output = ''
		for own id, op of @pending_ops
			output += "#{op.name}:\n"
			for tag in op.pendingTags()
				output += "    '#{tag}'\n"
		console.log output


	#Private class members and methods
	@pending_ops: {} #operations that haven't fired yet
	@next_id: 0
	@addOp: (op) -> @pending_ops[op.id = @next_id++] = op #add to the operations table
	@removeOp: (op) -> delete @pending_ops[op.id] #remove from the operations table
	@ready_tag: '__reserved_ready' #private tag for ready

class DelayedOpError extends Error
	constructor: (tag) -> @message = "ok() callback called too many times (tag: '#{tag}') ";
	name: 'DelayedOpError'

root = exports ? this
root.DelayedOp = DelayedOp