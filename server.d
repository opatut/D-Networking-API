import net;

import std.socket;
import std.stdio;
import std.conv;
import core.thread;
import std.variant;

import messages;

struct ASDF
{
    @property size_t length() {return 0;}
    
    ubyte[] data;
    
    alias data this;
}

int main() {
    auto server = new Server(9861);
    while(true) {
        server.update();
        foreach(con; server.connections)
        {//RECEIVE
            writeln("RECV:");
            con.receive(
                (MsgCharacterUpdate msg){ con.send(msg); },
                (ASDF msg){ con.send(msg); }
            );
        }
        Thread.sleep( dur!("msecs")( 1000 ) );
    }
    return 0;
}