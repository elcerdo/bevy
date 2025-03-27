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
    state = state ^ (state >> 16u);
    state = state * 2654435769u;
    state = state ^ (state >> 16u);
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

    textureStore(initial, location, color);
    textureStore(current, location, color);
}

@compute @workgroup_size(8, 8, 1)
fn reduce(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    // if settings.count != 3 {
    //     return;
    // }
    let count = settings.count;
    let factor = 1u << (count + 1);
    let shift = 1u << count;
    let location = vec2<i32>(i32(invocation_id.x * factor), i32(invocation_id.y));
    let location_ = vec2<i32>(i32(invocation_id.x * factor + shift), i32(invocation_id.y));

    var color: vec4<u32> = textureLoad(current, location);
    color += textureLoad(current, location_);
    var color_ = vec4<u32>(0);
    if count != 0 {
        color_ = vec4<u32>(999, 0, 0, 0);
    }

    workgroupBarrier();

    textureStore(current, location, color);
    textureStore(current, location_, color_);
}
