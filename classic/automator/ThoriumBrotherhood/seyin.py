import sys
import time
from Quartz.CoreGraphics import *

# 测试完成后可改成100或其它次数
N = 1


def mouseEvent(type, posx, posy):
  theEvent = CGEventCreateMouseEvent(
      None, type, (posx, posy), kCGMouseButtonLeft)
  CGEventPost(kCGHIDEventTap, theEvent)


def mousemove(posx, posy):
  mouseEvent(kCGEventMouseMoved, posx, posy)


def mouseClick(posx, posy):
  mouseEvent(kCGEventLeftMouseDown, posx, posy)
  mouseEvent(kCGEventLeftMouseUp, posx, posy)


def mouseRightClick(posx, posy):
  mouseEvent(kCGEventRightMouseDown, posx, posy)
  mouseEvent(kCGEventRightMouseUp, posx, posy)


def clickLeftButton():
  # Move to the confirm button
  mousemove(104, 900 - 336)
  # 1 second delay
  time.sleep(0.5)
  # Click the confirm button
  mouseClick(104, 900 - 336)
  # 1 second delay
  time.sleep(0.5)


def clickMenu():
  # Click the menu
  mousemove(98, 900 - 619)
  time.sleep(0.5)
  mouseClick(98, 900 - 619)
  # 1 second delay
  time.sleep(0.5)


ourEvent = CGEventCreate(None)

# Save current mouse position
currentpos = CGEventGetLocation(ourEvent)

for _ in range(1, N):
  # Click the NPC
  mousemove(685, 448)
  time.sleep(1)
  mouseRightClick(685, 448)
  time.sleep(1)

  clickMenu()

  clickLeftButton()

  clickLeftButton()

# Restore mouse position
mousemove(int(currentpos.x), int(currentpos.y))
