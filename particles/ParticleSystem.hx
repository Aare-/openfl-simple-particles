package particles;

import de.polygonal.core.math.Vec2;
import flash.geom.Rectangle;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;

class ParticleSystem extends Sprite {

    public var active : Bool = false;
    public var emitters : Array<ParticleEmitter>;
    public var pos : Point;

    public function new( _pos:Point) {
        super();
        emitters = [];

        pos = _pos;
    }

    public function addEmitterFromXml(x : Xml){
        emitters.push(new ParticleEmitter(this, x));
    }

    public function loadFromXml(x : Xml){
        if(emitters == null)
            emitters = [];

        this.pos.x = Std.parseFloat(x.get("x"));
        this.pos.y = Std.parseFloat(x.get("y"));

        for(emitterDef in x.elementsNamed("particleEmitter"))
            emitters.push(new ParticleEmitter(this, emitterDef));
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
