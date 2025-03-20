// Partial sum compute

// #import "SDF_PATH"::signed_distance_function

// const DIFF_EPSILON: f32 = 1e-5;
// const DIFF_DIRECTION_UU: vec3<f32> = vec3(1.0, 0.0, 0.0);
// const DIFF_DIRECTION_VV: vec3<f32> = vec3(0.0, 1.0, 0.0);

struct Settings {
    count: u32,
    seed: u32,
}

@group(0) @binding(0)
var initial: texture_storage_2d<rgba32uint, write>;
@group(0) @binding(1)
var current: texture_storage_2d<rgba32uint, read_write>;
@group(0) @binding(2)
var<uniform> settings: Settings;

fn hash(value: u32) -> u32 {
    var state = value;
    state = state ^ 2747636419u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    return state;
}

fn random_int(value: u32, max: u32) -> u32 {
    return hash(value) % max;
}

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let aa = random_int(invocation_id.y << 16u | invocation_id.x + settings.seed, 1000);
    let color = vec4<u32>(aa, 0, 0, 0);

    let color_ = vec4<u32>(999, 0, 0, 0);

    textureStore(initial, location, color);
    textureStore(current, location, color_);
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    // let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    // // moves toward 0-isosurface with performing a gradient descent if f(p)^2

    // var color: vec4<f32> = textureLoad(input, location);

    // let pos = vec3(color.xy, 0.0);

    // let dist_center = signed_distance_function(pos);
    // let dist_right = signed_distance_function(pos + DIFF_EPSILON * DIFF_DIRECTION_UU);
    // let dist_left = signed_distance_function(pos - DIFF_EPSILON * DIFF_DIRECTION_UU);
    // let dist_above = signed_distance_function(pos + DIFF_EPSILON * DIFF_DIRECTION_VV);
    // let dist_below = signed_distance_function(pos - DIFF_EPSILON * DIFF_DIRECTION_VV);

    // let gu = (dist_right - dist_left) / 2.0 / DIFF_EPSILON;
    // let gv = (dist_above - dist_below) / 2.0 / DIFF_EPSILON;
    // var gg: vec2<f32> = vec2(gu, gv);
    // // if length(gg) > 0.0 {
    // //     gg = normalize(gg);
    // // } else {
    // //     gg = vec2(0.0);
    // // }

    // color.x -= 2.0 * settings.learning_rate * dist_center * gg.x;
    // color.y -= 2.0 * settings.learning_rate * dist_center * gg.y;

    // // warped pattern

    // let pos_ = (pos.xy + 1.0) / 2.0;
    // let has_converged: bool = abs(dist_center) < 1e-2;
    // let color_ = vec4(pos_, f32(has_converged), 1.0);

    // textureStore(output, location, color);
    // textureStore(pattern, location, color_);
}
