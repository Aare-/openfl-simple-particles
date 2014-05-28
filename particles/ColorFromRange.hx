package particles;

class ColorFromRange {
    var _value : Color;
    public var value (get, set) : Color;
    public var scatter          : Color;
    var returnValue             : Color;

    function set_value( val : Color ) : Color {
        this._value = val;
        return this._value;
    }

    function get_value() : Color {
        returnValue.r = _value.r + (Math.random() * 2.0 - 1.0) * scatter.r;
        returnValue.g = _value.g + (Math.random() * 2.0 - 1.0) * scatter.g;
        returnValue.b = _value.b + (Math.random() * 2.0 - 1.0) * scatter.b;
        returnValue.a = _value.a + (Math.random() * 2.0 - 1.0) * scatter.a;
        return returnValue;
    }

    public function new(?xml : Xml, ?value : Color = null, ?scatter : Color = null) {
        returnValue = new Color();
        if(xml != null){
            this._value
            = new Color(Std.parseFloat(xml.get("r")) / 255.0,
            Std.parseFloat(xml.get("g")) / 255.0,
            Std.parseFloat(xml.get("b")) / 255.0,
            Std.parseFloat(xml.get("a")) / 255.0);
            this.scatter
            = new Color(Std.parseFloat(xml.get("rS")) / 255.0,
            Std.parseFloat(xml.get("gS")) / 255.0,
            Std.parseFloat(xml.get("bS")) / 255.0,
            Std.parseFloat(xml.get("aS")) / 255.0);
        }else{
            if(scatter == null)
                scatter = new Color(0.0, 0.0, 0.0, 0.0);
            this.scatter = scatter;
            _value = value;
        }
    }
}