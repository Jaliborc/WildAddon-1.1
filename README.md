# WildAddon-1.1 :computer:
[![Patreon](http://img.shields.io/badge/news%20&%20rewards-patreon-ff4d42)](https://www.patreon.com/jaliborc)
[![Paypal](http://img.shields.io/badge/donate-paypal-1d3fe5)](https://www.paypal.me/jaliborc)
[![Discord](http://img.shields.io/badge/discuss-discord-5865F2)](https://bit.ly/discord-jaliborc)

A library for developing addons using a module-based approach.

Originally inspired on [AceAddon-3.0](https://www.wowace.com/projects/ace3) with minor behavior tweaks, this project has since diverged, adding features like _EventTrace_ support for signal debugging. Requires [CallbackHandler](https://www.curseforge.com/wow/addons/callbackhandler).

### Library API
|Name|Description|
|:--|:--|
| :Embed(object) | Adds the library method to your object. |
| :NewAddon(name [, object] [, libraries]) | Creates a public **addon object** or turns the provided one into it. |

### Addon Objects
Objects created using `:NewAddon` come with a set of predefined methods:

|Name|Description|
|:--|:--|
| :NewModule(name \[, object] \[, libraries, ...]) | Same as `:NewAddon`, but creates a local **addon object** parented to the main addon, called a module. |
| :SetDefaults(table, defaults)               | Initializes a table with a set of default values, without actually modifying the table. Useful for saved variables.                                                         |
| :RegisterEvent(event, call \[, args, ...])       | Listens to a game event.                                                                               |
| :UnregisterEvent(event)                     | Stops listening to a game event.                                                                       |
| :ContinueOn(condition, call)                | Listens to a game event **once**.                                                                      |
| :RegisterSignal(id, call \[, args, ...])         | Listens to an internal message among the addon and its modules.                                        |
| :UnregisterSignal(id)                       | Stops listening to an internal addon message.                                                          |
| :SendSignal(id \[, args, ...])                   | Sends an internal message to the addon and its modules.                                                |
| :UnregisterAll()                            | Unregisters all registered events and signals.                                                         |

Additionally, `:OnLoad()`, if defined, will be called on each object once the game has started and the addon is ready to load.

### :warning: Reminder!
If you use this library, please list it as one of your dependencies in the CurseForge admin system. It's a big help! :+1: