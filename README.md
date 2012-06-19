D-Networking-API
================

A Networking API for the D programming language. 
Currently just a concept to use the message passing interface from std.concurrency. 
overhead currently is 9byte per message.


================

Example usage:


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