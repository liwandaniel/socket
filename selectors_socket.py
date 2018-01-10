#/usr/bin/env python
#coding=utf-8

'''
Created on 2018/1/10
@Author  : liwan
@note: selectors 模块，实现高效的IO多路复用，默认使用epoll来实现，如果机器不支持epoll，就用select

'''
import selectors
import socket

sel = selectors.DefaultSelector()


def accept(sock, mask):
    conn, addr = sock.accept()
    print('accepted', conn, 'from', addr)
    conn.setblocking(False)
    sel.register(conn, selectors.EVENT_READ, read) #新的连接调用回调函数read


def read(conn, mask):
    data = conn.recv(1024)
    if data:
        print('echoing', repr(data), 'to', conn)
        conn.send(data)
    else:
        print('closing', conn)
        sel.unregister(conn)  # 取消注册
        conn.close() #关闭连接


sock = socket.socket()
sock.bind(('0.0.0.0', 8001))
sock.listen(100)
sock.setblocking(False)
sel.register(sock, selectors.EVENT_READ, accept)  # 注册事件，只要检测到一个新连接，就调用accept函数

while True:
    events = sel.select() #默认阻塞，有活动连接就返回活动连接的列表
    for key, mask in events:
        callback = key.data  #回调函数就相当于调用accept
        callback(key.fileobj, mask)