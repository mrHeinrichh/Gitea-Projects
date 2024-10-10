# jxim_client

## 目录结构

```bash
├── gen                        # android 打包密钥
├── plugin                     # 内置插件目录
├── lib                        # 源代码
│   ├── api                      # 所有请求，接口
│   ├── data                     # 数据，模版等
│   ├── object                   # 对象
│   ├── managers                 # 管理器
│   │   ├── objectMgr.dart         # 对象管理器
│   │   ├── imMgr.dart             # im管理器
│   │   ├── callMgr.dart          # 通话管理器
│   ├── utils                    # 工具
│   ├── views                    # 所有页面
│   ├── conf.dart                # 配置文件
│   ├── routes.dart              # 页面路由
│   ├── main.dart                # 入口文件

# 音频文档
## ios: https://www.kdocs.cn/l/stwflD9tNuyf
## android: https://www.kdocs.cn/l/siI2lj8pgHqY

# 踩坑记录
1. iOS 文档里面没有注明要设置默认的UI为true，不然设置这个为true的话，画面是出不来的
2. iOS 用swift初始化QCRTC Manager的时候用普通的初始化方法就行了，因为OC的manager初始化方法的命名不标准

编译：
flutter run --dart-define-from-file=release.json --release

--flavor Runner --dart-define-from-file=release.json

git reset --hard && git checkout stable && git pull &&  git reset --hard d211f42860350d914a5ad8102f9ec32764dc6d06 && flutter doctor -v

# 渠道说明
1=Heytalk, 3=uutalk, 4=uliao

# 同步颜色到uutalk和uliao
dart color_link.dart mediaBarBg 0xE6121212 0xE6121212

# .app转.dmg
1. Xcode打包，生成app文件
2. 签名：
    1. 获得证书：security find-identity -p codesigning
    2. 开始签名：codesign --force --verbose --sign 735C1136FDB7CD3A2F364545F0CCC8FF09BB915C HeyProfile.app
3. 打包成dmg
    1. 修改json文件的app的path
    2. 执行：appdmg ～/im-client/macos/config.json HeyProfile-1.0.20-159.dmg

# 桌面版的数据库存储路径
~/Library/Application Support/com.jiangxia.im/data_*.db
~/Library/Containers/691CE368-D09E-4C54-AE32-B4799D0C24F3/Data/Library/Application Support/com.jiangxia.im/data_*.db

cp -rf ./release.json ./launch.json

  dart fix --apply --code=prefer_collection_literals 
  dart fix --apply --code=prefer_const_constructors 
  dart fix --apply --code=sized_box_for_whitespace 
  dart fix --apply --code=unnecessary_this 
  dart fix --apply --code=unused_element 
  dart fix --apply --code=unused_import 
  dart fix --apply --code=use_super_parameters 

```
