package particles;

import flash.geom.Point;
class PointFromRange {
    public var x : FloatFromRange;
    public var y : FloatFromRange;

    public function new(?xml : Xml = null, ?value : Point=null, ?scatter : Point = null){
        if(xml != null){
            x = new FloatFromRange(xml.elementsNamed("x").next());
            y = new FloatFromRange(xml.elementsNamed("y").next());
        }else{
            if(scatter == null)
                scatter = new Point(0, 0);

            x = new FloatFromRange(value.x, scatter.x);
            y = new FloatFromRange(value.y, scatter.y);
        }
    }
}
