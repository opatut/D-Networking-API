/**
 * A Very Simple Socket Wrapper.
 * It splits a TCP-Stream into 'Messages' 
 * which are ubyte[] with a specific length.
 * each message currently has an overhead of 9byte.
 *
 * TODO: add checks for isAlive
 */
module net;

import std.socket;
import std.stdio;
import std.range;
import std.traits;
import std.typecons;
import std.typetuple;
import std.algorithm;

class Server {
private:
    TcpSocket _socket;
    Connection[] _connections;
    
public:
    ///
    this(ushort port) {
        this._socket = new TcpSocket();
        this._socket.bind(new InternetAddress(port));
        this._socket.listen(1);
        this._socket.blocking = false;
        assert(this._socket.isAlive);
    }
    
    ///
    ~this() {
        this.close();
    }
    
    ///
    void close() {
        assert(this._socket.isAlive);
        this._socket.shutdown(SocketShutdown.BOTH);
        this._socket.close();
    }
    
    ///
    @property Connection[] connections() {
        return this._connections;
    }
    
    ///
    void update() {
        assert(this._socket.isAlive);
        try {
            Socket socket = this._socket.accept();
            if(socket is null || !socket.isAlive)
                return;
            auto con = new Connection();
            this._connections ~= con;
            con._socket = socket;
		} catch(SocketAcceptException e) {
            //writeln("socket accept error");
        }
    }
}

class Connection {
private:   
    alias ubyte[] Message;
    Socket _socket;
    ubyte[] _buffer;
    
    string[] _localMap;
    string[] _remoteMap;
     
    alias ulong MangleLenType;
    
    enum MsgType : ubyte {
        PublishType,
        SendMsg
    }
    
public:
    ///
    static Connection connect(Address addr) {
        auto con = new Connection();
        con._socket = new TcpSocket(addr);
        assert(con._socket.isAlive);
        con._socket.blocking = false;        
        return con;
    }
    
    ///
    ~this() {
        this.close();
    }
    
    ///
    void close() {
        if(!this._socket.isAlive)
            return;
        this._socket.shutdown(SocketShutdown.BOTH);
        this._socket.close();
    }    
    
public:
    ///
    final void send(T)(T msg) {
        if(!this._socket.isAlive)
            return;
        auto pos = this._localMap.countUntil(T.mangleof);
        if(pos == -1) {
            //publish type first
            this._localMap ~= T.mangleof;
            MangleLenType mangleLen = T.mangleof.length;
            this._socket.send(
                MsgType.PublishType ~ 
                *cast(ubyte[MangleLenType.sizeof]*)&mangleLen ~ 
                cast(ubyte[])T.mangleof
            );
            pos = this._localMap.length-1;
            debug {                
                writeln(
                "sent: ",MsgType.PublishType ~ 
                *cast(ubyte[MangleLenType.sizeof]*)&mangleLen ~ 
                cast(ubyte[])T.mangleof
                );
            }
        }
        
        //send msg
        uint msgLen = cast(uint)msg.length;
        this._socket.send(
            MsgType.SendMsg ~
            *cast(ubyte[uint.sizeof]*)&pos ~
            *cast(ubyte[uint.sizeof]*)&msgLen ~
            cast(ubyte[])msg
        );
    }
    
    ///
    final void receive(T...)(scope T vals ) { 
        if(!this._socket.isAlive)
            return;
        static assert(T.length, "receive needs at least one function.");
        alias TypeTuple!(T) Ops;
        alias vals[0 .. $] ops;
        
        //get all bytes from socket and store in this._buffer
        assert(this._socket.isAlive);
        ubyte[1024] buf;
        ptrdiff_t len;
        while((len = this._socket.receive(buf)) > 0) {
            this._buffer ~= buf[0..len];
        }
        
        //enough buffer to decode a MsgType?
        if(this._buffer.length < MsgType.sizeof)
            return;
        
        MsgType msgType = *cast(MsgType*)this._buffer[0 .. MsgType.sizeof].ptr;
        final switch(msgType) {
        case MsgType.PublishType:
            //enough buffer to decode mangleLen?
            if(this._buffer.length < MsgType.sizeof + MangleLenType.sizeof)
                return;
            
            MangleLenType mangleLen = *cast(MangleLenType*)this._buffer[MsgType.sizeof .. MsgType.sizeof + MangleLenType.sizeof].ptr;
            
            //enough buffer to decode mangle?
            if(this._buffer.length < MsgType.sizeof + MangleLenType.sizeof + cast(size_t)mangleLen)
                return;
            
            string mangle = cast(string)this._buffer[MsgType.sizeof + MangleLenType.sizeof .. MsgType.sizeof + MangleLenType.sizeof + cast(size_t)mangleLen];
            
            this._remoteMap ~= mangle;
            this._buffer = this._buffer[MsgType.sizeof + MangleLenType.sizeof + cast(size_t)mangleLen .. $];          
            
            break;
        case MsgType.SendMsg:
            //enough buffer to decode typeID
            if(this._buffer.length < MsgType.sizeof + uint.sizeof)
                return;
            
            uint pos = *cast(uint*)this._buffer[MsgType.sizeof .. MsgType.sizeof + uint.sizeof].ptr;
            assert(pos < this._remoteMap.length, "could not find mangleof in _remoteMap."); //TODO: add that check in release?!
        
            string mangle = this._remoteMap[pos];
            
            foreach( i, t; Ops ) {
                alias ParameterTypeTuple!(t) Args;
                auto op = ops[i];
                
                static if( Args.length == 1 ) {
                    if(Args[0].mangleof == mangle) {
                        
                        //enough buffer to decode msgLen?
                        if(this._buffer.length < MsgType.sizeof + uint.sizeof + uint.sizeof)
                            return;
                        
                        uint msgLen = *cast(uint*)this._buffer[MsgType.sizeof + uint.sizeof .. MsgType.sizeof + uint.sizeof + uint.sizeof].ptr;
                        
                        //enough buffer to decode msg?
                        if(this._buffer.length < MsgType.sizeof + uint.sizeof + uint.sizeof + msgLen)
                            return;
                        
                        auto msg = *cast(Args[0]*)this._buffer[MsgType.sizeof + uint.sizeof + uint.sizeof .. MsgType.sizeof + uint.sizeof + uint.sizeof + msgLen].ptr;
                        this._buffer = this._buffer[MsgType.sizeof + uint.sizeof + uint.sizeof + msgLen .. $];
                        
                        op(msg);
                    }
                }
                else
                    static assert(false, "Only one Parameter supported in receive functions.");
            }                
            
            break;
        }
    }
}


