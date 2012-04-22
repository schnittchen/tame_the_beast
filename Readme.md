# TameTheBeast

## What?

TameTheBeast lets you define the creation of components of your application in a central container.
It is inspired by [this blog post](http://onestepback.org/index.cgi/Tech/Ruby/DependencyInjectionInRuby.rdoc) by
Jim Weirich.

## Why?

A central singleton is eventually inevitable for any application, but if you are like me, it tends to
suck up and swallow functionality that really should be separate from each other. You end up with one big blob
of unmanageable spaghetti since everything is tightly coupled.

Dependency injection is a way out that has proven to be effective in OOP. TameTheBeast aims at giving some nice lightweight sugar above it. (What it actually does is it patronizes you. Have been warned.)

## Show me code!

    container = TameTheBease.new

    container.register(:app_state) do
      { :running => false, :initializing => true }
    end

    container.register(:splash_window, :using => :app_state) do |h|
      SplashWindow.new(h.app_state)
    end
    
    # ...many more components registered here...
    
    resolution = container.resolve(:for => [:splash_window, ...])
    # => { :splash_window => <SplashWindow...> }

So this is the pattern:

* register your components with a slot (which must be a Symbol) and a constructing block
* the block argument gives you access to your dependencies. I call it the **inject hash**.
* declare your dependencies with the :using option, they will appear in the inject hash
* resolve for the components you need to kick your application up

Explicitly declaring your dependencies in this way _really_ helps in refactoring later!

## Features

### Sugar

#### Hash access

Access the resolution and the inject hashes by `[]` or by name.
That means you can say `resolution[:app_state]` as well as `resolution.app_state`. Same for the inject hashes.

#### Control what's getting resolved for

There are three ways to accomplish that:

    container.resolve_for :configuration, :app_state
    # or, at register time
    container.register(:printer_dialog, :resolve => true)
    # or, at resolution time
    container.resolve(:for => [:configuration, :app_state])

All components mentioned in any of the three ways will get resolved for. Call `resolve_for` as often as you like.

#### Slim dependency notation

Slots have to be symbols, but when declaring dependencies or resolving, 
you can reference them as strings like this:

    container.register(:foo, :using => %w{bar baz}) { ... }

    container.resolve_for %w{foo bar baz}

#### Stubbing

Is this really sugar? Not sure. Anyway, you can leave off the block on `register`,
and the component will be initialized as a stub. This way you can play around with the effects of
refactorings on dependencies to some extent without having to go too deep.

The stub will yell at you when you try to use it.

### Is my container complete? Do I have a dependency loop?

Just ask.

    container.complete?
    container.free_of_loops?

If there are dependency loops, `resolve` will raise an exception.

### Give me a dependency graph, please.

Nothing fancy yet, but you can do

    container.render_dependencies(:format => :hash)
    # => { :splash_window => [:app_state], ... }

Let me know if you know of a way to visualize this easily!

### Post-injection as a last resort

I have not yet completely made up my mind about this yet, but it seems like it is not always possible to avoid circular dependencies. You can break them up and post-inject like this:

    container.register(:component) do |h|
      ...
    end.post_inject_into { |h| h.parent = h.root_something } # or similar foo

The post injection block will be called right before the resolution is returned. It is passed
the resolution.

If you think you need this feature, _really_ think hard if you cannot find a way around (I believe there usually is). Using this feature should actually give you some pain, but I could not find a reliable way to implement this.

### Multi-phase initialization / Injection of pre-existing objects

There is no such thing as incremental resolution, you cannot use a component directly while still registering construction of others.

However, you can break up the registration into multiple phases and simply inject the result of prior `resolve` runs:

    container.inject(resolution_from_the_past)

If you have existing objects, you can actually keep them in a hash and inject them in this way. There is nothing special about using a `resolve` result here!

## License

Released under the MIT License.  See the [LICENSE](https://github.com/schnittchen/tame_the_beast/blob/master/LICENSE.md) file for further details.
