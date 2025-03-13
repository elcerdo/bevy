// Morpheus advection snippet

#import "shaders/morpheus/sdf/union.wgsl"::signed_distance_function
// #import "shaders/morpheus/sdf/sphere.wgsl"::signed_distance_function
// #import "shaders/morpheus/sdf/alien.wgsl"::signed_distance_function
// #import "shaders/morpheus/sdf/can.wgsl"::signed_distance_function

const DIFF_EPSILON: f32 = 1e-5;
const DIFF_DIRECTION_UU: vec3<f32> = vec3(1.0, 0.0, 0.0);
const DIFF_DIRECTION_VV: vec3<f32> = vec3(0.0, 1.0, 0.0);

struct Settings {
    texture_size: vec2<u32>,
    learning_rate: f32,
}

@group(0) @binding(0) var input: texture_storage_2d<rgba32float, read>;
@group(0) @binding(1) var output: texture_storage_2d<rgba32float, write>;
@group(0) @binding(2) var<uniform> settings: Settings;

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let hx: f32 = f32(settings.texture_size.x) / 2.0;
    let hy: f32 = f32(settings.texture_size.y) / 2.0;
    let pos = vec3((f32(invocation_id.x) - hx) / hx, (f32(invocation_id.y) - hy) / hy, 0.0);
    let is_inside: bool = signed_distance_function(pos) < 0.0;

    let color = vec4<f32>(pos.xy, f32(is_inside), 1.0);

    textureStore(output, location, color);
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));
    
    var color: vec4<f32> = textureLoad(input, location);

    let pos = vec3(color.xy, 0.0);

    let dist_center = signed_distance_function(pos);
    let dist_right = signed_distance_function(pos + DIFF_EPSILON * DIFF_DIRECTION_UU);
    let dist_left = signed_distance_function(pos - DIFF_EPSILON * DIFF_DIRECTION_UU);
    let dist_above = signed_distance_function(pos + DIFF_EPSILON * DIFF_DIRECTION_VV);
    let dist_below = signed_distance_function(pos - DIFF_EPSILON * DIFF_DIRECTION_VV);

    let gu = (dist_right - dist_left) / 2.0 / DIFF_EPSILON;
    let gv = (dist_above - dist_below) / 2.0 / DIFF_EPSILON;
    var gg: vec2<f32> = vec2(gu, gv);
    if length(gg) > 0.0 {
        gg = normalize(gg);
    } else {
        gg = vec2(0.0);
    }

    color.x -= settings.learning_rate * dist_center * gg.x;
    color.y -= settings.learning_rate * dist_center * gg.y;

    textureStore(output, location, color);
}
