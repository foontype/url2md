# url2md

pandoc/URLリストの先を全部ダウンロードして、docker run pandoc/extra で .md を作成するツール。

requirements: docker, curl

cygwin supported.

```
$ git clone https://github.com/foontype/url2md
$ cd url2md

$ ./build.sh

$ cp urls.example urls
$ vi urls

$ ./run.sh
```

