module messages;

import std.conv;

alias int[2] Vector2;
alias int[3] Vector3;
alias int[4] Quaternion;

struct MsgCharacterUpdate {
public:
    Vector3 position;
    Quaternion orientation;
    Vector3 scale;

    string toString() {
        return  "Position: " ~ position.to!(string) ~ "\n" ~
                "Orientation: " ~ orientation.to!(string) ~ "\n" ~
                "Scale: " ~ scale.to!(string);
    }
    
    ubyte[] data() {
        auto tmp = position~orientation~scale;
        return *cast(ubyte[tmp.sizeof]*)tmp.ptr;
    }
    
    alias data this;
}