package particles;

import flash.geom.Rectangle;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;


class ParticleSystem extends Sprite {

    public var active : Bool = false;
    public var emitters : Map<String, ParticleEmitter>;
    public var pos : Point;

    public function new( _pos:Point) {

        super();

        if(emitters == null) new Map<String, ParticleEmitter>();

        pos = _pos;
    }

    public function add_emitter(_name:String, _template:Dynamic) {

        if(emitters == null) emitters = new Map<String, ParticleEmitter>();

            //create the emitter instance
        var _emitter = new ParticleEmitter(this, _template);
            //store the reference of the emitter
        emitters.set(_name, _emitter);

    }

    public function emit(duration : Float = -1) {
        active = true;
        for(emitter in emitters) {
            emitter.emit(duration);
        }
    }

    public function stop() {
        active = false;
        for(emitter in emitters) {
            emitter.stop();
        }        
    }

    public function destroy() {
        for(emitter in emitters)
            emitter.destroy();
    }

    public function update(dt : Float) {
        if(!active) return;
        for(emitter in emitters)
            emitter.update(dt);

    }

    //default - debug renderer
    public static function bitmapParticleFunctionRenderFactory(emiter : ParticleEmitter, bitmapData : BitmapData){
        var spritesArray   : Array<Sprite> = [];
        var posCounter     : Int;
        var particle_image : BitmapData = bitmapData;

        emiter.beforeRender = inline function(){
            posCounter = 0;
        };
        emiter.renderParticle = inline function(particle : Particle){
            if(spritesArray.length <= posCounter){
                var particleSprite = new Sprite();
                var b = new Bitmap( particle_image );
                b.x -= particle_image.width  / 2;
                b.y -= particle_image.height / 2;

                particleSprite.addChild( b );

                spritesArray.push(particleSprite);
                emiter.particle_system.addChild( particleSprite );
            }

            spritesArray[posCounter].visible = true;
            spritesArray[posCounter].width = particle.start_size.x;
            spritesArray[posCounter].height = particle.start_size.y;

            // particle.sprite.color = particle.color;
            spritesArray[posCounter].x = particle.position.x;
            spritesArray[posCounter].y = particle.position.y;
            spritesArray[posCounter].rotation = particle.rotation;
            spritesArray[posCounter].alpha = particle.color.a;

            posCounter++;
        };
        emiter.afterRender = inline function(){
            for(i in posCounter ... spritesArray.length)
                spritesArray[i].visible = false;
        };
    }
}

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

    public function new(value : Float, ?scatter : Float = 0.0){
        this.value = value;
        this.scatter = scatter;
    }
}

class PointFromRange {
    public var x : FloatFromRange;
    public var y : FloatFromRange;

    public function new(value : Point, ?scatter : Point = null){
        if(scatter == null)
            scatter = new Point(0, 0);

        x = new FloatFromRange(value.x, scatter.x);
        y = new FloatFromRange(value.y, scatter.y);
    }
}

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

    public function new(value : Color, ?scatter : Color = null){
        returnValue = new Color();
        if(scatter == null)
            scatter = new Color(0.0, 0.0, 0.0, 0.0);
        this.scatter = scatter;
        _value = value;
    }
}

class ParticleEmitter {
    public var particle_system : ParticleSystem;

    public var active : Bool = true;
    public var emit_count : Int = 1;
    public var particles : Array<Particle>;

    public var elapsed_time : Float = 0;
    public var duration : Float = -1;
    public var emission_rate : Float = 0;    
    public var emit_next : Float = 0;
    public var emit_last : Float = 0;
    public var particle_index : Int = 0;

    var emit_timer : Float = 0;

    //emitter properties
    public var emiterShape : Rectangle;
    public var gravity : Point;
    public var emit_time : Float;

    /* direction of emmiter, in degrees*/
    public var direction       : FloatFromRange;
    public var zrotation       : FloatFromRange;
    public var rotation_offset : Float;
    public var radius          : FloatFromRange;

    //particle properties
    public var start_size : PointFromRange;
    public var end_size   : PointFromRange;
    public var velocity   : FloatFromRange;
    public var life       : FloatFromRange;
    
    public var rotation_value  : FloatFromRange;
    public var end_rotation    : FloatFromRange;

    public var start_color : ColorFromRange;
    public var end_color   : ColorFromRange;

    //rendering particles - inline this functions for best performance
    public var beforeRender   : Void -> Void;
    public var renderParticle : Particle -> Void;
    public var afterRender    : Void -> Void;

    //internal stuff
    public var template : Dynamic = null;

    var finish_time : Float = 0;

    var has_end_rotation : Bool = false;

