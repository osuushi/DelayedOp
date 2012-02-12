###

###
class DelayedOp
	###
	constructor:
		name: A name for this operation, useful for debugging (optional)
		cb: The callback executed when waiting is complete. (required)
	###
	constructor: (@name, @cb) ->
		[@name, @cb] = ['<Anonymous>', @name] unless @cb? # Allow name argument to be ommitted
		@total = 0
		@tags = {}
		DelayedOp.addOp @
		@wait DelayedOp.ready_tag

	###
	wait: Wait for a balancing call to 'ok' before the operation can fire
		tag: A string to tag this wait with. If you do not use the callback technique, the same tag must be 
			passed to the `ok` function that balances this wait. (optional)
		callback: Optional callback that is called immediately and passed an ok function
	###
	wait: (tag = '', callback) ->
		#handle ommitted tag argument if callback passed
		[tag, callback] = ['', tag] if typeof tag == 'function'
		#put the tag in the tag bag
		@tags[tag] ?= 0
		@tags[tag]++
		@total++
		if callback?
			#create the ok function to pass to the callback
			ok = =>
				@ok tag #pass tag to the callback
				ok = -> throw new DelayedOpError tag #rewrite the ok function 
			callback -> ok()
		return
	
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
	###
	ready: -> @ok DelayedOp.ready_tag

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