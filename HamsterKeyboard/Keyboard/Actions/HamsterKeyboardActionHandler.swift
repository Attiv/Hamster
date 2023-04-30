import KeyboardKit
import SwiftUI

class HamsterKeyboardActionHandler: StandardKeyboardActionHandler {
  public weak var hamsterKeyboardController: HamsterKeyboardViewController?
  // 全键盘滑动处理
  public let slidingGestureHandler: SlideGestureHandler
  public let appSettings: HamsterAppSettings
  public let rimeEngine: RimeEngine

  // 键盘滑动处理
  let characterDragAction: (HamsterKeyboardViewController) -> ((KeyboardAction, SlidingDirection, Int) -> Void) = { keyboardController in
    weak var ivc = keyboardController
    guard let ivc = ivc else { return { _, _, _ in } }

    // 滑动配置符号或功能映射
    let actionConfig: [String: String] = ivc.appSettings.keyboardSwipeGestureSymbol

    return { [weak ivc] action, direction, offset in
      guard let ivc = ivc else { return }

      var actionMappingValue: String?

      // 获取滑动动作的映射值
      switch action {
      case .character(let char):
        actionMappingValue = actionConfig[char.actionKey(direction)]
      case .backspace:
        actionMappingValue = actionConfig[.backspaceKeyName.actionKey(direction)]
      case .primary:
        actionMappingValue = actionConfig[.enterKeyName.actionKey(direction)]
      case .space:
        if direction.isXAxis && ivc.rimeEngine.suggestions.isEmpty {
          // 空格左右滑动
          ivc.adjustTextPosition(byCharacterOffset: offset)
          return
        }
        actionMappingValue = actionConfig[.spaceKeyName.actionKey(direction)]
      case .keyboardType(let type):
        if type == .numeric && ivc.keyboardContext.keyboardType.isAlphabetic {
          actionMappingValue = actionConfig[.numberKeyboardButton.actionKey(direction)]
        }
      default:
        break
      }

      guard let actionMappingValue = actionMappingValue else {
        return
      }

      Logger.shared.log.debug("sliding action mapping: \(actionMappingValue)")

      // #功能指令处理
      if ivc.functionalInstructionsHandled(actionMappingValue) {
        return
      }
      // 字符处理
      ivc.insertText(actionMappingValue)
    }
  }

  public init(
    inputViewController ivc: HamsterKeyboardViewController,
    keyboardContext: KeyboardContext,
    keyboardFeedbackHandler: KeyboardFeedbackHandler
  ) {
    weak var keyboardController = ivc
    self.hamsterKeyboardController = keyboardController
    self.appSettings = ivc.appSettings
    self.rimeEngine = ivc.rimeEngine
    self.slidingGestureHandler = HamsterSlidingGestureHandler(
      keyboardContext: keyboardContext,
      appSettings: appSettings,
      action: characterDragAction(ivc)
    )

    super.init(
      keyboardController: ivc,
      keyboardContext: ivc.keyboardContext,
      keyboardBehavior: ivc.keyboardBehavior,
      keyboardFeedbackHandler: ivc.keyboardFeedbackHandler,
      autocompleteContext: ivc.autocompleteContext
    )
  }

  override func action(for gesture: KeyboardGesture, on action: KeyboardAction) -> KeyboardAction
    .GestureAction?
  {
    if let hamsterAction = action.hamsterStanderAction(for: gesture) {
      return hamsterAction
    }
    return nil
  }

  override func handle(
    _ gesture: KeyboardKit.KeyboardGesture, on action: KeyboardKit.KeyboardAction
  ) {
    handle(gesture, on: action, replaced: false)
  }

  override func handle(_ gesture: KeyboardGesture, on action: KeyboardAction, replaced _: Bool) {
    // 反馈触发
    triggerFeedback(for: gesture, on: action)
    guard let gestureAction = self.action(for: gesture, on: action) else { return }
    // TODO: 这里前后可以添加中英自动加入空格等特性
    gestureAction(keyboardController)
    // 这里改变键盘类型: 比如双击, 不能在KeyboardAction+Action那里改
    tryChangeKeyboardType(after: gesture, on: action)
    keyboardController?.performTextContextSync()
  }

  /**
   Try to change `keyboardType` after a `gesture` has been
   performed on the provided `action`.
   */
  override func tryChangeKeyboardType(after gesture: KeyboardGesture, on action: KeyboardAction) {
    guard keyboardBehavior.shouldSwitchToPreferredKeyboardType(after: gesture, on: action) else { return }
    let newType = keyboardBehavior.preferredKeyboardType(after: gesture, on: action)
    keyboardContext.keyboardType = newType
  }

  override func triggerFeedback(for gesture: KeyboardGesture, on action: KeyboardAction) {
    guard shouldTriggerFeedback(for: gesture, on: action) else { return }
    keyboardFeedbackHandler.triggerFeedback(for: gesture, on: action)
  }

  override func handleDrag(
    on action: KeyboardAction, from startLocation: CGPoint, to currentLocation: CGPoint
  ) {
    switch action {
    case .space:
      // space滑动的的开关判断
      slidingGestureHandler.handleDragGesture(action: action, from: startLocation, to: currentLocation)
    default:
      if appSettings.enableKeyboardSwipeGestureSymbol {
        slidingGestureHandler.handleDragGesture(action: action, from: startLocation, to: currentLocation)
      }
    }
  }
}

private extension String {
  // 空格名称
  static let spaceKeyName = "space"
  // 删除键名称
  static let backspaceKeyName = "backspace"
  // 回车键名称
  static let enterKeyName = "enter"

  // 数字键盘切换键
  static let numberKeyboardButton = "123"

  // 获取滑动ActionKey
  func actionKey(_ slidingDirection: SlidingDirection) -> String {
    var actionKey: String
    if slidingDirection.isXAxis {
      actionKey = lowercased() + (slidingDirection == .right ? KeyboardConstant.Character.SlideRight : KeyboardConstant.Character.SlideLeft)
    } else {
      actionKey = lowercased() + (slidingDirection == .down ? KeyboardConstant.Character.SlideDown : KeyboardConstant.Character.SlideUp)
    }
    return actionKey
  }
}
