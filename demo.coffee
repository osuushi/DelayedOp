###
Demo script for the different styles
###

#A useless asynchronous function for demo purposes
someAsyncCall = (cb) -> setTimeout cb, 500 + 500*Math.random()

op = new DelayedOp 'Demo'


###
The simplest call style
If your waits and oks are imbalanced, this style is not helpful in finding the 
problem.
###
op.wait()
someAsyncCall ->
	console.log 'Simple style'
	op.ok()

###
Tagged call style
If your calls are unbalanced, you will at least know which tag it was.
###
op.wait 'tag'
someAsyncCall ->
	console.log 'Tagged style'
	op.ok 'tag'

###
Callback style
The callback is passed its very own 'ok' function which throws an exception if it is called twice.
###
op.wait (ok) -> someAsyncCall ->
	console.log 'Callback style'
	ok()


###
Tagged callback style
Just a tad more information for debugging 
###
op.wait 'tag', (ok) -> someAsyncCall ->
	console.log 'Tagged callback style'
	ok() #you don't have to pass the tag in this style


op.ready -> alert 'All operations have completed.'