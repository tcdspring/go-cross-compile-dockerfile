    
此Dockerfile集成了一些编译工具，可方便的进行跨平台编译

脚本参考了[https://github.com/karalabe/xgo](https://github.com/karalabe/xgo)项目，里面集成了各种平台的编译器，按照它的教程，很轻松的可以编译出各个平台的二进制文件

需要注意的是xgo项目目前并不支持`go mod`，所以才有了本项目，安装了各种编译器，方便golang进行交叉编译，安装了node.js，方便electron项目打包，安装了wine以及innosetup工具，便于制作windows平台的安装包

使用方法：

```
// YourProjectPath 项目的路径
// $GOPATH 如果不指定的话，在docker中会重新下载项目的依赖
docker run --rm -v YourProjectPath:/project -v $GOPATH:/go -it compiler /bin/bash
```

如果不使用上面的docker，可能需要自己解决一些问题，可参考下面的文档，可能会少走些弯路

### 1. 提示找不到`openssl/rand.h`文件

拿[github.com/xeodou/go-sqlcipher](https://github.com/xeodou/go-sqlcipher)项目来举例，在安装go-sqlcipher时遇到了下面的错误：

```
github.com/xeodou/go-sqlcipher
# github.com/xeodou/go-sqlcipher
../github.com/xeodou/go-sqlcipher/sqlite3-binding.c:18280:10: fatal error: openssl/rand.h: No such file or directory
#include <openssl/rand.h>
^~~~~~~~~~~~~~~~
compilation terminated.
```

提示找不到`openssl/rand.h`文件，如果你也遇到了同样的问题，可以尝试下面的方案：

#### darwin
```
brew install openssl
brew link openssl --force

# 有时候会需要下面两句
export CGO_LDFLAGS="-L/usr/local/opt/openssl/lib"
export CGO_CPPFLAGS="-I/usr/local/opt/openssl/include"

go get -v github.com/xeodou/go-sqlcipher
```
#### ubuntu
```
sudo apt-get install libssl-dev

go get -v github.com/xeodou/go-sqlcipher
```

#### ubuntu上编译win32版本

首先需要安装gcc-mingw-w64

```
sudo apt-get install gcc-mingw-w64
```
完成之后执行

```
// windows 64位
CGO_ENABLED=1 GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc go build
```

这样就可以进行编译了，但是编译的是windows64位的，如果想编译32位的，需要修改一下

```
// windows 32位
CGO_ENABLED=1 GOOS=windows GOARCH=386 CC=i686-w64-mingw32-gcc go build
```

但是go-sqlcipher编译时依然出错，提示openssl/rand.h: No such file or directory 

跟mac和linux上提示是一样的，这时就需要安装openssl了，可以下载代码编译，也可以下载编译好的包进行安装

下载源码编译可参照这篇文章

[OpenSSL for Windows](http://www.blogcompiler.com/2011/12/21/openssl-for-windows/)

当然，下载安装包是最简单的，上面文章的最下边有下载的地址，可下载后进行覆盖即可。

*   [OpenSSL 1.0.0e for 32-bit MinGW-w64](http://www.blogcompiler.com/wp-content/uploads/2011/12/openssl-1.0.0e-mingw32.tar.gz) (prefix i686-w64-mingw32)
*   [OpenSSL 1.0.0e for 64-bit MinGW-w64](http://www.blogcompiler.com/wp-content/uploads/2011/12/openssl-1.0.0e-mingw64.tar.gz) (prefix x86_64-w64-mingw32)


下载后，将解压后的目录中的文件夹复制到gcc-mingw-w64的安装目录即可。
```
sudo cp -r ./openssl-1.0.0e-mingw32/* /usr/i686-w64-mingw32/
sudo cp -r ./openssl-1.0.0e-mingw64/* /usr/x86_64-w64-mingw32/
```
然后执行如下命令：
```
// windows 64位
CGO_ENABLED=1 GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc go build

// windows 32位
CGO_ENABLED=1 GOOS=windows GOARCH=386 CC=i686-w64-mingw32-gcc go build
```

编译可以通过，拷贝编译出的exe文件到windows系统上，也可以运行，并能正常创建sqlcipher的数据库

### 2. 使用`go mod`管理项目，并导入本地包

有这样一种场景，你的项目依赖于某个github库，但是你修改了这个库，那该怎样处理呢？

这时候有两种做法：

#### 1. 在github上fork该库，修改后提交，然后导入该库

优点： 简单，方便

缺点： 改动需要彻底，否则导入该库后容易出现类型错误

#### 2. 第二种就是在本地修改该github库，并引入

如果说这个库很稳定，很久都不会更新，那可以采用这种方式

比如下面的做法：

##### 在项目目录中创建vender文件夹

##### 将github库复制进去

##### 修改`go.mod`文件

```
module daemon

require (
	github.com/paypal/gatt v0.0.0-20151011220935-4ae819d591cf
	github.com/pkg/errors v0.8.1
)

replace github.com/paypal/gatt => ./vender/github.com/paypal/gatt
```

##### 进入gatt目录，并执行下面命令

```
cd ./vender/github.com/paypal/gatt/

go mod init github.com/paypal/gatt
```

这种方式值得争议的地方就是vender目录中的依赖库是否有必要上传到代码仓库中，下面说一下个人的想法吧：

* 如果说你引用的这个库是github上的，并且自己做了修改，而且你用到了vender这种方式，那最好还是将vender中的代码一起提交，如果不提交的话，时间长了很容易忘记自己修改过该库，再次编译时容易出问题

* 如果你的仓库是公司内部私有的，那无所谓了，直接一起交吧


### 3. Golang交叉编译手册

Golang在跨平台编译时是很方便的，下面这个表格列出了golang支持的平台和架构.

GOOS - Target Operating System | GOARCH - Target Platform
---|---
android   | 	arm
darwin    | 	386
darwin    | 	amd64
darwin    | 	arm
darwin    | 	arm64
dragonfly | 	amd64
freebsd   | 	386
freebsd   | 	amd64
freebsd   | 	arm
linux     | 	386
linux     | 	amd64
linux     | 	arm
linux     | 	arm64
linux     | 	ppc64
linux     | 	ppc64le
linux     | 	mips
linux     | 	mipsle
linux     | 	mips64
linux     | 	mips64le
netbsd    | 	386
netbsd    | 	amd64
netbsd    | 	arm
openbsd   |  	386
openbsd   | 	amd64
openbsd   | 	arm
plan9     | 	386
plan9     | 	amd64
solaris   | 	amd64
windows   | 	386
windows   | 	amd64


编译时命令格式如下：


```
env GOOS=target-OS GOARCH=target-architecture go build package-import-path

# 例如在ubuntu上编译arm64架构的二进制
$ GOOS=linux GOARCH=arm64 go build
```

如果代码中不包含C的代码，纯Go编写的，则以上命令就可以跨平台编译了

如果代码中包含C代码，则需要CGO来交叉编译

下面列出了一些常用的编译器

```
// android arm7
CC=arm-linux-androideabi-gcc CXX=arm-linux-androideabi-g++ GOOS=android GOARCH=arm GOARM=7 CGO_ENABLED=1 

// android 386
CC=i686-linux-android-gcc CXX=i686-linux-android-g++ GOOS=android GOARCH=386 CGO_ENABLED=1 

// android arm64
CC=aarch64-linux-android-gcc CXX=aarch64-linux-android-g++ GOOS=android GOARCH=arm64 CGO_ENABLED=1
          
// linux armv5     
CC=arm-linux-gnueabi-gcc-5 CXX=arm-linux-gnueabi-g++-5 GOOS=linux GOARCH=arm GOARM=5 CGO_ENABLED=1 CGO_CFLAGS="-march=armv5" CGO_CXXFLAGS="-march=armv5" 
    
// linux armv6
CC=arm-linux-gnueabi-gcc-5 GOOS=linux GOARCH=arm GOARM=6 CGO_ENABLED=1 CGO_CFLAGS="-march=armv6" CGO_CXXFLAGS="-march=armv6"

// linux armv7-a
CC=arm-linux-gnueabihf-gcc-5 CXX=arm-linux-gnueabihf-g++-5 GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=1 CGO_CFLAGS="-march=armv7-a -fPIC" CGO_CXXFLAGS="-march=armv7-a -fPIC"
   
// linux arm64
CC=aarch64-linux-gnu-gcc-5 CXX=aarch64-linux-gnu-g++-5 GOOS=linux GOARCH=arm64 CGO_ENABLED=1
    
// linux mips64
CC=mips64-linux-gnuabi64-gcc-5 CXX=mips64-linux-gnuabi64-g++-5 GOOS=linux GOARCH=mips64 CGO_ENABLED=1

// linux mips64le
CC=mips64el-linux-gnuabi64-gcc-5 CXX=mips64el-linux-gnuabi64-g++-5 GOOS=linux GOARCH=mips64le CGO_ENABLED=1
 
// linux mips
CC=mips-linux-gnu-gcc-5 CXX=mips-linux-gnu-g++-5 GOOS=linux GOARCH=mips CGO_ENABLED=1 

// linux mipsle
CC=mipsel-linux-gnu-gcc-5 CXX=mipsel-linux-gnu-g++-5 GOOS=linux GOARCH=mipsle CGO_ENABLED=1

// windows amd64
CC=x86_64-w64-mingw32-gcc-posix CXX=x86_64-w64-mingw32-g++-posix GOOS=windows GOARCH=amd64 CGO_ENABLED=1

// windows 386
CC=i686-w64-mingw32-gcc-posix CXX=i686-w64-mingw32-g++-posix GOOS=windows GOARCH=386 CGO_ENABLED=1 

// darwin amd64
CC=o64-clang CXX=o64-clang++ GOOS=darwin GOARCH=amd64 CGO_ENABLED=1

// darwin 386   
CC=o32-clang CXX=o32-clang++ GOOS=darwin GOARCH=386 CGO_ENABLED=1

// ios arm-7
CC=arm-apple-darwin11-clang CXX=arm-apple-darwin11-clang++ GOOS=darwin GOARCH=arm GOARM=7 CGO_ENABLED=1

// ios arm64
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CC=arm-apple-darwin11-clang

```