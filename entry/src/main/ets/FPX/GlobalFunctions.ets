/** 声明：以下代码来自AI辅助编程工具Deep Seek 改进而来 */
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';

/**
 * 将Uint8Array数据转换为像素图PixelMap
 * @param context 环境上下文
 * @param uint8Array  二进制数据内容
 * @returns PixelMap像素位图
 */
export async function uint8ArrayToPixelMap(context: common.UIAbilityContext,
  uint8Array: Uint8Array | null | undefined): Promise<image.PixelMap | null> {
  try {
    if (uint8Array !== undefined && uint8Array !== null && uint8Array.length > 0) {
      // 1. 将Uint8Array转换为ArrayBuffer
      const arrayBuffer = uint8Array.buffer;
      // 2. 创建ImageSource
      const imageSource = image.createImageSource(arrayBuffer);
      // 3. 创建解码选项
      const decodingOptions: image.DecodingOptions = {
        // 可以设置解码选项，如：
        editable: true,
        desiredPixelFormat: 3,
      };
      // 4. 解码为PixelMap
      const pixelMap = await imageSource.createPixelMap(decodingOptions);
      return pixelMap;
    } else {
      console.warn('警告#11001：Uint8Array不能为空数据null!:');
      return await createEmptyPixelMap(context);
    }
  } catch (error) {
    console.warn('警告#11002：Uint8Array转PixelMap失败:',);
    return await createEmptyPixelMap(context);
  }
}

/**
 * 生成默认default像素图PixelMap
 * @param context 环境上下文
 * @returns EmptyPixelMap空像素位图
 */
async function createEmptyPixelMap(context: common.UIAbilityContext): Promise<image.PixelMap | null> {
  try {
    let uint8Array: Uint8Array = await context.resourceManager.getRawFileContent("default.png");
    // 1. 将Uint8Array转换为ArrayBuffer
    const arrayBuffer = uint8Array.buffer;
    // 2. 创建ImageSource
    const imageSource = image.createImageSource(arrayBuffer);
    // 3. 创建解码选项
    const decodingOptions: image.DecodingOptions = {
      // 可以设置解码选项，如：
      editable: true,
      desiredPixelFormat: 3,
    };
    // 4. 解码为PixelMap
    const pixelMap = await imageSource.createPixelMap(decodingOptions);
    return pixelMap;
  } catch (error) {
    console.error('错误#11001：Uint8Array转PixelMap失败:');
    return null;
  }
}

