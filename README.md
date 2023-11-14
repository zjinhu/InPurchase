# InPurchase

[![SPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager/)
![Xcode 14.0+](https://img.shields.io/badge/Xcode-14.0%2B-blue.svg)
![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)
![Swift 5.0+](https://img.shields.io/badge/Swift-5.0%2B-orange.svg)
![SwiftUI 3.0+](https://img.shields.io/badge/SwiftUI-3.0%2B-orange.svg)

## Example

基于iOS15提供的StoreKit2封装的app内购买功能,支持StoreKit1的SKPaymentQueue。

## Usage

创建ProductIds.plist文件，将ProductId存入，方便InPurchase获取。

在适当位置初始化InPurchase，InPurchase会以异步的方式获取plist文件中的产品，并将其存入products数组。且会自动获取当前订阅购买状态并存入InPurchaseStorage,方便外部判断。

点击购买后等待状态请根据showLoading去展示遮罩。

需要用到内购信息请传递环境变量至需要用到的View

```
    @StateObject var storeKit = InPurchase()
```



## Install

Select `File > Swift Packages > Add Pacakage Dependency` in Xcode's menu bar, and enter in the search bar

`https://github.com/jackiehu/InPurchase`, you can complete the integration

### Manual Install

InPurchase also supports manual Install, just drag the InPurchase folder in the Sources folder into the project that needs to be installed

## Author

jackiehu, 814030966@qq.com

## More tools to speed up APP development

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftMediator&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftMediator)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftBrick&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftBrick)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftLog&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftLog)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftMesh&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftMesh)

[![ReadMe Card](https://github-readme-stats.vercel.app/api/pin/?username=jackiehu&repo=SwiftNotification&theme=radical&locale=cn)](https://github.com/jackiehu/SwiftNotification)


## 许可

InPurchase is available under the MIT license. See the LICENSE file for more info.
