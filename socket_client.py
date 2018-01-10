#/usr/bin/env python
#coding=utf-8

'''
Created on 2018/1/9
@Author  : liwan
@note: socket_client

'''

import socket

HOST = 'localhost'  # The remote host
PORT = 8001  # The same port as used by the server
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
while True:
    msg = bytes(input(">>:"), encoding="utf8")
    s.sendall(msg)
    data = s.recv(1024)
    print('Received', repr(data))

# s.close()