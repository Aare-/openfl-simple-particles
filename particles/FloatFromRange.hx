package particles;

class FloatFromRange {
    var _value : Float;
    public var value (get, set)   : Float;
    public var scatter : Float;

    function set_value( val : Float) : Float{
        _value = val;
        return _value;
    }

    function get_value() : Float {
        return (Math.random() * 2.0 - 1.0) * scatter + _value;
    }

    public function new(?x : Xml = null, ?value : Float = 0.0, ?scatter : Float = 0.0){
        if(x != null){
            this.value = Std.parseFloat(x.get("value"));
            this.scatter = (x.exists("scatter") ? Std.parseFloat(x.get("scatter")) : 0.0);
        }else{
            this.value = value;
            this.scatter = scatter;
        }
    }
}