#! /bin/bash
# $DEBUG 开发环境为True，生产环境为False
set -e

if [[ ! $DEBUG ]]; then
    read -p "Project Name: " NAME
else
    NAME='test'
fi

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

cd $NAME
rm -r src/assets
mkdir src/views
mkdir src/mock
touch src/mock/index.js
touch src/components/.gitkeep
mv src/components/HelloWorld.vue src/views/Index.vue

if [[ ! $DEBUG ]]; then
    npm install
    npm install -S axios vue-axios
    npm install -S element-ui
    npm install -S mockjs
fi

#是否有后端
#如果有，则会更改package.json第10行，自动将打包好的文件导入后端
#后端必须为类flask项目文件格式，有templates和static文件夹
if [[ ! $DEBUG ]]; then
    read -p "Any back end (flask like only)? (y/n) " back_end_flag
    back_end_path=""
    if [[ $back_end_flag == "n" ]]; then
        :
    else
        #填写后端的路径必须相对于vue项目，同级直接填写文件夹名字，否则使用..来定位
        read -p "Path (relative to project $NAME) to the back end: " back_end_path
    fi
else
    back_end_path='test'
fi

#修改src/router/index.js中默认的演示文件为Index
router_import_code_darwin="import Index from '@/views/Index'\
"

router_import_code_linux="import Index from '@/views/Index'"

router_component_code_darwin="\      component: Index,\
"

router_component_code_linux="\      component: Index,"

#用于防止router-link组件被多次点击而报错
router_link_code_darwin='const originalPush = Router.prototype.push\
Router.prototype.push = function push(location) {\
\  return originalPush.call(this, location).catch(err => err)\
}\
\
'

router_link_code_linux='const originalPush = Router.prototype.push\
Router.prototype.push = function push(location) {\
\  return originalPush.call(this, location).catch(err => err)\
}\
'

#main.js中导入包以及判断运行环境，若为开发环境则调用mock.js
main_code_darwin='import axios from "axios";\
import VueAxios from "vue-axios";\
import ElementUI from "element-ui";\
import "element-ui/lib/theme-chalk/index.css";\
\
Vue.use(VueAxios, axios);\
Vue.use(ElementUI);\
\
if (process.env.NODE_ENV == "development") { require("./mock"); }\
'

main_code_linux='import axios from "axios";\
import VueAxios from "vue-axios";\
import ElementUI from "element-ui";\
import "element-ui/lib/theme-chalk/index.css";\
\
Vue.use(VueAxios, axios);\
Vue.use(ElementUI);\
\
if (process.env.NODE_ENV == "development") { require("./mock"); }'

#更改config/index.js中的默认host为0.0.0.0
host_code_darwin="\    host: '0.0.0.0', // can be overwritten by process.env.HOST\
"

host_code_linux="\    host: '0.0.0.0', // can be overwritten by process.env.HOST"

#如果有类flask的后端，可以自动将打包好的文件导入
build_code_darwin="\    \"build\": \"node build/build.js && cp -r dist/index.html ../$back_end_path/templates/ && rm -r ../$back_end_path/static && cp -r dist/static ../$back_end_path\"\
"

build_code_linux="\    \"build\": \"node build/build.js && cp -r dist/index.html ../$back_end_path/templates/ && rm -r ../$back_end_path/static && cp -r dist/static ../$back_end_path\""

#判断系统平台
#因为macOS与Linux下的sed命令有差别
#Darwin即macOS
system=$(uname -a)
if [[ $system =~ "Darwin" ]]; then
    sed -i '' "/export default new Router/i\\
        $router_link_code_darwin
        /HelloWorld/d
        /import Router/a\\
        $router_import_code_darwin
        /path/a\\
        $router_component_code_darwin
        " src/router/index.js

    sed -i '' "/.\/assets\/logo.png/d
        /margin-top/d
        " src/App.vue

    sed -i '' "/import router/a\\
        $main_code_darwin
        " src/main.js

    sed -i '' "/localhost/d
        /port: 8080/i\\
        $host_code_darwin
        " config/index.js

    if [[ $back_end_flag == "n" ]]; then
        :
    else
        sed -i '' "/\"build\": \"node build\/build.js\"/d
            /\"start\": \"npm run dev\"/a\\
            $build_code_darwin
            " package.json
    fi
else
    sed -i "/export default new Router/i $router_link_code_linux" src/router/index.js
    sed -i "HelloWorld/d" src/router/index.js
    sed -i "/import Router/a $router_import_code_linux" src/router/index.js
    sed -i "/path/a $router_component_code_linux" src/router/index.js

    sed -i "/.\/assets\/logo.png/d; /margin-top/d" src/App.vue

    sed -i "/import router/a $main_code_linux" src/main.js

    sed -i "/localhost/d; /port: 8080/i $host_code_linux" config/index.js

    if [[ $back_end_flag == "n" ]]; then
        :
    else
        sed -i "/\"build\": \"node build\/build.js\"/d; /\"start\": \"npm run dev\"/a $build_code_linux" package.json
    fi
fi

#mock写法例子
mock_code='const Mock = require("mockjs");\n//Mock.mock("url", "get/post", require("file"));'
echo -e $mock_code >src/mock/index.js

echo -e "\nProject initialization finished!\n\nTo get started:\n\ncd $NAME\nnpm run dev\n"
