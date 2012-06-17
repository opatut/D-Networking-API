import net;

import std.socket;
import std.stdio;
import std.conv;
import core.thread;

import messages;

int main()
{
    auto server = new Server(9861);
    while(true)
    {
        server.update();
        foreach(con; server.connections)
        {
            ubyte[][] msgs = con.receive();
            writeln(msgs);
            foreach(msg; msgs)
            {
                writeln(msg);
                con.send(msg);
            }
        }
        Thread.sleep( dur!("msecs")( 1000 ) );
    }
    return 0;
}