    public function new(_system:ParticleSystem, _template:Dynamic) {   

        template = _template;
        particle_system = _system;

        particles = new Array<Particle>();
        emiterShape = new Rectangle(particle_system.pos.x, particle_system.pos.y, 0, 0);
 
        emit_timer = 0;
        emit_last = 0;
        emit_next = 0;
            
        //apply defaults
        apply(template);
    }

    public function apply(_template:Dynamic) {
        if(_template == null) _template = {};

        (_template.emit_time != null) ? 
            emit_time = _template.emit_time : 
            emit_time = 0.1;

        (_template.emit_count != null) ? 
            emit_count = _template.emit_count : 
            emit_count = 1;

        (_template.direction != null) ? 
            direction = _template.direction : 
            direction = new FloatFromRange(0.0);

        (_template.velocity != null) ?
            velocity = _template.velocity :
            velocity = new FloatFromRange(0.0);

        (_template.life != null) ?
            life = _template.life : life = new FloatFromRange(1.0);

        (_template.rotation != null) ?
            zrotation = _template.rotation : 
            zrotation = new FloatFromRange(0.0);

        (_template.rotation_offset != null) ?
            rotation_offset = _template.rotation_offset :
            rotation_offset = 0.0;

        (_template.end_rotation != null) 
            ? { end_rotation = _template.end_rotation;  has_end_rotation = true;  }
            : { end_rotation = new FloatFromRange(0.0); has_end_rotation = false; }

        if(_template.emiter_shape != null)
            emiterShape.setTo(particle_system.pos.x + _template.emiter_shape.x,
                              particle_system.pos.y + _template.emiter_shape.y,
                              _template.emiter_shape.width, _template.emiter_shape.height);
        else
            emiterShape.setTo(particle_system.pos.x, particle_system.pos.x,
                              0, 0);

        (_template.gravity != null) ?
            gravity = _template.gravity : 
            gravity = new Point(0,-80);

        (_template.start_size != null) ?
            start_size = _template.start_size : 
            start_size = new PointFromRange(new Point(32, 32));

        (_template.end_size != null) ?
            end_size = _template.end_size : 
            end_size = new PointFromRange(new Point(128,128));

        (_template.start_color != null) ? 
            start_color = _template.start_color :
            start_color = new ColorFromRange(new Color(1,1,1,1));

        (_template.end_color != null) ?
            end_color = _template.end_color :
            end_color = new ColorFromRange(new Color(0,0,0,0));
    } //apply

    public function destroy() {
        particles = null;
    }

    public function emit(t : Float){
        duration = t;
        active = true;
        emit_last = 0;
        emit_timer = 0;
        emit_next = 0;

        if(duration != -1) {
            finish_time = haxe.Timer.stamp() + duration;
        }else{
            finish_time = -1;
        }
    } 

    public function stop() {
        active = false;
        elapsed_time = 0;
        emit_timer = 0;
    }

    private function spawn() {
        var particle = null;
        for(p in particles)
            if(!p.active){
                particle = p;
                break;
            }

        if(particle == null){
            particle = new Particle(this);
            particles.push(particle);
        }
        
        init_particle( particle );
    }

    function multiply_point(target:Point, a:Point, b:Point) : Point {
        target.setTo( a.x*b.x, a.y*b.y );
        return target;
    }
    function multiply_point_with_float(target:Point, a:Point, b:Float) : Point {
        target.setTo( a.x*b, a.y*b );
        return target;
    }

    private function init_particle( particle:Particle ) {
        particle.active = true;

        particle.rotation = zrotation.value + rotation_offset;

        particle.position.x = emiterShape.x + Math.random() * emiterShape.width;
        particle.position.y = emiterShape.y + Math.random() * emiterShape.height;

        var new_dir = direction.value * ( Math.PI / 180 ); // convert to radians
        var new_velocity = velocity.value;

        particle.velocity.setTo(Math.cos( new_dir ) * new_velocity,
                                Math.sin( new_dir ) * new_velocity);
        particle.acceleration.setTo(0, 0);

        particle.start_size.x = Math.floor(Math.max(0.0, start_size.x.value));
        particle.start_size.y = Math.floor(Math.max(0.0, start_size.y.value));

        particle.time_to_live = life.value;

        particle.size_delta.x = ( end_size.x.value - particle.start_size.x ) / particle.time_to_live;
        particle.size_delta.y = ( end_size.y.value - particle.start_size.y ) / particle.time_to_live;

        particle.color     = new Color( start_color.value );
        var end_color : Color =  new Color( end_color.value );

        particle.color_delta.r = ( end_color.r - particle.color.r ) / particle.time_to_live;
        particle.color_delta.g = ( end_color.g - particle.color.g ) / particle.time_to_live;
        particle.color_delta.b = ( end_color.b - particle.color.b ) / particle.time_to_live;
        particle.color_delta.a = ( end_color.a - particle.color.a ) / particle.time_to_live;

        if(has_end_rotation)
            particle.rotation_delta  = ( end_rotation.value - particle.rotation ) / particle.time_to_live;
    } //init_particle

