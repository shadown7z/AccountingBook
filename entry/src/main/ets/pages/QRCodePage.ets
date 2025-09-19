import { HMRouter } from '@hadss/hmrouter'
import { HMRouterMgr } from '@hadss/hmrouter'
import { promptAction } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

import { PagePath } from '../constants/PagePath'

/**
 * 企业微信二维码页面
 * 功能：展示企业微信二维码，支持保存到本地
 */
@Entry
@HMRouter({ pageUrl: PagePath.QRCODE })
@ComponentV2
export struct QRCodePage {
  @Local isLoading: boolean = false
  @Local showSaveSuccess: boolean = false
  
  /**
   * 页面构建方法
   */
  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()
      
      // 主要内容区域
      this.buildContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }
  
  /**
   * 构建顶部导航栏
   */
  @Builder
  buildHeader() {
    Row() {
      // 返回按钮
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .width(20)
          .height(20)
          .fontColor(['#333333'])
      }
      .width(40)
      .height(40)
      .backgroundColor('transparent')
      .onClick(() => {
        HMRouterMgr.pop()
      })
      
      // 标题
      Text('企业微信二维码')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 占位符保持对称
      Blank()
        .width(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.white'))
    .shadow({
      radius: 4,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }
  
  /**
   * 构建主要内容区域
   */
  @Builder
  buildContent() {
    Column() {
      // 说明文字
      Text('扫描下方二维码添加企业微信')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 40, bottom: 30 })
      
      // 二维码容器
      Column() {
        // 二维码图片
        Image($rawfile('2wb2.jpg'))
          .width(280)
          .height(280)
          .borderRadius(12)
          .shadow({
            radius: 8,
            color: 'rgba(0, 0, 0, 0.15)',
            offsetX: 0,
            offsetY: 4
          })
      }
      .width(320)
      .height(320)
      .backgroundColor($r('app.color.white'))
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(20)
      .shadow({
        radius: 12,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 6
      })
      
      // 保存按钮
      Button('保存到相册')
        .width(200)
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.white'))
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(24)
        .margin({ top: 40 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.saveImageToGallery()
        })
      
      // 加载状态提示
      if (this.isLoading) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color($r('app.color.brand_primary'))
          
          Text('正在保存...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 8 })
        }
        .margin({ top: 16 })
      }
      
      // 提示文字
      Text('长按二维码也可保存图片')
        .fontSize(14)
        .fontColor($r('app.color.text_hint'))
        .margin({ top: 20 })
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  
  /**
   * 保存图片到相册
   */
  private async saveImageToGallery() {
    try {
      this.isLoading = true
      
      // 获取应用上下文
      const context: common.UIAbilityContext = getContext() as common.UIAbilityContext
      
      // 获取相册管理器
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context)
      
      // 注意：此操作必须在用户点击事件触发后的5秒内执行
      // 使用安全控件创建图片资源，系统会自动处理权限
      const uri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'qrcode_wechat.jpg')
      
      // 读取应用内的二维码图片
      const resourceManager = context.resourceManager
      const imageData = await resourceManager.getRawFileContent('2wb2.jpg')
      
      // 将图片数据写入到相册
      const file = await fileIo.open(uri, fileIo.OpenMode.WRITE_ONLY)
      await fileIo.write(file.fd, imageData.buffer)
      await fileIo.close(file.fd)
      
      console.info('保存成功，文件URI:', uri)
      promptAction.showToast({
        message: '图片已保存到相册',
        duration: 2000
      })
      
    } catch (error) {
      const err = error as BusinessError
      console.error('保存图片失败:', err.code, err.message)
      
      let errorMessage = '保存失败，请重试'
      if (err.code === 13900012) {
        errorMessage = '缺少媒体库权限，请允许访问相册'
      } else if (err.code === 13900020) {
        errorMessage = '权限已过期，请重新点击保存'
      }
      
      promptAction.showToast({
        message: errorMessage,
        duration: 2000
      })
    } finally {
      this.isLoading = false
    }
  }
}