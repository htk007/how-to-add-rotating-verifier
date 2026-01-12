import display from '@ohos.display'
import { promptAction } from '@kit.ArkUI'

interface XY { x: number; y: number }

function atanToDegrees(rad: number): number {
  return rad * (180 / Math.PI)
}

function angleBetween(p0: XY, p1: XY, p2: XY): number {
  const sY = p1.y - p0.y
  const sX = p1.x - p0.x
  const eY = p2.y - p0.y
  const eX = p2.x - p0.x
  const start = Math.atan2(sY, sX)
  const end = Math.atan2(eY, eX)
  let deg = atanToDegrees(end - start)
  if (deg > 180) {
    deg -= 360
  }
  if (deg <= -180) {
    deg += 360
  }
  return deg
}

/** --- Rotating Verification Component --- */
@Component
struct VerificationDial {
  onVerified?: () => void

  @State private rotateAngle: number = -90
  @State private startPos: XY = { x: 0, y: 0 }
  @State private updatePos: XY = { x: 0, y: 0 }
  @State private center: XY = { x: 0, y: 0 }
  @State private verified: boolean = false

  private screenW: number = 0
  private screenH: number = 0
  private startRotates: number = 0
  private updateRotates: number = 0

  aboutToAppear(): void {
    const d = display.getDefaultDisplaySync()
    this.screenW = this.getUIContext().px2vp(d.width)
    this.screenH = this.getUIContext().px2vp(d.height)
    this.center = { x: this.screenW / 2, y: this.screenH / 2 } as XY
  }

  build() {
    Column() {
      // Title slightly lower
      Text('Rotate to Verify')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 60, bottom: 16 })

      Stack() {
        // Rotating icon
        Image($r('app.media.dislikeIcon'))
          .width(70)
          .height(70)
          .rotate({ centerX: '50%', centerY: '50%', angle: this.rotateAngle })

        // Small verification circle
        Circle()
          .width(110)
          .height(110)
          .stroke('#3D5AFE')
          .strokeWidth(3)
          .fillOpacity(0)
          .onTouch((ev: TouchEvent) => {
            if (this.verified) {
              return
            }

            if (ev.type === TouchType.Down) {
              this.startRotates = this.rotateAngle
              this.startPos = { x: ev.touches[0].windowX, y: ev.touches[0].windowY } as XY
            } else if (ev.type === TouchType.Move) {
              this.updatePos = { x: ev.touches[0].windowX, y: ev.touches[0].windowY } as XY
              this.updateRotates = angleBetween(this.center, this.startPos, this.updatePos)
              this.rotateAngle = this.updateRotates + this.startRotates
            }

            // Verification threshold: +90° ±5°
            if (!this.verified && this.rotateAngle > 85 && this.rotateAngle < 95) {
              this.verified = true
              promptAction.openToast({ message: 'Verification successful!' })
              this.onVerified && this.onVerified()
            }
          })
      }

      Text(this.verified ? 'Verified!' : 'Rotate +90° to verify')
        .fontSize(16)
        .opacity(0.7)
        .margin({ top: 24 })
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }
}

/** --- Main App Screen --- */
@Component
struct MainApp {
  build() {
    Column() {
      Text('Welcome to the App 🎉')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
      Text('You have passed verification.')
        .fontSize(16)
        .opacity(0.7)
        .margin({ top: 8 })
      // --- Real application content goes here ---
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Brown)
  }
}

/** --- Entry Point: Show verification first, then open the main app --- */
@Entry
@Component
struct Index {
  @State private isVerified: boolean = false

  build() {
    if (!this.isVerified) {
      VerificationDial({
        onVerified: () => {
          this.isVerified = true  // Verified: open main app
        }
      })
    } else {
      MainApp()
    }
  }
}