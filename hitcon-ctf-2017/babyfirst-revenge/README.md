#### 使用Dockerfile

##### 安装Docker

##### 搭建
- 进入Dockerfile所在的目录
运行命令 ```docker build -t '自定义镜像名称' .``` (请注意最后的点不要少)
运行命令 ```docker images``` 查看是否已经成功构建景象
运行命令 ```docker run -id --name '自定义容器名称' -m '要分配给此容器的内存上限' --network='要分配给此容器的网络' -p '容器的外部端口':80 '自定义镜像名称' /run.sh```

##### 维护
进入容器 运行指令 ```docker exec -it '容器名称' /bin/bash```


镜像作者：Pr0ph3t
1415314884@qq.com