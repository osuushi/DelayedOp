####Table of Contents
[        What is this for?](#rm-what)<br/>
[        Getting the library](#rm-getting)<br/>
[        Usage](#rm-usage)<br/>
[                 Creating the op object](#rm-creating)<br/>
[                 Adding operations](#rm-adding)<br/>
[                         Simple Style](#rm-simple)<br/>
[                         Callback Style](#rm-callback)<br/>
[                         Return Style](#rm-return)<br/>
[                 Tags](#rm-tags)<br/>
[                 Finishing Up](#rm-finishing)<br/>
[                 Debugging](#rm-debugging)<br/>


<a name = "rm-what" />
# What is this for?

When working with asynchronous functions (e.g. AJAX), it is often the case that you want to make several 
asynchronous calls at once, and then have some callback execute once **all** of those asynchronous operations 
have finished.

DelayedOp is a micro-library written in CoffeeScript that simplifies this process while making it easy to debug
when things go wrong.

Take a look at demo.coffee if you want to jump right in, or read on for a more detailed discussion.

<a name = "rm-getting" />
#Getting the library

You can compile from the original DelayedOp.coffee source, or
[download](https://github.com/downloads/osuushi/DelayedOp/DelayedOp-0.1.2.min.js) the latest compiled and 
minified version of the library.

<a name = "rm-usage" />
#Usage

<a name = "rm-creating" />
##Creating the op object

To begin with, you simply create a DelayedOp (you can give it an optional name for debugging purposes)

```js
/* JavaScript */
var op = new DelayedOp('My Operation');
```

```coffee
### CoffeeScript ###
op = new DelayedOp 'My Operation'
```

<a name = "rm-adding" />
##Adding operations
There are three different styles for using this new object, and each style can be either tagged or untagged.

<a name = "rm-simple" />
###Simple Style

```js
/* JavaScript */
op.wait();
someAsyncFunction(function() {
	op.ok();
});
```

```coffee
### CoffeeScript ###
op.wait()
someAsyncFunction ->
	### Do stuff ###
	op.ok()
```

This style is the easiest to use. You call `op.wait()` before the async call, and then in the async function's
callback, you call `op.ok()`.

For simple use cases, this call style should be fine, but it will not help you much if you make an error. If
`op.ok()` is called too many times, it will throw an exception, but you'll have to hunt down the extra call
yourself.

Wouldn't it be nice if DelayedOp could do some tracking for us in case we make a mistake? Well...

<a name = "rm-callback" />
###Callback Style

```js
/* JavaScript */
op.wait(function(ok) {
	someAsyncFunction(function() {
		/* Do stuff */
		ok();
	});
}
```

```coffee
### CoffeeScript ###
op.wait (ok) -> someAsyncFunction ->
	### Do stuff ###
	ok()
```

In this style, we pass a callback to `wait` which accepts an `ok` function as its parameter. The `ok` function 
DelayedOp passes to the callback will throw an exception if it's called more than once. If you make a 
programming error, you'll know *specifically* where the problem is.

The only disadvantage to this style is that it adds a bit more boilerplate, especially in plain JavaScript.

<a name = "rm-return" />
###Return Style

```js
/* JavaScript */
var ok = op.wait();
someAsyncFunction(function() {
	/* Do stuff */
	ok();
})
```

```coffee
### CoffeeScript ###
ok = op.wait()
someAsyncFunction ->
	### Do stuff ###
	ok()
```

The `wait` function returns a special `ok` function (the same one passed to the callback in the callback 
style), which can only be called once (it throws an error if you call it twice). One particularly useful 
pattern using this style when no additional processing is needed in the async callback is like so:

```js
/* JavaScript */
someAsyncFunction(op.wait());
```

```coffee
### CoffeeScript ###
someAsyncFunction op.wait()
```

In many cases, however, you will find that this style requires you to pollute the current scope with
variables to hold your `ok` functions. In such cases, the callback style is usually more appropriate.

<a name = "rm-tags" />
##Tags

You can pass a string "tag" to the `wait` method. This aids in tracking down errors if `ok` calls outweigh 
your `wait` calls, and it can also help you to find the inverse problem (see "[Debugging](#rm-debugging)" 
below).

To attach a tag, pass it as the first parameter to `wait`, and pass the same tag to the corresponding call to 
`ok`, like so:

```js
/* JavaScript */
op.wait('SomeTag');
someAsyncFunction(function() {
	op.ok('SomeTag');
});
```

```coffee
### CoffeeScript ###
op.wait 'SomeTag'
someAsyncFunction ->
	### Do stuff ###
	op.ok 'SomeTag'
```

If your calls to `ok` exceed those to `wait` for any given tag, an error will be thrown, giving you a better 
idea of where the problem is.

You can also pass tags to the other call styles:


```js
/* JavaScript */

// Callback style
op.wait('SomeTag', function(ok) {
	someAsyncFunction(function() {
		/* Do stuff */
		ok(); 
	});
}

// Return style
var ok = op.wait('AnotherTag');
someAsyncFunction(function() {
	/* Do stuff */
	ok();
})
```

```coffee
### CoffeeScript ###

# Callback style
op.wait 'SomeTag', (ok) -> someAsyncFunction ->
	### Do stuff ###
	ok()

# Return style
ok = op.wait 'AnotherTag'
someAsyncFunction ->
	### Do stuff ###
	ok()
```

Note that for the callback and return styles, you don't have to pass the tag to the `ok` function. When 
creating the single-use `ok` function, DelayedOp automatically curries the tag parameter for you.

<a name = "rm-finishing" />
##Finishing up

Once you've set up the operation, you use the `ready` method to give it a callback. This callback will run
once all `wait` calls have been balanced by `ok` calls

```js
/* JavaScript */
op.ready(function(){
	alert('All operations are complete.');
});
```

```coffee
### CoffeeScript ###
op.ready ->	alert 'All operations are complete.'
```

<a name = "rm-debugging" />
##Debugging

DelayedOp throws informative exceptions if you have too many `ok` calls, or too few `wait`s, but what if you 
forget to call `ok` or accidentally insert a duplicate `wait`? How do you find out why your operation isn't
firing?

In that case, you can use the debugging method:

```js
DelayedOp.logPending()
```

This will log in the console the names of all unfired operations along with their unclosed tags.

