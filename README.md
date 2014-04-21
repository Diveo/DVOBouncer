#DVOBouncer

Add gravity bouncing to UIScrollView content.

> Useful for interactive tutorials, where say you want to show the user there is more content on another side of the scroll view.

DVOBouncer uses UIKit Dynamics to simulate an elastic bounce effect on scroll view content, in any direction.

Sample
-------

<img src="./Demo/bounce.gif" align="middle" width="280" />

Usage
-------

`DVOBouncer` can be implemented in one line:

```objective-c
self.bouncer = [DVOBouncer bounceScrollView:scrollView inDirection:DVOBounceDirectionBottom];
```

Background
-------
`DVOBouncer` was built during the creation of [Diveo](http://appstore.com/diveo) to help demonstrate to users how to interact with the app.

Contact
-------
**Diveo** | [www.diveo.co](http://www.diveo.co) | [@diveoapp](https://twitter.com/diveoapp)

**Mo Bitar** | [@bitario](https://twitter.com/bitario)

License
-------
DVOBouncer is available under the MIT license.


