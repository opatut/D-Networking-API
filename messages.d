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
    
    @property ubyte[] data() {
        auto tmp = position~orientation~scale;
        return *cast(ubyte[Vector3.sizeof+Quaternion.sizeof+Vector3.sizeof]*)tmp.ptr;
    }
    
    this(ubyte[] msg) {
        position = *cast(Vector3*)msg.ptr;
        orientation = *cast(Quaternion*)(msg.ptr+Vector3.sizeof);
        scale = *cast(Vector3*)(msg.ptr+orientation.sizeof+scale.sizeof);
    }
    
    //~ void opAssign(ubyte[] msg) {
    //~ }
    
    alias data this;
    
    //alias setdata this;
}