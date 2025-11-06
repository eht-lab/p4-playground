# 如何使用

## 修改dockerfile
修改apollo/docker-compose.yaml
- 替换"your_name" 为自己的名字
- 替换"your_user_id" 为自己的user id，id的查询方法:
   - 在terminal 中输入以下命令, 用查询结果中的uid替换your_user_id
      ```bash
      $ id
      ```
- 替换"your_password" 为你希望的密码

## docker操作

- 构建container
cd 到"docker-compose.yaml"文件所在目录，执行：
```
sudo docker compose up -d
```

- 停止container

```bash
sudo docker compose down

```
## 重启

```bash
sudo docker compose restart
```
