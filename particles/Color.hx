package particles;

class Color {
    public var r : Float;
    public var g : Float;
    public var b : Float;
    public var a : Float;

    public function new( ?color : Color = null, _r : Float = 1.0, _g : Float = 1.0, _b : Float = 1.0, _a : Float = 1.0 ) {
        set(color, _r, _g, _b, _a);
    }

    public function set( ?color : Color = null,
                         ?_r : Float = -1, ?_g : Float = -1, ?_b : Float = -1, ?_a : Float = -1 ) : Color {
        if(color != null){
            this.r = color.r;
            this.g = color.g;
            this.b = color.b;
            this.a = color.a;

            return this;
        }

        if(r != -1){
            r = _r;
            g = _g;
            b = _b;
            a = _a;
        }

        return this;
    }

    public function rgb(_rgb:Int = 0xFFFFFF) : Color {
        from_int(_rgb);
        return this;
    } //rgb

    private function from_int(_i:Int) {
        var _r = _i >> 16;
        var _g = _i >> 8 & 0xFF;
        var _b = _i & 0xFF;

//convert to 0-1
        r = _r / 255;
        g = _g / 255;
        b = _b / 255;

//alpha not specified in 0xFFFFFF
//but we don't need to clobber it,
//it was set in the member list
// a = 1.0;
    }
}