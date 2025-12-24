# 熊宝记账 🐻💰

一款基于HarmonyOS开发的现代化个人记账应用，帮助您轻松管理日常收支，养成良好的理财习惯。

## ✨ 主要功能特性

### 📊 核心记账功能
- **快速记账**：支持收入/支出快速录入，操作简单直观
- **分类管理**：内置丰富的收支分类，支持自定义分类和图标
- **账户管理**：支持现金、支付宝、微信等多种账户类型
- **账单统计**：按月份查看收支明细和统计分析

### 💡 智能功能
- **预算管理**：设置月度预算，实时监控支出情况
- **数据备份**：支持数据备份和恢复，保障数据安全
- **桌面卡片**：提供桌面小组件，快速查看收支概况
- **企业微信**：内置企业微信二维码，支持保存到相册

### 🎨 用户体验
- **现代化UI**：遵循HarmonyOS设计规范，界面简洁美观
- **暗色主题**：支持明暗主题切换，适应不同使用场景
- **流畅交互**：基于ArkTS开发，提供原生级别的流畅体验

## 🚀 安装指南

### 环境要求
- **开发环境**：DevEco Studio 5.0+
- **系统版本**：HarmonyOS 6.0+
- **API Level**：12+
- **Node.js**：16.0+

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd AccountingBook3
   ```

2. **安装依赖**
   ```bash
   ohpm install
   ```

3. **编译项目**
   ```bash
   hvigorw assembleApp
   ```

4. **一键部署**
   ```bash
   # Windows
   .\run.ps1
   
   # macOS/Linux
   ./run.sh
   ```

## 📖 使用说明

### 快速开始

1. **首次使用**
   - 启动应用后，系统会自动初始化数据库
   - 默认创建基础的收支分类和账户类型

2. **添加记账记录**
   - 点击主页的"+"按钮进入记账页面
   - 选择收入/支出类型、分类、账户
   - 输入金额和备注信息
   - 点击保存完成记录

3. **查看统计**
   - 主页显示当月收支概况
   - 点击"账单"查看详细记录
   - 支持按月份筛选和统计

### 高级功能

- **自定义分类**：在分类管理页面添加个性化分类
- **预算设置**：设置月度预算并监控执行情况
- **数据备份**：定期备份数据，防止数据丢失
- **企业微信**：扫描二维码添加企业微信联系

## ⚙️ 配置选项

### 应用配置

应用的主要配置文件位于以下位置：

- **应用配置**：`AppScope/app.json5`
- **模块配置**：`entry/src/main/module.json5`
- **构建配置**：`build-profile.json5`

### 权限配置

应用需要以下权限：

```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.WRITE_IMAGEVIDEO",
      "reason": "$string:permission_write_imagevideo_reason",
      "usedScene": {
        "abilities": ["EntryAbility"],
        "when": "inuse"
      }
    }
  ]
}
```

### 数据库配置

- **数据库名称**：`bills.db`
- **安全级别**：S3
- **存储位置**：应用沙箱目录

## 🏗️ 项目结构

```
AccountingBook3/
├── AppScope/                 # 应用全局配置
├── entry/                    # 主模块
│   ├── src/main/ets/
│   │   ├── pages/           # 页面组件
│   │   ├── service/         # 业务服务
│   │   ├── model/           # 数据模型
│   │   └── constants/       # 常量定义
│   └── src/main/resources/  # 资源文件
├── hvigor/                  # 构建工具
└── oh_modules/              # 依赖模块
```

## 🤝 贡献指南

我们欢迎所有形式的贡献！请遵循以下步骤：

### 开发流程

1. **Fork 项目**到您的GitHub账户
2. **创建功能分支**：`git checkout -b feature/amazing-feature`
3. **提交更改**：`git commit -m 'Add some amazing feature'`
4. **推送分支**：`git push origin feature/amazing-feature`
5. **创建Pull Request**

### 代码规范

- 遵循ArkTS编码规范
- 使用@ComponentV2和@Local状态管理
- 添加必要的代码注释
- 确保编译通过：`hvigorw assembleApp`

### 提交规范

使用语义化提交信息：

- `feat:` 新功能
- `fix:` 修复bug
- `docs:` 文档更新
- `style:` 代码格式调整
- `refactor:` 代码重构
- `test:` 测试相关

## 📄 许可证信息

本项目采用 [Apache License 2.0](LICENSE) 许可证。

```
Copyright 2024 熊宝记账团队

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

**感谢您使用熊宝记账！** 🎉

如果这个项目对您有帮助，请给我们一个⭐️星标支持！
