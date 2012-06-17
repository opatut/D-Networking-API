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
        foreach(msg; msgs)
        {
            Variant var = msg;
            this._send(*cast(ubyte[var.sizeof]*)&var);
        }
    }

        
    final void receive(T...)(scope T vals ) {
        static assert( T.length );
        alias TypeTuple!(T) Ops;
        alias vals[0 .. $] ops;
        
        ubyte[][] msgs = this._receive();
        foreach(msgdata; msgs)
        {            
            auto msg = *cast(Variant*)msgdata.ptr;
            foreach( i, t; Ops )
            {
                alias ParameterTypeTuple!(t) Args;
                auto op = ops[i];
                if( msg.convertsTo!(Args) )
                {
                    this._convert(msg, op);
                }
            }
        }
    }
    
private:
    final auto _convert(Op)(Variant msg, Op op )
    {
        alias ParameterTypeTuple!(Op) Args;

        static if( Args.length == 1 )
        {
            static if( is( Args[0] == Variant ) )
            {
                op( msg );
                return;
            }
            else
            {
                op( msg.get!(Args) );
                return;
            }
        }
        else
        {
            op( msg.get!(Tuple!(Args)).expand );
            return;
        }
    }

    void _send(Message message) {
        assert(this._socket.isAlive);
        assert(message.length <= uint.max);
        uint msgLength = message.length;
        ubyte[4] msgLengthU = *cast(ubyte[4]*)&msgLength;
        ptrdiff_t sendLength = this._socket.send(msgLengthU ~ message);
        assert(sendLength == msgLength+4);
    }
    
    @property Message[] _receive() {
        assert(this._socket.isAlive);
        ubyte[1024] buf;        
        ptrdiff_t len;
        while((len = this._socket.receive(buf)) > 0)
        {
            _buffer ~= buf[0..len];
        }
        
        //decode next messages in buffer
        Message[] messages;
        while(true)
        {
            if(this._buffer.length < 4)
                return messages;        
            uint messageLengthInBytes = *cast(uint*)this._buffer.ptr;
            if(messageLengthInBytes+4 < this._buffer.length)
                return messages;
            
            messages ~= this._buffer[4..messageLengthInBytes+4];
            this._buffer = this._buffer[messageLengthInBytes+4..$];
        }
    }
}


