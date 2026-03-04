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
  @State private targetAngle: number = 90 // Default to 90, randomized in aboutToAppear
  @State private ringColor: string = '#FF5252' // Initial color

  private screenW: number = 0
  private screenH: number = 0
  private startRotates: number = 0
  private updateRotates: number = 0

  aboutToAppear(): void {
    const d = display.getDefaultDisplaySync()
    this.screenW = this.getUIContext().px2vp(d.width)
    this.screenH = this.getUIContext().px2vp(d.height)
    this.center = { x: this.screenW / 2, y: this.screenH / 2 } as XY
    // Randomize target angle to ensure it requires movement from the -90 start position
    // Generate an offset between 60 and 300 degrees from -90
    let randomOffset = Math.floor(Math.random() * 240) + 60
    this.targetAngle = -90 + randomOffset
    // Normalize target angle to be between -180 and 180
    if (this.targetAngle > 180) {
      this.targetAngle -= 360
    }
    if (this.targetAngle <= -180) {
      this.targetAngle += 360
    }

    // Set initial color based on starting position (-90)
    let initialDiff = Math.abs(-90 - this.targetAngle)
    if (initialDiff > 180) {
        initialDiff = 360 - initialDiff
    }
    if (initialDiff < 5) {
        this.ringColor = '#4CAF50'
    } else if (initialDiff < 30) {
        this.ringColor = '#FF9800'
    } else {
        this.ringColor = '#FF5252'
    }
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
          .stroke(this.ringColor)
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

            // Normalize rotateAngle for verification
            let currentNormalized = this.rotateAngle % 360
            if (currentNormalized > 180) currentNormalized -= 360
            if (currentNormalized <= -180) currentNormalized += 360

            let diff = Math.abs(currentNormalized - this.targetAngle)
            if (diff > 180) {
                diff = 360 - diff
            }

            // Update color based on proximity
            if (diff < 5) {
                this.ringColor = '#4CAF50' // Green when success
            } else if (diff < 30) {
                this.ringColor = '#FF9800' // Orange when close
            } else {
                this.ringColor = '#FF5252' // Red when far
            }

            // Trigger verification on touch up/cancel if close enough, or snap back
            if (ev.type === TouchType.Up || ev.type === TouchType.Cancel) {
              if (diff < 15) { // Snapping threshold
                // Calculate shortest relative path instead of snapping to normalized bounds
                let snapAngle = this.rotateAngle
                let delta = this.targetAngle - currentNormalized
                if (delta > 180) delta -= 360
                if (delta < -180) delta += 360

                animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                  this.rotateAngle = snapAngle + delta
                  this.ringColor = '#4CAF50'
                })
                if (!this.verified) {
                  this.verified = true
                  promptAction.openToast({ message: 'Verification successful!' })
                  // Delay a bit before proceeding
                  setTimeout(() => {
                    this.onVerified && this.onVerified()
                  }, 500)
                }
              } else {
                // Auto-reset if not close enough
                animateTo({ duration: 500, curve: Curve.Friction }, () => {
                  // Reset smoothly relative to current spins
                  let deltaReset = -90 - currentNormalized
                  if (deltaReset > 180) deltaReset -= 360
                  if (deltaReset < -180) deltaReset += 360
                  this.rotateAngle = this.rotateAngle + deltaReset

                  // Reset color calculation
                  let resetDiff = Math.abs(-90 - this.targetAngle)
                  if (resetDiff > 180) resetDiff = 360 - resetDiff
                  if (resetDiff < 5) this.ringColor = '#4CAF50'
                  else if (resetDiff < 30) this.ringColor = '#FF9800'
                  else this.ringColor = '#FF5252'
                })
              }
            } else if (!this.verified && diff < 5) {
               // Immediate verification if they hit it perfectly while moving
               this.verified = true
               promptAction.openToast({ message: 'Verification successful!' })
               setTimeout(() => {
                 this.onVerified && this.onVerified()
               }, 500)
            }
          })

        // Target Indicator Container (same size as the verification circle)
        Stack() {
          // Target Indicator Dot at the top center of the container
          Circle()
            .width(12)
            .height(12)
            .fill('#FF5252')
            .position({ x: '50%', y: 0 })
            .translate({ x: -6, y: -6 }) // offset by half its width/height to center it exactly on the stroke
        }
        .width(110)
        .height(110)
        // Rotate the entire container to place the dot on the correct orbit angle
        .rotate({ centerX: '50%', centerY: '50%', angle: this.targetAngle + 90 }) // Add 90 because 0 angle in math is right, but 0 angle in UI starting pos is top
      }

      Text(this.verified ? 'Verified!' : `Rotate to target to verify`)
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