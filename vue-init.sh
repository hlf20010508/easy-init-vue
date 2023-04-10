#! /bin/bash
# $DEBUG 开发环境为true，生产环境为false
set -e

if [[ $DEBUG != 'true' ]]; then
read -p "Project Name: " NAME
#是否有后端
#如果有，则会更改package.json第10行，自动将打包好的文件导入后端
#后端必须为类flask项目文件格式，有templates和static文件夹
read -p "Any back end (flask like only)? (y/n) " back_end_flag
back_end_path=""
if [[ $back_end_flag != "n" ]]; then
#填写后端的路径必须相对于vue项目，同级直接填写文件夹名字，否则使用..来定位
read -p "Path (relative to the parent directory of project $NAME) to the back end: " back_end_path
fi
else
NAME='vue-test'
back_end_path='vue-test'
fi

expect <<EOF
set timeout -1

spawn vue init hlf20010508/vue-template $NAME

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

if [[ $DEBUG != 'true' ]]; then
npm install
npm install -S axios vue-axios element-ui
fi

#如果有类flask的后端，可以自动将打包好的文件导入
build_code_darwin="    \"build\": \"node build/build.js && cp -r dist/index.html ../$back_end_path/templates/ && rm -r ../$back_end_path/static && cp -r dist/static ../$back_end_path\"\
"

if [[ $back_end_flag != "n" ]]; then
sed -i '' "/\"build\": \"node build\/build.js\"/d
/\"start\": \"npm run dev\"/a\\
$build_code_darwin
" package.json
fi

echo -e "\nProject initialization finished!\n\nTo get started:\n\ncd $NAME\nnpm run dev\n"
