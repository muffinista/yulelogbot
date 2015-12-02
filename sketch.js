// Learning Processing
// Daniel Shiffman
// http://www.learningprocessing.com

// Example 1-1: stroke and fill

FIRE = "1f525";

//BLACK_SQUARE = "2B1B";
//WHITE_SQUARE = "2B1C";

SMOKE="1f4ad";
SPARKLES="2728";
STAR="1f31f";
DIZZY="1f4ab";

var grid_w = 6;
var grid_h = 5;

var sprite_size = 72;
var sprite_scale = 1.0;
var urlBase = "https://raw.githubusercontent.com/twitter/twemoji/gh-pages/72x72/";
var images = {};

var emitters = [];

var offset;

var decorations = [];

BASE_CHANGE_CHANCE = 0.5;
var grow_bump = 0.1;
MAX_LEVEL = 5;
MIN_DECORATION_LEVEL = 1;
DECORATION_CHANCE = 0.1;

function codeToImage(c) {
    return loadImage(urlBase + c + ".png");
}


function setup() {
    for ( var i = 0; i < grid_w; i++ ) {
        emitters.push(1.0);
    }

    offset = sprite_size * sprite_scale;

    createCanvas(grid_w * offset, grid_h * offset);

    images.FIRE = codeToImage(FIRE);
    images.SMOKE = codeToImage(SMOKE);
    images.SPARKLES = codeToImage(SPARKLES);
    images.STAR = codeToImage(STAR);
    images.DIZZY = codeToImage(DIZZY);

    decorations = [
        images.SMOKE,
        images.SPARKLES,
        images.STAR,
        images.DIZZY
    ];

    frameRate(10);
}


function updateEmitters() {
    var new_emitters = _.map(emitters, function(e) {
        chance = BASE_CHANGE_CHANCE + ( (3-e).abs * 0.1);
    
        var acted = false;
        if ( e < MAX_LEVEL ) {
            chance = BASE_CHANGE_CHANCE + (e*0.1);
            do_grow = random() > chance - grow_bump;
            if (do_grow) {
                e = e + 1;
                return e;
            }
        }

        if ( ! acted && e > 1 ) {
            chance = BASE_CHANGE_CHANCE - (e*0.05);
            if ( e == MAX_LEVEL ) {
                chance = 0.2;
            }
            do_shrink = random() > chance;

            if ( do_shrink ) {
                e = e - 1;
            }
        }

        return e;
  });

    emitters = new_emitters;

}

function draw() {
    background(255);
    //rect(50,50,75,100);
    updateEmitters();
 
    //console.log(emitters);

    for ( var x = 0; x < grid_w; x++ ) {
        var value = emitters[x];
        for ( var y = 0; y < grid_h; y++ ) {
            if ( y <= value ) {
                var sprite;
                if ( value > MIN_DECORATION_LEVEL && 
                     random() <= DECORATION_CHANCE && 
                     (value == y || value == y - 1) ) {
                    sprite = _.sample(decorations);
                }
                else {
                    sprite = images.FIRE;
                }
                console.log(sprite);
                

                image(sprite,
                      x * offset, (grid_h - y) * offset,
                      sprite_size * sprite_scale, sprite_size * sprite_scale);
            }
        }

    }


}