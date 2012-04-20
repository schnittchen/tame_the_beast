# TameTheBeast

## What?

TameTheBeast lets you define the creation of components of your application in a central container.
It is inspired by  [this blog post](http://onestepback.org/index.cgi/Tech/Ruby/DependencyInjectionInRuby.rdoc) by
Jim Weirich.

## Why?

A central singleton is eventually inevitable for any application, but if you are like me, it tends to
suck up and swallow functionality that really should be separate from each other. You end up with one big blob
of unmanageable spaghetti since everything is tightly coupled.

Dependency injection is a way out that has proven to be effective in OOP. TameTheBeast aims at giving some nice yet light sugar above it. (What it actually does is it patronizes you. Have been warned.)

## Show me code!

    container = TameTheBease.new

    container.register(:app_state) { :running => false, :initializing => true }
    container.register(:splash_window, :using => :app_state) do |h|
      SplashWindow.new(c.app_state)
    end
    
    # ...many more components registered here...
    
    resolution = container.resolve(:for => [:splash_window, ...])
    # => { :splash_window => <SplashWindow...> }

So this is the pattern:

* register your components with a slot and a constructing block
* the block argument gives you access to your dependencies. I call it the **inject hash**.
* declare your dependencies with the :using option, they will appear in the inject hash

Explicitly declaring your dependencies _really_ helps in refactoring later!

## Features

### Sugar

Access the resolution and the inject hashes by `:[]` or by name That means you can say `resolution[:app_state]` as well as `resolution.app_state`. Same for the inject hashes.



### Is my container complete? Do I have a dependency loop?

Just ask.

    container.complete?
    container.free_of_loops?

If there are dependency loops, `resolve` will raise an exception.

### Give me a graph, please.

Nothing fancy yet, but you can do

    container.render_dependencies(:format => :hash)
    # => { :splash_window => [:app_state], ... }

### Post-injection as a last resort

I have not yet completely made up my mind about this yet, but it seems like it is not always possible to avoid circular dependencies. You can break them up and post-inject like this:

    TBD example here

If you think you need this feature, _really_ think hard if you cannot find a way around (I believe there usually is). Using this feature should actually give you some pain.

### Injection of already existing stuff, multi-phase initialization

TBD
