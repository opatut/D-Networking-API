D-Networking-API
================

A Networking API for the D programming language. 
Currently just a concept to use the message passing interface from std.concurrency. 
overhead currently is 4byte(msgLength) + 16byte(typeHash)  per message.


================

Example usage:

    int main()
    {
        auto con = Connection.connect(new InternetAddress("127.0.0.1", 9861));
        while(true)
        {
            {//SEND
                MsgCharacterUpdate msg;
                msg.position = [12,13,14];
                msg.orientation = [55,66,77,88];
                msg.scale = [1,2,3];
                
                writeln("SEND:\n", msg);
                con.send(msg);
                writeln();
            }
            
            {//RECEIVE
                writeln("RECV:");
                con.receive(
                    (MsgCharacterUpdate msg){ writeln("MsgCharUpdate: ", msg); },
                    (int i){writeln("INT: ", i);}
                );
            }
            
            Thread.sleep( dur!("msecs")( 1000 ) );
        }
        return 0;
    }