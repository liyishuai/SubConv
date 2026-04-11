---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: SubConv
  text: Yet Another Subscription Converter for mihomo
  tagline: Easy-to-deploy mihomo subscription converter
  image:
    src: /logo.jpg
    alt: SubConv Logo
  actions:
    - theme: brand
      text: Get Started
      link: /guide/introduction/what-is-subconv
    - theme: alt
      text: View on GitHub
      link: https://github.com/SubConv/SubConv

features:
  - title: Easy to Deploy
    details: It can be easily deployed on Vercel or Your VPS
  - title: Safe
    details: It's deployed on your own Vercel or VPS, so nobody else can see your data
  - title: Using provider
    details: By using proxy-provider and rule-provider, nodes and rules can be updated automatically on any platform
  - title: Proxy rule-provider by default
    details: Rule-provider will be proxied by default to prevent rule update failure due to inability to access GitHub
  - title: Easy to Customize
    details: You can customize the rule sets and proxy groups by modifying the template files
  - title: Support Multiple Airports
    details: It supports multiple airports
  - title: Support Multiple Protocols
    details: It supports multiple protocols, including SS, SSR, VMess, VLESS, Trojan, and Hysteria. Base64 subscriptions are also supported
  - title: Support Display Remaining Traffic
    details: Support displaying remaining traffic and user information when there is only one subscription
---
