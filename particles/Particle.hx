package particles;

import flash.geom.Point;

class Particle {
    public var active : Bool;

    public var particle_system : ParticleSystem;
    public var particle_emitter : ParticleEmitter;

    public var start_size : Point;
    public var position   : Point;

    public var velocity     : Point;
    public var acceleration : Point;
    public var damping      : Float;

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