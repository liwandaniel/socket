#/usr/bin/env python
#coding=utf-8

'''
Created on 2018/1/10
@Author  : liwan
@note: 创建大量连接测试并发量

'''
import socket
import sys

messages = [b'first',
            b'second',
            b'third',
            ]
server_address = ('0.0.0.0', 8001)

#测试高并发连接
socks = [socket.socket(socket.AF_INET, socket.SOCK_STREAM) for i in range(1000)]

# Connect the socket to the port where the server is listening
print('connecting to %s port %s' % server_address)
for s in socks:
    s.connect(server_address)

for message in messages:

    #所有的连接发送消息
    for s in socks:
        print('%s: sending "%s"' % (s.getsockname(), message))
        s.send(message)

    #处理所有收到的消息
    for s in socks:
        data = s.recv(1024)
        print('%s: received "%s"' % (s.getsockname(), data))
        if not data:
            print(sys.stderr, 'closing socket', s.getsockname())
