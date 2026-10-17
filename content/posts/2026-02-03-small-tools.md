---
title: Small tools, sharp edges
slug: small-tools
date: 2026-02-03
description: On building software that does one thing and then stops.
tags:
  - engineering
draft: true
---

The best tool I own is a mechanical pencil that has done exactly one thing
since 2014. It has no firmware. It has never asked me to rate it.

Most software wants to become a platform. A note-taking app grows a calendar,
then a chat feature, then an AI assistant, and at some point it stops being
good at notes. The pressure is structural rather than anyone's fault: teams
need roadmaps, and roadmaps need new things.

What I keep coming back to is that a tool which does one thing can be
*finished*. There is a version after which the correct amount of work is zero.

```ruby
# The whole thing, roughly.
def render(markdown)
  Commonmarker.to_html(markdown, options: { parse: { smart: true } })
end
```

Finished software is rare enough that when you find some, it feels like a
small act of generosity.
