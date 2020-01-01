from pynput.keyboard import Key, Controller, KeyCode, Listener
from pynput.mouse import Controller as MouseController, Button
import time
import random

looping = False

keyboard = Controller()
mouse = MouseController()


def jump():
    keyboard.press(Key.space)
    keyboard.release(Key.space)


def moveLeft():
    mouse.press(Button.right)
    keyboard.press('a')
    time.sleep(0.2)
    keyboard.release('a')
    time.sleep(0.1)
    mouse.release(Button.right)


def moveRight():
    mouse.press(Button.right)
    keyboard.press('d')
    time.sleep(0.2)
    keyboard.release('d')
    time.sleep(0.1)
    mouse.release(Button.right)


def moveForward():
    # move forward a step
    keyboard.press('w')
    time.sleep(0.2)
    keyboard.release('w')


def moveBackward():
    # move backward a step
    keyboard.press('s')
    time.sleep(0.2)
    keyboard.release('s')


def releaseSoul():
    mouse.position = (955, 230)
    mouse.press(Button.left)
    mouse.release(Button.left)


def loop():
    count = 0
    global looping
    while looping:
        # jump
        jump()
        # delay 1-10s
        time.sleep(random.uniform(1, 10))
 
        # choose a random direction move a step
        direct = random.choice('fblr')
        if direct == 'f':
            moveForward()
            moveBackward()
        elif direct == 'b':
            moveBackward()
            moveForward()
        elif direct == 'l':
            moveLeft()
            moveRight()
        elif direct == 'r':
            moveRight()
            moveLeft()

        # delay 1-10s
        time.sleep(random.uniform(1, 10))

        count += 1

        if count > 5:
            count = 0
            releaseSoul()

def on_press(key):
    try:
        # print('press key {0}, vk: {1}'.format(key.char, key.vk))
        if key == Key.f2:
            global looping
            if looping == False:
                looping = True
                loop()
    except AttributeError:
        print('special press key {0}, vk: {1}'.format(key, key.value.vk))


def on_release(key):
    if key == Key.esc:
        # stop listening
        global looping
        looping = False
        return False

    if key == Key.f3:
        global looping
        looping = False
        return False

    try:
        print('release key {0}, vk: {1}'.format(key.char, key.vk))
    except AttributeError:
        print('special release key {0}, vk: {1}'.format(key, key.value.vk))


# with Listener(on_press=on_press, on_release=on_release) as listener:
#     listener.join()

looping = True
loop()
