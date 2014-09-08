package particles;

import flash.geom.Point;
import flash.geom.Rectangle;

class ParticleEmitter {
    public var particle_system : ParticleSystem;
    public var name : String;

    public var active : Bool = true;
    public var emit_count : Int = 1;
    public var particles : Array<Particle>;

    public var emission_rate : Float = 0;
    public var particle_index : Int = 0;

    var emit_timer : Float = 0;

    //emitter properties
    public var emiterShape : Rectangle;
    public var gravity : Point;
    public var emit_time : Float;
    public var duration  : Float;

/* direction of emmiter, in degrees*/
    public var direction       : FloatFromRange;
    public var zrotation       : FloatFromRange;
    public var rotation_offset : Float;
    public var radius          : FloatFromRange;

//particle properties
    public var start_size : PointFromRange;
    public var end_size   : PointFromRange;
    public var velocity   : FloatFromRange;
    public var damping    : FloatFromRange;
    public var life       : FloatFromRange;
	public var squareSizeStart : Bool;
	public var squareSizeEnd : Bool;

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

    public function new(_system : ParticleSystem, ?x : Xml = null, ?_template : Dynamic = null) {
        template = _template;
        particle_system = _system;

        particles = new Array<Particle>();
        emiterShape = new Rectangle(particle_system.pos.x, particle_system.pos.y, 0, 0);

        emit_timer = 0;

		//apply defaults
        apply(x, template);
    }

    private inline function getF(x : Xml, par : String, def : Float) : Float {
        return x.exists(par) ? Std.parseFloat(x.get(par)) : def;
    }

    private inline function getI(x : Xml, par : String, def : Int) : Int {
        return x.exists(par) ? Std.parseInt(x.get(par)) : def;
    }

    public function apply(?x : Xml = null, _template:Dynamic) {
        if(x != null){
            emit_time = getF(x, "emitTime", 0.1);
            duration = getF(x, "duration", 0.1);
            emit_count = getI(x, "emitCount", 1);

            direction = new FloatFromRange(x.elementsNamed("direction").next());
            velocity  = new FloatFromRange(x.elementsNamed("velocity").next());
            damping   = new FloatFromRange(x.elementsNamed("damping").next());
            life = new FloatFromRange(x.elementsNamed("life").next());
            end_rotation = new FloatFromRange(x.elementsNamed("endRotation").next());
            var xmlRotation : Xml = x.elementsNamed("rotation").next();
            zrotation = new FloatFromRange(xmlRotation);
            rotation_offset = getF(xmlRotation, "offset", 0.0);

            emiterShape = new Rectangle(getF(x.elementsNamed("emitterShape").next(), "x", 0.0),
                                        getF(x.elementsNamed("emitterShape").next(), "y", 0.0),
                                        getF(x.elementsNamed("emitterShape").next(), "width", 0.0),
                                        getF(x.elementsNamed("emitterShape").next(), "height", 0.0));

            gravity = new Point(getF(x.elementsNamed("gravity").next(), "x", 0.0),
            getF(x.elementsNamed("gravity").next(), "y", 0.0));

			var startSizeXML = x.elementsNamed("startSize").next();
			var endSizeXML = x.elementsNamed("endSize").next();
			
            start_size = new PointFromRange(startSizeXML);
            end_size = new PointFromRange(endSizeXML);
			squareSizeStart 
				= startSizeXML.exists("square") ? 
					(startSizeXML.get("square") == "true" ? true : false ) : false;
			squareSizeEnd	
				= endSizeXML.exists("square") ? 
					(endSizeXML.get("square") == "true" ? true : false ) : false;

            start_color = new ColorFromRange(x.elementsNamed("startColor").next());
            end_color = new ColorFromRange(x.elementsNamed("endColor").next());

        }else{
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
            end_size = new PointFromRange(new Point(128, 128));
			
			squareSizeStart = false;
			squareSizeEnd = false;

            (_template.start_color != null) ?
            start_color = _template.start_color :
            start_color = new ColorFromRange(new Color(1,1,1,1));

            (_template.end_color != null) ?
            end_color = _template.end_color :
            end_color = new ColorFromRange(new Color(0,0,0,0));
        }
    }

    public function destroy() {
        particles = null;
    }

    public function emit(){
        active = true;
        emit_timer = emit_time;
        finish_time = duration;

        if(emit_time != -1)
            finish_time = emit_time;
        else
            finish_time = -1;
    }

    public function stop() {
        emit_timer = 0;
        finish_time = -0.5;
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

        particle.position.x = particle_system.pos.x + emiterShape.x + Math.random() * emiterShape.width;
        particle.position.y = particle_system.pos.y + emiterShape.y + Math.random() * emiterShape.height;

        var new_dir = direction.value * ( Math.PI / 180 ); // convert to radians
        var new_velocity = velocity.value;

        particle.velocity.setTo(Math.cos( new_dir ) * new_velocity,
        Math.sin( new_dir ) * new_velocity);
        particle.damping = damping.value;
        particle.acceleration.setTo(0, 0);

		if (squareSizeStart) {
			particle.start_size.y = 
			particle.start_size.x = Math.floor(Math.max(0.0, start_size.x.value));
		} else {
			particle.start_size.x = Math.floor(Math.max(0.0, start_size.x.value));
			particle.start_size.y = Math.floor(Math.max(0.0, start_size.y.value));
		}

        particle.time_to_live = life.value;
		
		if (squareSizeEnd) {
			var deltaY : Float = end_size.x.value;
			particle.size_delta.x = ( deltaY - particle.start_size.x ) / particle.time_to_live;
			particle.size_delta.y = ( deltaY - particle.start_size.y ) / particle.time_to_live;
		}else{
			particle.size_delta.x = ( end_size.x.value - particle.start_size.x ) / particle.time_to_live;
			particle.size_delta.y = ( end_size.y.value - particle.start_size.y ) / particle.time_to_live;
		}
		

        particle.color     = new Color( start_color.value );
        var end_color : Color =  new Color( end_color.value );

        particle.color_delta.r = ( end_color.r - particle.color.r ) / particle.time_to_live;
        particle.color_delta.g = ( end_color.g - particle.color.g ) / particle.time_to_live;
        particle.color_delta.b = ( end_color.b - particle.color.b ) / particle.time_to_live;
        particle.color_delta.a = ( end_color.a - particle.color.a ) / particle.time_to_live;

        if(has_end_rotation)
            particle.rotation_delta  = ( end_rotation.value - particle.rotation ) / particle.time_to_live;
    } //init_particle

    public function update(dt : Float){
        if(!active) return;
        if( finish_time >= 0 || finish_time == -1) {
            emit_timer += dt;

            if( emit_timer >= emit_time ) {
                emit_timer = 0;
                for(i in 0 ... emit_count)
                    spawn();
            }

            if(finish_time != -1){
                finish_time -= dt;
                if(finish_time <= 0)
                    stop();
            }
        }

        //update all active particles
        if(beforeRender != null) beforeRender();
        active = false;
        for(current_particle in particles) {
            if(!current_particle.active) continue;

            active = true;
            //die over time
            current_particle.time_to_live -= dt;

            // If the current particle is alive
            if( current_particle.time_to_live > 0 ) {
                //updating velocity by acceleration
                current_particle.velocity.x
                    = current_particle.velocity.x + (current_particle.acceleration.x + gravity.x) * dt;
                current_particle.velocity.y
                    = current_particle.velocity.y + (current_particle.acceleration.y + gravity.y) * dt;

                //TODO: damping


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
            } else
                current_particle.active = false;
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