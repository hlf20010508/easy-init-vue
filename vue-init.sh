#! /bin/bash
set -e

read -p "Project Name: " NAME
expect <<EOF
    set timeout -1
    
    spawn vue init webpack $NAME

    expect "name"
    send "\n"

    expect "description"
    send "\n"

    expect "Author"
    send "\n"

    expect "Compiler"
    send "\n"

    expect "vue-router"
    send "Y\n"

    expect "ESLint"
    send "n\n"

    expect "unit"
    send "n\n"

    expect "e2e"
    send "n\n"

    expect "NPM"
    send "\033\[B\033\[B\n"

    expect eof
EOF
# expect "NPM"
# 执行 npm install
# send "\n"
# 不执行 npm install
# send "\033\[B\033\[B\n"

cd $NAME
rm src/assets/logo.png
mkdir src/views
mkdir src/mock
touch src/mock/index.js
# npm install -S axios vue-axios
# npm install -S element-ui
# npm install -S mockjs

#是否有后端
#如果有，则会更改package.json第10行，自动将打包好的文件导入后端
#后端必须为类flask项目文件格式，有templates和static文件夹
read -p "Any back end (flask like only)? (y/n) " back_end_flag
back_end_path=""
if [[ $back_end_flag == "n" ]]
then
    :
else
    #填写后端的路径必须相对于vue项目，同级直接填写文件夹名字，否则使用..来定位
    read -p "Path (relative to project $NAME) to the back end: " back_end_path
fi

#用于防止router-link组件被多次点击而报错
router_link_code='const originalPush = Router.prototype.push\
Router.prototype.push = function push(location) {\
\  return originalPush.call(this, location).catch(err => err)\
}\
\
'

#main.js中导入包以及判断运行环境，若为开发环境则调用mock.js
main_code='import axios from "axios";\
import VueAxios from "vue-axios";\
import ElementUI from "element-ui";\
import "element-ui/lib/theme-chalk/index.css";\
\
Vue.use(VueAxios, axios);\
Vue.use(ElementUI);\
\
if (process.env.NODE_ENV == "development") { require("./mock"); }\
'

#更改config/index.js中的默认host为0.0.0.0
host_code="\    host: '0.0.0.0', // can be overwritten by process.env.HOST\
"

#mock写法例子
mock_code='const Mock = require("mockjs");\
//Mock.mock("url", "get/post", require("file"));\
'

#如果有类flask的后端，可以自动将打包好的文件导入
build_code='\    "build": "node build/build.js && cp -r dist/index.html ../'$back_end_path'/templates/ && rm -r ../'$back_end_path'/static && cp -r dist/static ../'$back_end_path'"\
'

#判断系统平台
#因为macOS与Linux下的sed命令有差别
#Darwin即macOS
system=$(uname -a)
if [[ $system =~ "Darwin" ]]
then
    sed -i '' "/export default new Router/i\\
        $router_link_code
        /name: 'HelloWorld'/d
        " src/router/index.js

    sed -i '' "/.\/assets\/logo.png/d
        /margin-top/d
        " src/App.vue

    sed -i '' "/import router/a\\
        $main_code
        " src/main.js

    sed -i '' "/localhost/d
        /port: 8080/i\\
        $host_code
        " config/index.js

    if [[ $back_end_flag == "n" ]]
    then
        :
    else
        sed -i '' "/\"build\": \"node build\/build.js\"/d
            /\"start\": \"npm run dev\"/a\\
            $build_code
            " package.json
    fi
else
    sed -i "/export default new Router/i $router_link_code; /name: 'HelloWorld'/d" src/router/index.js

    sed -i "/.\/assets\/logo.png/d; /margin-top/d" src/App.vue

    sed -i "/import router/a $main_code" src/main.js

    sed -i "/localhost/d; /port: 8080/i $host_code" config/index.js

    if [[ $back_end_flag == "n" ]]
    then
        :
    else
        sed -i "/\"build\": \"node build\/build.js\"/d; /\"start\": \"npm run dev\"/a $build_code" package.json
    fi
fi

mock_code='const Mock = require("mockjs");\n//Mock.mock("url", "get/post", require("file"));'
echo -e $mock_code > src/mock/index.js

echo -e "\nProject initialization finished!\n\nTo get started:\n\ncd $NAME\nnpm run dev\n"
