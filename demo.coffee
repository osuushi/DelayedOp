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
Simple call style with tag
If your calls are unbalanced, you will at least know which tag it was.
###
op.wait 'tag'
someAsyncCall ->
	console.log 'Tagged simple style'
	op.ok 'tag'

###
Callback style
The callback is passed its very own 'ok' function which throws an exception if it is called twice.
###
op.wait (ok) -> someAsyncCall ->
	console.log 'Callback style'
	ok()


###
Callback style with tag
Just a tad more information for debugging 
###
op.wait 'tag', (ok) -> someAsyncCall ->
	console.log 'Tagged callback style'
	ok() #you don't have to pass the tag in this style



###
Return style
###
ok = op.wait()
someAsyncCall ->
	console.log 'Return style'
	ok()


###
Return style with tag
###
ok2 = op.wait 'tag'
someAsyncCall ->
	console.log 'Tagged return style'
	ok2()



op.ready -> alert 'All operations have completed.'