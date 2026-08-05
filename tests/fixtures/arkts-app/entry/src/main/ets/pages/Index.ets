import { add } from '../utils/MathUtil';

@Entry
@Component
struct Index {
  build() {
    Column({ space: 10 }) {
      Text('ArkTS fixture')
        .fontSize(20)
      Text(`1 + 2 = ${add(1, 2)}`)
        .fontSize(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
