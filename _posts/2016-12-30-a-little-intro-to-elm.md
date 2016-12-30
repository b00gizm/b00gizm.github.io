---
layout:     post
title:      "A Little Intro to Elm"
author:     Pascal Cremer
date:       2016-12-30 14:49:21
tags:       elm javascript react functional language intro
published:  true
---
![Elm Logo](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/elm-logo.png)

For me, the days between Christmas and NYE are usually the perfect time to browse through the items of my [Todoist](https://todoist.com) and choose something I can finally invest some time in. This year, I've decided to learn something about [Elm](elm-lang.org). Elm has been popping up in my Twitter stream quite regularly throughout the year with people singing nothing but praises of it.

So, what exactly is Elm?

> Elm is a functional language that compiles to JavaScript.

"Yawn, *another* language that compiles to Javascript?" - Yeah, I hear you, but hang on, this one's pretty cool!

> It competes with projects like React as a tool for creating websites and web apps. Elm has a very strong emphasis on simplicity, ease-of-use, and quality tooling.

[React](https://facebook.github.io/react/) (by Facebook) has been my library of choice when it comes to developing user interfaces for web apps. I love quite a lot about it, but, as with almost everything else, it does not guarantee to automatically produce scalable and maintainable front end code. Those, who feel comfortable around React, will quickly discover a lot similarities within the Elm architecture. In addition, you'll also get these things for free:

* A pure and easy to learn functional language
* A strict, but flexible type system
* A module loader
* No runtime errors, no `null`, no `undefined` is not a function
* Javascript interop
* Great tooling (REPL, compiler, package manager etc.)

In the past, I've spent quite a lot time trying to learn [Clojure](https://clojure.org/) / [ClojureScript](https://clojurescript.org/) as pure functional language. I'd say that I can now glance at some Clojure code and tell what it's doing, but I was never confident writing "real" code in it. I've found Elm to be *a lot* more approachable and easier to understand. From what I can tell, it seems to take a lot of clues and concepts from the [Haskell](https://www.haskell.org/) world, while keeping some similarities to Javascript.

Here's a simple example for a function that adds two `Int` values:

```elm
add: Int -> Int -> Int
add x y = 
	x + y
```

The first line is a type annotation which tells you that `add` is a function that takes two `Int` values as arguments and returns an `Int`. The following lines are the actual function definition. Notice that there's no explicit `return` statement, since we're in a pure functional context without any side effects. Here's how you call the function:

```elm
onePlusTwo = add 1 2
```

No parenthesizes, no commas. It might feel a bit odd at first, but you'll get used to it.

Thanks to the annotation, `add` is now strictly typed, which means that something like

```elm
invalid = add 1 "two"
```

will not compile.

## Fun with Elm's Type System

In this introductory posting, we won't produce any (meaningful) HTML output, but only toy around with Elm's type system, which I found quite fantastic, once I got the hang of it. Some of it's syntax might be confusing at first, especially when reading through the [official tutorials](https://guide.elm-lang.org/architecture/user_input/text_fields.html). So I hope the following example will help to clarify things.

If you don't want to [install](https://guide.elm-lang.org/install.html) Elm on your system, you can just follow along in the official [online editor](http://elm-lang.org/try).

Imagine we're developing the next big HTML5 browser game. For the sake of simplicity, let's say our game contains some `GameObjects`, which are of either type `Lifeform` or `Obstacle`. Every `GameObject` has a `Position` (as 2D coordinate), but only `Lifeform`s (like the player or his enemies) do also have a life / energy meter. `Lifeform`s can also move to a new `Position`, while the position of `Obstacle`s is fixed.

{% gist 1bb208110f524496a54e61dd63e323b2 %}[^gist]

Let's dissect it line by line.

The first line is for loading the Html module and exposing just the [`text`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#text) function to our game, which is used to output plain text in the DOM.

The following lines introduce some type aliases, type constructors and union types.

```elm
type alias Energy = Int
type alias Position = { x: Int, y: Int }
type alias GameObject = { pos: Position, kind: Kind }

type Kind = Lifeform Energy | Obstacle
```

*Type aliases* are the simplest among them. They don't introduce new types, but provide alternative, convenient names for existing ones. So, `Energy` is just an alias for the `Int` type, `Position` an alias for a record type (think Javascript Objects) with both `x` and `y` property as `Int`, and `GameObject` an alias for another record type with both `pos` and `kind` properties. `pos` is of type `Position`, but what exactly is `kind`?

```elm
type Kind = Lifeform Energy | Obstacle
```

`Kind` is a so called *union type*, which can be compared to *enums* in other languages, especially to [those in Swift](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Enumerations.html), because they can also have some kind of associated values. As you can see, `Kind` would either be a `Lifeform` or `Obstacle`. But what does `Energy` do next to `Lifeform`?

`Lifeform Energy` is called a *type constructor*. At least for me, this was something I needed quite some time to wrap my head around. As we know, `Energy` is just an alias for `Int`, so we could substitute it with `Lifeform Int`. Think of the `Lifeform`  literal as *tag* to protect against misuse.

While this is a valid use of a type constructor:

```elm
playerKind = Lifeform 100
```

this is not:

```elm
notALifeform = 100
```

What are the advantages? Imagine that we'll extend our game to also have space ships, which aren't life forms, but have life / energy meters of their own. We could then extend our `Kind` union type like:

```elm
type Kind = Lifeform Energy | SpaceShip Energy | Obstacle
```

And use them like:

```elm
playerKind = Lifeform 100
shipKind = SpaceShip 500
```

Even if we basically only care for the `Energy` value, we protect `playerKind` and `shipKind` by providing the appropriate  *tags*. From now on, the compiler will complain, if you try to use a `SpaceShip` where only `Lifeform`s would be valid. Let that sink in for a moment. It is a real powerful language feature.

```elm
moveTo: GameObject -> Position -> GameObject
moveTo obj newPos =
  case obj.kind of
    Lifeform eng -> { obj | pos = newPos }
    Obstacle -> obj
```

Here, wo define `moveTo` as a function to take a `GameObject` and `Position` as parameter and returns a `GameObject`. Because only `Lifeform`s can move to another position, we use the Elm's `case` statement for type and pattern matching. So, if `obj.kind` is a `Lifeform`, we'll just "update" the position value to `newPos` (in reality, we're returning a new record object). If it's an `Obstacle`, we'll return the object as-is.

```elm
player: GameObject
player =
  { pos = { x = 0, y = 0 }
  , kind = Lifeform 100
  }
```

We now introduce `player` of type `GameObject` and give it an initial position and kind `Lifeform` with an energy value of 100.

```elm
main =
  text (toString (moveTo player { x = 1, y = 1 }))
```

The `main` function triggers the execution of our Elm app. It moves our `player` to new position and puts it's [string representation](http://package.elm-lang.org/packages/elm-lang/core/5.0.0/Basics#toString) as text into the DOM, which results in

```elm
{ pos = { x = 1, y = 1 }, kind = Lifeform 100 }
``` 

And that's it! In just more than 20 lines of code, we'll have a simple model for our game, completely type safe without any classes, inheritance, if statements, or abstract methods. It's not just concise and readable, but also pretty elegant.

Further reading:

* [An Introduction to Elm](https://guide.elm-lang.org/)
* [The Elm Architecture](https://guide.elm-lang.org/architecture/)
* [Elm explained](https://github.com/niksilver/elm-explained)
