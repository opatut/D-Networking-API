import net;

import std.socket;
import std.stdio;
import std.conv;
import core.thread;

import messages;
import std.variant;

import std.traits;
import std.conv;



int main()
{    
    auto con = Connection.connect(new InternetAddress("127.0.0.1", 9861));
    int i = 0;
    while(true)
    {
        i++;
        {//SEND
            MsgCharacterUpdate msg;
            msg.position = [i,i,i];
            msg.orientation = [i,i,i,i];
            msg.scale = [i,i,i];
            
            writeln("SEND:\n");
            //con.send(12345);
            con.send(msg);
            writeln("--------");
            writeln();
        }
        
        {//RECEIVE
            writeln("RECV:");
            con.receive(
                (MsgCharacterUpdate msg){ writeln(msg); },
                (int i){writeln("INT: ", i);}
            );
            writeln("--------");
            writeln();
        }
        
        Thread.sleep( dur!("msecs")( 1000 ) );
    }
    return 0;
}