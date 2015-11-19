---
layout:     post
title:      Mobile Blogging with Pythonista, Jekyll and Github
author:     Pascal Cremer
date:       2015-11-18 18:14:27
tags:       ios python blog automation pythonista
---

I've been beta-testing [Ole Zorns](https://twitter.com/olemoritz) new version of his app [Pythonista](http://omz-software.com/pythonista/ "Pythonista") for over three weeks now, and it quickly became one of my most favorite iOS apps ever. Pythonista basically started as an app which lets you run Python code on your iPhone or iPad, but since then, evolved into something more much poweful than just a REPL or stripped down IDE: Pythonista ships with some custom modules as wrappers around iOS APIs, which let you script your very own automations and even add custom UI, if you want.
Pythonista 1.6 now is in its final beta phase and, at least for me, feels more like a 2.x release than just a minor update. It adds editor tabs, so you can have multiple files open at once, new modules and even a bridge for writing your own Objective-C wrappers (fingers crossed that this ever gets past App Review). But my most favorite new feature is the Pythonista app extension, which a way to run your Python scripts from within every app that supports the native iOS share sheet. When I read about this the first time, I immediately knew that I wanted to use it for optimizing my "on the go" blogging workflow.

## The old workflow
To give you a little bit of context: My blog [codenugget.co](http://codenugget.co) is powered by [Jekyll](https://jekyllrb.com/ "Jekyll • Simple, blog-aware, static sites"), an engine written in Ruby for creating static pages from Markdown files, and was originally hosted on [Heroku](https://www.heroku.com/ "heroku - Google-Suche"). Here's what I did:

1. Whenever I started working on a new post, I created a draft inside a special folder inside my [Dropbox](https://www.dropbox.com/ "Dropbox"), so I would be able to access and edit it from any device I own
2. Built a custom Docker image containing everything for running the Jekyll development server. I would then run a [Docker](https://www.docker.com/ "Docker - Build, Ship, and Run Any App, Anywhere") container based on that image with a volume linked to a directory on my local machine containing the code, which I host on Github.
3. Created a [Hazel](https://www.noodlesoft.com/hazel.php) action to run on my host machine that monitors my blog code and Dropbox folders and sync new drafts and / or postings back and forth
4. Whenever I was ready to publish, I'd `git` commit the new post and pushed everything to the `master` branch on [Github](https://github.com/b00giZm/b00gizm.github.io)
5. Finally, I would then push everything to the `heroku` branch, which would then trigger a rebuild and reload of my Heroku app

Last year, when I started working on this setup, it was a fun and exciting little side project. It took me two days to bring it to a working state — well, kind of. The Hazel script seemed to only work, when it felt like it. Most of the time, it simply wouldn't trigger automatically. I don't know this was a bug inside Hazel, some weird conditions regarding file events and Dropbox hosted files, or just me not understanding how to correctly use the file creation / modification time attributes for Hazel actions. 

But, more importantly, I couldn't publish new posts from my iPhone or iPad, because I would always need Git as my ultimate requirement. 

## The new and shiny Pythonista way

First of all, I migrated my blog from Heroku to Github pages, which elimates step 5 from above, because I now just have to push to `master` and Github will pick up all changes and update the contents of my blog. Github pages are free to use and bring a custom `<username>.github.io` subdomain for every user. If you want to use your own domain, just include a `CNAME` file in your repository [and point your domain to Github's servers](https://help.github.com/articles/setting-up-a-custom-domain-with-github-pages/ "Setting up a custom domain with GitHub Pages - User Documentation"). So, in my case, [http://codenugget.co](http://codenugget.co) is now pointing to [http://b00gizm.github.io](http://b00gizm.github.io).

I then wrote a little script called `MobileBlogger.py`, which can be accessed through the Pythonista app extension. I takes a blob of text, does some magic to determine meta data like the title or the file name, prompts a `dialogs.form_input()` sheets for confirmation, and  then uses the `pygithub3` [Python module](https://pygithub3.readthedocs.org/en/latest/ "Documentation Overview — pygithub3 0.5.1 documentation") to push everything to Github over their official API.

In my first tests, it worked pretty well and Github picked up the changes almost instantly, which means, that I can now publish new posts from almost every iOS app that supports native text sharing (even the iOS Notes app, if you're really hardcore).

{% gist cc704ba2a96e4a319e9e %}[^gist]

In short:

1. Prepare a draft for a new post in your favorite text app which supports native sharing
2. When ready, launch the share sheets, choose the Pythonista action extension and run the `MobileBlogger.py` script
3. Customize the default values in the then presented confirmation sheet
4. Hit "Done"

You want see this as a GIF? Sure you do ;)

![mobile-blogger.gif](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/mobile-blogger.gif)

**Update 11/19/2015: Added the full video**

<iframe src="https://player.vimeo.com/video/146140447" width="500" height="375" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

Feel free to fork, use and/or improve my script as you like. 

To be honest, I'd really appreciate, if you would send suggestions on how to improve it. Since I have no real Python background, it currently might not be the most idiomatic Python code on the planet (and it's, by no means, anything near feature complete, since you currently can only create new posts and not push updates).

So, if you haven't already, head to the AppStore [and buy Pythonista](https://appsto.re/de/P0xGF.i). I guess it won't take that much longer until version 1.6 leaves its beta state and will be released to the public.

[^gist]: Important: `MobileBlogger.py` depends on the [pygithub3](http://pygithub3.readthedocs.org/en/latest/) module, which provides a wrapper around Github's API. Please make sure, that it's available inside your Pythonista app. For your convenience, I recommend [StaSh](https://github.com/ywangd/stash), a bash-like shell for Pythonista, which makes it easy to install Python modules via its own `pip.py` command.
