![WingKit: a Lung Function Test SDK](./wingkit-logo.png)

WingKit is a library that allows third parties to integrate with the Wing REST API to perform lung function tests.

## Requirements

- iOS 9.0+
- Xcode 9.0+
- Swift 4.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. To install it, run this command in your terminal:
```bash
$ gem install cocoapods
```

> WingKit requires CocoaPods 1.1+ to build.

To integrate WingKit into your project, specifiy it in your `Podfile`:

#### Production

```ruby
source 'https://github.com/sparodev/Wing-CocoaPodSpecs'
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'WingKit', '~> 1.0'
end
```

#### Development

 1. Clone the WingKit repository to your mac.
 2. Reference the local filepath where you cloned the repo in your Podfile:

```ruby
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'WingKit', :path => '<path/to/repo>'
end
```

## Examples

Check out the [WingKitExample repo](https://github.com/sparodev/WingKitExample) for an example of how to integrate with WingKit to perform a lung function test and view the results.