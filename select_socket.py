#/usr/bin/env python
#coding=utf-8

'''
Created on 2018/1/10
@Author  : liwan
@note: select_socket

'''
import select
import socket
import sys
import queue

# Create a TCP/IP socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('localhost', 8001)
server.bind(server_address)
server.listen(1000)

server.setblocking(False)

inputs = [server, ]
outputs = []
message_queues = {}

while inputs:
    readable, writeable, exception = select.select(inputs, outputs, inputs)
    # print(readable, writeable, exception)
    for r in readable:
        if r is server:   #建立了一个新连接
            conn, addr = server.accept()
            print('new connection from', addr)
            conn.setblocking(False)
            inputs.append(conn)
            message_queues[conn] = queue.Queue()  #初始化一个队列，用于存储发送给这个连接的客户端的消息
        else:
            data = r.recv(1024)
            if data:
                print('received "%s" from %s' % (data, r.getpeername()))
                message_queues[r].put(data.upper())

                if r not in outputs:
                    outputs.append(r) #放入到返回的链接队列里
                # r.send(data.upper())
                # print("send done...")
            else:
                #没有数据就关闭连接
                print('closing after reading no data')
                if r in outputs:
                    outputs.remove(r)  # 既然客户端都断开了，我就不用再给它返回数据了，所以这时候如果这个客户端的连接对象还在outputs列表中，就把它删掉
                    inputs.remove(r)  # inputs中也删除掉
                    r.close()  # 把这个连接关闭掉

                    # Remove message queue
                    del message_queues[r]

    for w in writeable:   # 要返回给客户端的连接列表
        data_to_client = message_queues[w].get()  # 获取到要发送给当前连接的客户端的数据
        outputs.remove(w)  # 确保下次不会返回已经处理过的连接
        w.send(data_to_client)  # 发送给客户端的源数据

    for e in exception:  #如果在跟某个socket连接通信过程中出了错误，就把这个连接在inputs\outputs\msg_queue中都删除，再把连接关闭
        print('handling exceptional condition for', e.getpeername())
        inputs.remove(e)   # Stop listening for input on the connection
        if e in outputs:
            outputs.remove(e)
        e.close()

        del message_queues[e]