    public function update(dt : Float) {

        if( active ) { // && emission_rate > 0            

            emit_timer = haxe.Timer.stamp();

            if( emit_timer > emit_next ) {                
                emit_next = emit_timer + emit_time; 
                emit_last = emit_timer;
                for(i in 0 ... emit_count)
                    spawn();
            }

            if(finish_time != -1 &&
               (duration != -1 && emit_timer > finish_time) )
                stop();

        } //if active and still emitting

        //update all active particles
        if(beforeRender != null) beforeRender();
        for(current_particle in particles) {
            if(!current_particle.active) continue;

            //die over time
            current_particle.time_to_live -= dt;

            // If the current particle is alive
            if( current_particle.time_to_live > 0 ) {
                //updating velocity by acceleration
                current_particle.velocity.x
                    = current_particle.velocity.x + (current_particle.acceleration.x + gravity.x) * dt;
                current_particle.velocity.y
                    = current_particle.velocity.y + (current_particle.acceleration.y + gravity.y) * dt;

                //updating position by velocity
                current_particle.position.x
                    = current_particle.position.x + current_particle.velocity.x * dt;
                current_particle.position.y
                    = current_particle.position.y + current_particle.velocity.y * dt;

                // update colours based on delta
                var r = current_particle.color.r += ( current_particle.color_delta.r * dt );
                var g = current_particle.color.g += ( current_particle.color_delta.g * dt );
                var b = current_particle.color.b += ( current_particle.color_delta.b * dt );
                var a = current_particle.color.a += ( current_particle.color_delta.a * dt );

                //clamp colors
                if(r < 0) { r = 0; } if(g < 0) { g = 0; } if(b < 0) { b = 0; } if(a < 0) { a = 0; }
                if(r > 1) { r = 1; } if(g > 1) { g = 1; } if(b > 1) { b = 1; } if(a > 1) { a = 1; }

                //updatying visuals
                current_particle.start_size.x += ( current_particle.size_delta.x * dt );
                current_particle.start_size.y += ( current_particle.size_delta.y * dt );
                current_particle.rotation += ( current_particle.rotation_delta * dt );

                if(renderParticle != null)
                    renderParticle(current_particle);
            } else {
                current_particle.active = false;
            }
        }

        if(afterRender != null) afterRender();
    }

  //utils
    private function normalise(vec : Point){
        var len : Float = Math.sqrt(Math.pow(vec.x, 2) + Math.pow(vec.y, 2));
        vec.x /= len;
        vec.y /= len;
    }
} //ParticleEmitter

class Particle {
    public var active : Bool;

    public var particle_system : ParticleSystem;
    public var particle_emitter : ParticleEmitter;

    public var start_size : Point;
    public var position   : Point;

    public var velocity     : Point;
    public var acceleration : Point;

    public var time_to_live : Float = 0;
    public var rotation     : Float = 0;
    
    public var color          : Color;
    public var color_delta    : Color;
    public var size_delta     : Point;
    public var rotation_delta : Float = 0;

    public function new(e : ParticleEmitter) {
        particle_emitter = e;
        particle_system = e.particle_system;

        velocity = new Point();
        acceleration = new Point();

        position = new Point();
        start_size = new Point();
        size_delta = new Point();

            //delta must be 0
        color_delta = new Color(0,0,0,0);
        color = new Color();
    }

    static var tmpParticle : Particle;

    inline static function copyPoint(a : Point, b : Point){
        a.setTo(b.x, b.y);
    }

    static function copy(a : Particle, b : Particle){
        a.active = b.active;
        a.particle_emitter = b.particle_emitter;
        a.particle_system = b.particle_system;

        copyPoint(a.velocity, b.velocity);
        copyPoint(a.acceleration, b.acceleration);
        copyPoint(a.position, b.position);
        copyPoint(a.start_size, b.start_size);
        copyPoint(a.size_delta, b.size_delta);

        a.color_delta.set(b.color_delta);
        a.color.set(b.color);
    }

    public static function swap(a : Particle, b : Particle){
        if(tmpParticle == null)
            tmpParticle = new Particle(null);
        copy(tmpParticle, a);
        copy(a, b);
        copy(b, tmpParticle);
    }
}

class Color {
    public var r : Float;
    public var g : Float;
    public var b : Float;
    public var a : Float;
    
    public function new( ?color : Color = null, _r:Float = 1.0, _g:Float = 1.0, _b:Float = 1.0, _a:Float = 1.0 ) {
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