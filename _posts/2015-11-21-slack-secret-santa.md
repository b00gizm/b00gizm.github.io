---
layout:     linked-post
title:      Slack Secret Santa
author:     Pascal Cremer
date:       2015-11-21 13:09:26
tags:       linked slack php symfony
---

> Secret Santa is a Western Christmas tradition in which members of a group or community are randomly assigned a person to whom they anonymously give a gift.
> At JoliCode, we do this every year, and every year we have to ask someone from outside the company to be our "Secret Santa", running a script and sending emails to everyone.

> This time is gone! With this Slack application, just select the peoples you want to do a Secret Santa with, and let Rudolph decide and notify, by private message, each user.

Source: [https://slack-secret-santa.herokuapp.com/](https://slack-secret-santa.herokuapp.com/)

I'm a sucker for fun and nerdy side projects like this: Prepare this year's Secret Santa within [Slack](https://slack.com).

But if you dig into [its code](https://github.com/jolicode/slack-secret-santa), you'll find even more goodies. It's based on Symfony 2.8 and features [the new Microkernel](http://symfony.com/blog/new-in-symfony-2-8-symfony-as-a-microframework), which enables a whole new class of slim and single-purpose apps "on the shoulders" of Symfony with some great impacts on [performance](https://www.flickr.com/photos/21284732@N04/22515869074/).
