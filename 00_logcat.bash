#!/bin/bash

adb logcat | grep -iE "crash|exception|fatal"
