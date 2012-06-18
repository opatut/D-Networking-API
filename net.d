/**
 * A Very Simple Socket Wrapper.
 * It splits a TCP-Stream into 'Messages' 
 * which are ubyte[] with a specific length.
 * each message currently has an overhead of 4byte.
 *
 * TODO: add checks for isAlive
 */
module net;

import std.socket;
import std.conv;
import std.stdio;
    import std.range;
    import std.traits;
    import std.typecons;
    import std.typetuple;
import std.variant;
    import std.algorithm;
import std.md5;

ubyte[16u] uniqueId(T)() {
    ubyte[16u] digest;
    sum(digest, T.mangleof);
    return digest;
}

class Server {
private:
    TcpSocket _socket;
    Connection[] _connections;
    
public:
    this(ushort port) {
        writeln("start server");
        this._socket = new TcpSocket();
        writeln("bind server");
        this._socket.bind(new InternetAddress(port));
        writeln("listen server");
        this._socket.listen(1);
        writeln("setblcking server");
        this._socket.blocking = false;
        writeln("alive server");
        assert(this._socket.isAlive);
    }
    
    ~this() {
        this.close();
    }
    
    void close() {
        assert(this._socket.isAlive);
        this._socket.shutdown(SocketShutdown.BOTH);
        this._socket.close();
    }
    
    @property Connection[] connections() {
        return this._connections;
    }
    
    void update() {
        assert(this._socket.isAlive);
        try {
            Socket socket = this._socket.accept();
            if(socket is null || !socket.isAlive)
                return;
            auto con = new Connection();
            this._connections ~= con;
            con._socket = socket;
            writeln("new socket");
		} catch(SocketAcceptException e) {
            //writeln("socket accept error");
        }
    }
}

class Connection {
    alias ubyte[] Message;
    Socket _socket;
    ubyte[] _buffer;
    
public:
    static Connection connect(Address addr) {
        auto con = new Connection();
        con._socket = new TcpSocket(addr);
        assert(con._socket.isAlive);
        con._socket.blocking = false;
        return con;
    }
    
    ~this() {
        this.close();
    }
    
    void close() {
        assert(this._socket.isAlive);
        this._socket.shutdown(SocketShutdown.BOTH);
        this._socket.close();
    }
    
public:
    final void send(T...)( T msgs ) {
        foreach(msg; msgs) {
            ubyte[] data;

            static if(isImplicitlyConvertible!(typeof(msg), ubyte[]))
                data = msg;
            else static if(isNumeric!(typeof(msg)))
                data = *cast(ubyte[msg.sizeof]*)&msg;
            else
                static assert(false, "Type " ~ typeof(msg).stringof ~ " cannot be sent.");
            
            uint len = data.length;
            ubyte[16u] type = uniqueId!(T);
            this._socket.send(
                *cast(ubyte[len.sizeof]*)&len ~
                *cast(ubyte[type.sizeof]*)&type ~
                data
            );
        }
    }

    final void receive(T...)(scope T vals ) {   
        static assert( T.length );
        alias TypeTuple!(T) Ops;
        alias vals[0 .. $] ops;        
        assert(this._socket.isAlive);
        ubyte[1024] buf;
        ptrdiff_t len;
        while((len = this._socket.receive(buf)) > 0) {
            _buffer ~= buf[0..len];
        }
        //decode next messages in buffer
        ubyte[][] messages;
        while(true) {            
            //has length and type?
            enum beg = uint.sizeof + (ubyte[16u]).sizeof;
            if(this._buffer.length < beg)
                return;       
            
            uint msgLen = *cast(uint*)this._buffer.ptr;
            ubyte[16u] msgType = *cast(ubyte[16u]*)(this._buffer.ptr + uint.sizeof);
            
            uint end = beg+msgLen;
            
            //has complete msg?
            if(this._buffer.length < end)
                return;
            
            ubyte[] msgData = this._buffer[beg .. end];
            this._buffer = this._buffer[end .. $];
                        
            foreach( i, t; Ops ) {
                alias ParameterTypeTuple!(t) Args;
                auto op = ops[i];
                
                static if( Args.length == 1 ) {
                    if(uniqueId!(Args[0]) == msgType) {
                        writeln(msgData);
                        static if(isImplicitlyConvertible!(Args[0], ubyte[]))
                            op(cast(Args[0])msgData);
                        else static if(isNumeric!(Args[0]))
                            op(*cast(Args[0]*)msgData.ptr);
                        else
                            static assert(false, "Type " ~ Args[0].stringof ~ " is not supported.");
                    }
                }
                else
                    static assert(false, "Only one Parameter supported.");
            }
        }
    }
}


