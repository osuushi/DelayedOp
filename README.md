# What is this for?

When working with asynchronous functions (e.g. AJAX), it is often the case that you want to make several 
asynchronous calls at once, and then have some callback execute once **all** of those asynchronous operations 
have finished.

DelayedOp is a micro-library written in CoffeeScript that simplifies this process while making it easy to debug
when things go wrong.

Take a look at demo.coffee if you want to jump right in, or read on for a more detailed discussion.

##Getting the library

You can compile from the original DelayedOp.coffee source, or
[download the minified version of the library](https://github.com/downloads/osuushi/DelayedOp/DelayedOp.min.js).



##Setting up the op object

To begin with, you simply create a DelayedOp (you can give it an optional name for debugging purposes)

<small>*(JavaScript)*</small>

	var op = new DelayedOp('My Operation');

<small>*(CoffeeScript)*</small>

	op = new DelayedOp 'My Operation'



##Adding operations
There are four different styles for using this new object:

###Simple Style

<small>*(JavaScript)*</small>

	op.wait();
	someAsyncFunction(function() {
		op.ok();
	});

<small>*(CoffeeScript)*</small>

	op.wait()
	someAsyncFunction -> op.ok()

This style is the easiest to use. You call `op.wait()` before the async call, and then in the async function's
callback, you call `op.ok()`.

For simple use cases, this call style should be fine, but it will not help you much if you make an error. If
`op.ok()` is called too many times, it will throw an exception, but you'll have to hunt down the extra call
yourself.

Wouldn't it be nice if the `op` object could do some tracking for us in case we make a mistake? Well...

###Tagged Style

<small>*(JavaScript)*</small>

	op.wait('tag');
	someAsyncFunction(function() {
		op.ok('tag');
	});

<small>*(CoffeeScript)*</small>

	op.wait 'tag'
	someAsyncFunction -> op.ok 'tag'

This is very similar to the first style, but you pass the same string tag to both `wait` and `ok`. DelayedOp 
tracks these tags individually, so if your calls are unbalanced, you'll know which tag caused the problem.

But what if you can't use a distinct tag for every call? What if you're calling in a loop, for example?
In that case...

###Callback Style

<small>*(JavaScript)*</small>

	op.wait(function(ok) {
		someAsyncFunction(function() {
			ok();
		});
	}

<small>*(CoffeeScript)*</small>

	op.wait (ok) -> someAsyncFunction ->
		ok()

In this style, we pass a callback to `wait` which accepts an `ok` function as its parameter. The `ok` function 
DelayedOp passes to the callback will throw an exception if it's called more than once. If you make a 
programming error, you'll know *specifically* where the problem is.

The only disadvantage to this style is that it adds a bit more boilerplate, especially in plain JavaScript.

Finally, there's...

###Tagged Callback Style

<small>*(JavaScript)*</small>

	op.wait('tag', function(ok) {
		someAsyncFunction(function() {
			ok();
		});
	}

<small>*(CoffeeScript)*</small>

	op.wait 'tag', (ok) -> someAsyncFunction ->
		ok()

This is exactly like the callback style, but you also provide a tag string. Note that in this style, you do 
not have to pass the tag to the passed `ok` function.

##Finishing up

Once you've set up the operation, you use the `ready()` method to give it a callback. This callback will run
once all `wait` calls have been balanced by `ok` calls

<small>*(JavaScript)*</small>

	op.ready(function(){
		alert('All operations are complete.');
	});

<small>*(CoffeeScript)*</small>

	op.ready ->
		alert 'All operations are complete.'

###Debugging

DelayedOp provides informative errors if you have too many `ok` calls, or too few `wait`s, but what if you 
forget to call `ok` or accidentally insert a duplicate `wait`? How do you find out why your operation isn't
firing?

In that case, you can use the debugging method:

	DelayedOp.logPending()

This will log in the console the names of all unfired operations along with their unclosed tags.