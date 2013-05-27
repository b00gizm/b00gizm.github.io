---
layout: page
title: CodeNugget Blog
tagline: Recent posts.
---
{% include JB/setup %}

There will be more here soon. I promise.

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>
