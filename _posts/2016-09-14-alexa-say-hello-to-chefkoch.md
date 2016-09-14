---
layout:     post
title:      "Alexa, say hello to Chefkoch!"
author:     Pascal Cremer
date:       2016-09-14 14:04:30
tags:       amazon alexa echo chefkoch
---
!["Alexa, say hello to Chefkoch!"](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/amazon-echo01.png)

**(Click [here](https://dayone.me/2GSSz1Q) for the [German version](https://dayone.me/2GSSz1Q) of this post.)**

As you might [have heard](http://www.theverge.com/2016/9/14/12912690/amazon-echo-european-release-date-features), the [Amazon Echo](https://www.amazon.com/Amazon-Echo-Bluetooth-Speaker-with-WiFi-Alexa/dp/B00X4WHP5E) (with their virtual assistent "Alexa") will launch in both Germany and UK this fall, and I'm excited to tell you that [Chefkoch](http://www.chefkoch.de/), the company I am a part of, along with others of our parent company [Gruner+Jahr](http://www.guj.de/), will be one of the official launch partners to deliver a so called ["custom skill"](https://developer.amazon.com/alexa-skills-kit) to enhance to capatibilities of the device.

So, during late August and the first half of September 2016, I had the great opportunity to work on Chefkoch's official Alexa skill, and, to be honest, it almost felt unreal to me. When the Echo originally launched in the US in June of 2015, I was totally hooked by the idea of having a "Siri" like virtual assistent, which you can put on your kitchen table or inside your living room, instead of just having in on your mobile phone. I [totally](http://codenugget.co/2016/05/22/sunday-hacking-sonos-home-part1.html) [knew](http://codenugget.co/2016/08/29/sunday-hacking-sonos-home-part2.html) that I wanted to write software for it, and, as of today, I am one of the few lucky guys in Germany and UK to officially have early access to the device itself and the new beta software.

![Amazon Echo at desk](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/amazon-echo02.jpg)

Chefkoch.de just celebrated its [18th birthday](http://www.guj.de/presse/pressemitteilungen/chefkochde-feiert-18-geburtstag/) this summer. As you can imagine, we carry a [big legacy](http://web.archive.org/web/19991001233853/http://www.chefkoch.de/), but our team is constantly exploring new ways of making Europes biggest recipe database accessible to even more people in order to enrich their lives. In a company wide hackathon (internally dubbed "Mett-a-Thon"), one of our teams released [Chatkoch](https://www.facebook.com/chatkoch) (our first chat bot) on Facebook's [Messenger platform](https://www.messenger.com/). If you chat with him, he will give you suggestions based on the preferences you tell him. Even though we launched him on Facebook first, he was architected to support all different kind of message services and protocols like [XMPP/Jabber](http://xmpp.org/), [Slack](https://slack.com/) or [Mattermost](https://www.mattermost.org/). It was amazing what the Chatkoch team put out in just three days of work.

Being on Amazon Echo on day one seemed like the most obvious next evolutionary step. Instead of just typing you can just your voice to access great recipes and suggestion from the Chefkoch.de database. For the initial release, you'll have access to our recipe of the day and the  best recipes from our most famous categories. You can let Alexa read out the ingredients of the recipes you're interested in, and, when you're ready to cook, it can send the full recipe to your Alexa app. We still have a ton of other ideas for evolving our Chefkoch skill, but we thought that this is a great set to start with and we hope to bring even more of it to this new platform in the near future.

![My cat Minx, still suspicious of this shiny new thing](https://raw.githubusercontent.com/b00giZm/b00gizm.github.io/master/uploads/amazon-echo03.jpg)

In a follow up blog post, I will go over the nitty gritty technical details of developing a custom skill for our use case, and the toolchain that helped releasing a fully featured internal beta version in less than a week of development.

I'd like to thank my company for giving me this opportunity, plus our parent company G+J, and our partners at Amazon for the great support throughout the last weeks. The official Chefkoch skill will be available for free at launch on October 26 2016 for all German customers of Amazon Echo.
