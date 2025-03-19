//// PREAMBLE

fn signed_distance_function(pos: vec3<f32>) -> f32 {
    return compute_main_digraph(pos).v_dist;
}

//// BUILTINS

fn inverseSqrt(vv: f32) -> f32 { return 1.0 / sqrt(vv); }

fn opp(vv: f32) -> f32 { return -vv; }

fn vmin2(vv: vec2<f32>) -> f32 { return min(vv.x, vv.y); }
fn vmin3(vv: vec3<f32>) -> f32 { return min(min(vv.x, vv.y), vv.z); }
fn vmin4(vv: vec4<f32>) -> f32 { return min(min(vv.x, vv.y), min(vv.z, vv.w)); }

fn vmax2(vv: vec2<f32>) -> f32 { return max(vv.x, vv.y); }
fn vmax3(vv: vec3<f32>) -> f32 { return max(max(vv.x, vv.y), vv.z); }
fn vmax4(vv: vec4<f32>) -> f32 { return max(max(vv.x, vv.y), max(vv.z, vv.w)); }

// According to the Kronos documentation, the fract of the input is computing
// in this way 'x-floor(x)' which result to wrong results with negative values.
fn fractOfPositiveAndNegativeValue(vv: f32) -> f32 {
    if (vv < 0.0) {
        return vv - ceil(vv);
    } else {
        return vv - floor(vv);
    };
}
fn fractOfPositiveAndNegativeValue2(vv: vec2<f32>) -> vec2<f32> {
    return vec2(
        fractOfPositiveAndNegativeValue(vv.x),
        fractOfPositiveAndNegativeValue(vv.y));
}
fn fractOfPositiveAndNegativeValue3(vv: vec3<f32>) -> vec3<f32> {
    return vec3(
        fractOfPositiveAndNegativeValue(vv.x),
        fractOfPositiveAndNegativeValue(vv.y),
        fractOfPositiveAndNegativeValue(vv.z));
}
fn fractOfPositiveAndNegativeValue4(vv: vec4<f32>) -> vec4<f32> {
    return vec4(
        fractOfPositiveAndNegativeValue(vv.x),
        fractOfPositiveAndNegativeValue(vv.y),
        fractOfPositiveAndNegativeValue(vv.z),
        fractOfPositiveAndNegativeValue(vv.w));
}


// https://www.shadertoy.com/view/4dS3Wd
fn hash(q: f32) -> f32 {
    var p = fract(q * 0.011);
    p *= p + 7.5;
    p *= p + p;
    return fract(p);
}
fn hash2(q: vec2<f32>) -> f32 {
    var p3 = fract(q.xyx) * 0.13;
    p3 += dot(p3, p3.yzx + 3.333);
    return fract((p3.x + p3.y) * p3.z);
}
fn noise(x: f32) -> f32 {
    let i = floor(x);
    let f = fract(x);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), u);
}
fn noise2(x: vec2<f32>) -> f32 {
    let i = floor(x);
    let f = fract(x);
    let a = hash2(i);
    let b = hash2(i + vec2(1.0, 0.0));
    let c = hash2(i + vec2(0.0, 1.0));
    let d = hash2(i + vec2(1.0, 1.0));
    let u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
fn noise3(x: vec3<f32>) -> f32 {
    const step = vec3(110.0, 241.0, 171.0);
    let i = floor(x);
    let f = fract(x);
    let n = dot(i, step);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(n + dot(step, vec3(0.0, 0.0, 0.0))), hash(n + dot(step, vec3(1.0, 0.0, 0.0))), u.x),
                   mix(hash(n + dot(step, vec3(0.0, 1.0, 0.0))), hash(n + dot(step, vec3(1.0, 1.0, 0.0))), u.x), u.y),
               mix(mix(hash(n + dot(step, vec3(0.0, 0.0, 1.0))), hash(n + dot(step, vec3(1.0, 0.0, 1.0))), u.x),
                   mix(hash(n + dot(step, vec3(0.0, 1.0, 1.0))), hash(n + dot(step, vec3(1.0, 1.0, 1.0))), u.x), u.y), u.z);
}

fn fbm(x_: f32, octaves: f32) -> f32 {
    const shift = 100.0;
    let num_octaves = i32(octaves);
    var v = 0.0;
    var a = 0.5;
    var x = x_;
    for (var i: i32 = 0; i < num_octaves; i++) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}
fn fbm2(x_: vec2<f32>, octaves: f32) -> f32 {
    const shift = vec2(100.0);
    const rot = mat2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    let num_octaves = i32(octaves);
    var v = 0.0;
    var a = 0.5;
    var x = x_;
    for (var i: i32 = 0; i < num_octaves; i++) {
        v += a * noise2(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}
fn fbm3(x_: vec3<f32>, octaves: f32) -> f32 {
    const shift = vec3(100.0);
    let num_octaves = i32(octaves);
    var v = 0.0;
    var a = 0.5;
    var x = x_;
    for (var i: i32 = 0; i < num_octaves; i++) {
        v += a * noise3(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// https://www.pcg-random.org/
fn noisePcg(q: f32) -> f32 {
    let v = u32(round(q));
    let state = v * 747796405u + 2891336453u;
    let word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return f32(f32((word >> 22u) ^ word) * (1.0/f32(0xffffffffu))) ;
}
// http://www.jcgt.org/published/0009/03/02/
// https://www.shadertoy.com/view/XlGcRh  
fn noisePcg2(q: vec2<f32>) -> vec2<f32> {
    var v = vec2u(q);
    v = v * 1664525u + 1013904223u;
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v.x = v.x ^ (v.x >> 16u);
    v.y = v.y ^ (v.y >> 16u);
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v.x = v.x ^ (v.x >> 16u);
    v.y = v.y ^ (v.y >> 16u);
    return vec2f(v) / f32(0xffffffffu);
}
// http://www.jcgt.org/published/0009/03/02/
// https://www.shadertoy.com/view/XlGcRh
fn noisePcg3(q: vec3<f32>) -> vec3<f32> {
    var v = vec3u(q);
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.x = v.x ^ (v.x >> 16u);
    v.y = v.y ^ (v.y >> 16u);
    v.z = v.z ^ (v.z >> 16u);
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return vec3f(v) / f32(0xffffffffu);
}
// http://www.jcgt.org/published/0009/03/02/
// https://www.shadertoy.com/view/XlGcRh
fn noisePcg4(q: vec4<f32>) -> vec4<f32> {
    var v = vec4u(q);
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    v.x = v.x ^ (v.x >> 16u);
    v.y = v.y ^ (v.y >> 16u);
    v.z = v.z ^ (v.z >> 16u);
    v.w = v.w ^ (v.w >> 16u);
    v.x += v.y * v.w;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v.w += v.y * v.z;
    return vec4f(v) / f32(0xffffffffu);
}


//// CUSTOM TYPES

struct t_params {
	v_radius: f32,
	v_bottom: f32,
	v_top: f32,
	v_scale: f32,
	v_depth: f32,
}

struct t_sea_params {
	v_time: f32,
	v_speed: f32,
	v_amplitude: f32,
	v_frequency: f32,
	v_choppy: f32,
}

struct t_sea_scaling {
	v_scale: f32,
}

struct t_animation {
	v_time: f32,
	v_start: f32,
	v_end: f32,
}

struct t_noise2to1_consts {
	v_zero: f32,
	v_one: f32,
	v_two: f32,
	v_minus_one: f32,
}

struct t_octave_params {
	v_one: f32,
	v_power: f32,
}

struct t_hash2to1_constants {
	v_p1: f32,
	v_p2: f32,
	v_p3: f32,
}

struct t_sea_surface_params {
	v_zero: f32,
	v_one: f32,
	v_uv_multiplier: f32,
	v_octave_mul1: vec2<f32>,
	v_octave_mul2: vec2<f32>,
	v_freq_multiplier: f32,
	v_amplitude_multiplier: f32,
	v_choppy_mix: f32,
}

struct t_position {
	v_pos: vec3<f32>,
}
struct t_outlet {
	v_dist: f32,
}

//// INSTANCES

const u_params: t_params = t_params(f32(1), f32(-0.195), f32(0.185), f32(15.4), f32(0.55));
const u_sea_params: t_sea_params = t_sea_params(f32(0), f32(0.1), f32(0.085), f32(2), f32(5.05));
const u_sea_scaling: t_sea_scaling = t_sea_scaling(f32(2.35));
const u_animation: t_animation = t_animation(f32(2.8945785), f32(0), f32(10));

const c_noise2to1_consts: t_noise2to1_consts = t_noise2to1_consts(f32(0), f32(1), f32(2), f32(-1));
const c_octave_params: t_octave_params = t_octave_params(f32(1), f32(0.65));
const c_hash2to1_constants: t_hash2to1_constants = t_hash2to1_constants(f32(127.1), f32(311.7), f32(43758.547));
const c_sea_surface_params: t_sea_surface_params = t_sea_surface_params(f32(0), f32(1), f32(0.75), vec2(1.6, 1.2), vec2(-1.2, 1.6), f32(1.9), f32(0.22), f32(0.2));

//// IMPLEMENTATIONS

// FID[0429] ComposeFuncType::Terminal main:(v3 pos)->(sc dist)
// FID[0421] ComposeFuncType::Inlet position:()->(v3 pos)
// FID[0430] ComposeFuncType::Outlet outlet:(sc dist)->()
fn compute_main_digraph(a_pos: vec3<f32>) -> t_outlet {
	let tmp072: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_zero);
	let tmp139: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_zero);
	let tmp138: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_one);
	let tmp071: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_one);
	let tmp084: vec2<f32> = floor(((vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(u_sea_params.v_frequency, u_sea_params.v_frequency)));
	let tmp151: vec2<f32> = floor(((vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(u_sea_params.v_frequency, u_sea_params.v_frequency)));
	let tmp301: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier), (u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier))));
	let tmp147: vec2<f32> = (tmp151 + vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero));
	let tmp141: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp121: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp080: vec2<f32> = (tmp084 + vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero));
	let tmp047: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp054: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp060: vec2<f32> = (tmp084 + vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one));
	let tmp061: vec2<f32> = (tmp084 + tmp071);
	let tmp234: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier), (u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier))));
	let tmp064: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp127: vec2<f32> = (tmp151 + vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one));
	let tmp128: vec2<f32> = (tmp151 + tmp138);
	let tmp070: vec2<f32> = (tmp084 + tmp072);
	let tmp131: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp222: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_zero);
	let tmp074: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp137: vec2<f32> = (tmp151 + tmp139);
	let tmp114: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp221: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_one);
	let tmp288: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_one);
	let tmp289: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_zero);
	let tmp440: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_one);
	let tmp224: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp214: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp220: vec2<f32> = (tmp234 + tmp222);
	let tmp297: vec2<f32> = (tmp301 + vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero));
	let tmp287: vec2<f32> = (tmp301 + tmp289);
	let tmp281: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp278: vec2<f32> = (tmp301 + tmp288);
	let tmp277: vec2<f32> = (tmp301 + vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one));
	let tmp271: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp264: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp075: f32 = dot(tmp080, tmp074);
	let tmp204: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp065: f32 = dot(tmp070, tmp064);
	let tmp055: f32 = dot(tmp061, tmp054);
	let tmp453: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul2)) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier), ((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier))));
	let tmp048: f32 = dot(tmp060, tmp047);
	let tmp230: vec2<f32> = (tmp234 + vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero));
	let tmp441: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_zero);
	let tmp115: f32 = dot(tmp127, tmp114);
	let tmp291: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp132: f32 = dot(tmp137, tmp131);
	let tmp374: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_zero);
	let tmp142: f32 = dot(tmp147, tmp141);
	let tmp197: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp373: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_one);
	let tmp122: f32 = dot(tmp128, tmp121);
	let tmp210: vec2<f32> = (tmp234 + vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one));
	let tmp211: vec2<f32> = (tmp234 + tmp221);
	let tmp386: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul2)) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier), ((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier))));
	let tmp053: t_hash2to1_constants = c_hash2to1_constants;
	let tmp076: f32 = sin(tmp075);
	let tmp046: t_hash2to1_constants = c_hash2to1_constants;
	let tmp439: vec2<f32> = (tmp453 + tmp441);
	let tmp140: t_hash2to1_constants = c_hash2to1_constants;
	let tmp205: f32 = dot(tmp211, tmp204);
	let tmp130: t_hash2to1_constants = c_hash2to1_constants;
	let tmp416: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp113: t_hash2to1_constants = c_hash2to1_constants;
	let tmp449: vec2<f32> = (tmp453 + vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero));
	let tmp105: vec2<f32> = floor(((vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(u_sea_params.v_frequency, u_sea_params.v_frequency)));
	let tmp349: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp372: vec2<f32> = (tmp386 + tmp374);
	let tmp423: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp198: f32 = dot(tmp210, tmp197);
	let tmp133: f32 = sin(tmp132);
	let tmp116: f32 = sin(tmp115);
	let tmp073: t_hash2to1_constants = c_hash2to1_constants;
	let tmp063: t_hash2to1_constants = c_hash2to1_constants;
	let tmp430: vec2<f32> = (tmp453 + tmp440);
	let tmp123: f32 = sin(tmp122);
	let tmp215: f32 = dot(tmp220, tmp214);
	let tmp292: f32 = dot(tmp297, tmp291);
	let tmp443: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp225: f32 = dot(tmp230, tmp224);
	let tmp282: f32 = dot(tmp287, tmp281);
	let tmp120: t_hash2to1_constants = c_hash2to1_constants;
	let tmp362: vec2<f32> = (tmp386 + vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one));
	let tmp143: f32 = sin(tmp142);
	let tmp272: f32 = dot(tmp278, tmp271);
	let tmp433: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp265: f32 = dot(tmp277, tmp264);
	let tmp382: vec2<f32> = (tmp386 + vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero));
	let tmp376: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp363: vec2<f32> = (tmp386 + tmp373);
	let tmp066: f32 = sin(tmp065);
	let tmp366: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp429: vec2<f32> = (tmp453 + vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one));
	let tmp356: vec2<f32> = vec2<f32>(c_hash2to1_constants.v_p1, c_hash2to1_constants.v_p2);
	let tmp056: f32 = sin(tmp055);
	let tmp049: f32 = sin(tmp048);
	let tmp038: vec2<f32> = floor(((vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(u_sea_params.v_frequency, u_sea_params.v_frequency)));
	let tmp149: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero);
	let tmp148: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one);
	let tmp206: f32 = sin(tmp205);
	let tmp082: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero);
	let tmp136: f32 = floor((tmp133 * tmp130.v_p3));
	let tmp255: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier), (u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier))));
	let tmp216: f32 = sin(tmp215);
	let tmp203: t_hash2to1_constants = c_hash2to1_constants;
	let tmp213: t_hash2to1_constants = c_hash2to1_constants;
	let tmp293: f32 = sin(tmp292);
	let tmp144: f32 = (tmp143 * tmp140.v_p3);
	let tmp079: f32 = floor((tmp076 * tmp073.v_p3));
	let tmp134: f32 = (tmp133 * tmp130.v_p3);
	let tmp377: f32 = dot(tmp382, tmp376);
	let tmp223: t_hash2to1_constants = c_hash2to1_constants;
	let tmp283: f32 = sin(tmp282);
	let tmp417: f32 = dot(tmp429, tmp416);
	let tmp067: f32 = (tmp066 * tmp063.v_p3);
	let tmp106: vec2<f32> = (((vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(u_sea_params.v_frequency, u_sea_params.v_frequency)) - tmp105);
	let tmp199: f32 = sin(tmp198);
	let tmp273: f32 = sin(tmp272);
	let tmp424: f32 = dot(tmp430, tmp423);
	let tmp124: f32 = (tmp123 * tmp120.v_p3);
	let tmp266: f32 = sin(tmp265);
	let tmp119: f32 = floor((tmp116 * tmp113.v_p3));
	let tmp117: f32 = (tmp116 * tmp113.v_p3);
	let tmp188: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier), (u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier))));
	let tmp126: f32 = floor(tmp124);
	let tmp357: f32 = dot(tmp363, tmp356);
	let tmp196: t_hash2to1_constants = c_hash2to1_constants;
	let tmp263: t_hash2to1_constants = c_hash2to1_constants;
	let tmp069: f32 = floor(tmp067);
	let tmp280: t_hash2to1_constants = c_hash2to1_constants;
	let tmp290: t_hash2to1_constants = c_hash2to1_constants;
	let tmp226: f32 = sin(tmp225);
	let tmp057: f32 = (tmp056 * tmp053.v_p3);
	let tmp081: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one);
	let tmp059: f32 = floor(tmp057);
	let tmp434: f32 = dot(tmp439, tmp433);
	let tmp367: f32 = dot(tmp372, tmp366);
	let tmp350: f32 = dot(tmp362, tmp349);
	let tmp052: f32 = floor((tmp049 * tmp046.v_p3));
	let tmp444: f32 = dot(tmp449, tmp443);
	let tmp146: f32 = floor(tmp144);
	let tmp050: f32 = (tmp049 * tmp046.v_p3);
	let tmp039: vec2<f32> = (((vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(u_sea_params.v_frequency, u_sea_params.v_frequency)) - tmp038);
	let tmp077: f32 = (tmp076 * tmp073.v_p3);
	let tmp270: t_hash2to1_constants = c_hash2to1_constants;
	let tmp298: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one);
	let tmp125: f32 = (tmp124 - tmp126);
	let tmp296: f32 = floor((tmp293 * tmp290.v_p3));
	let tmp415: t_hash2to1_constants = c_hash2to1_constants;
	let tmp432: t_hash2to1_constants = c_hash2to1_constants;
	let tmp365: t_hash2to1_constants = c_hash2to1_constants;
	let tmp355: t_hash2to1_constants = c_hash2to1_constants;
	let tmp442: t_hash2to1_constants = c_hash2to1_constants;
	let tmp348: t_hash2to1_constants = c_hash2to1_constants;
	let tmp286: f32 = floor((tmp283 * tmp280.v_p3));
	let tmp422: t_hash2to1_constants = c_hash2to1_constants;
	let tmp375: t_hash2to1_constants = c_hash2to1_constants;
	let tmp135: f32 = (tmp134 - tmp136);
	let tmp145: f32 = (tmp144 - tmp146);
	let tmp274: f32 = (tmp273 * tmp270.v_p3);
	let tmp276: f32 = floor(tmp274);
	let tmp207: f32 = (tmp206 * tmp203.v_p3);
	let tmp231: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one);
	let tmp200: f32 = (tmp199 * tmp196.v_p3);
	let tmp269: f32 = floor((tmp266 * tmp263.v_p3));
	let tmp435: f32 = sin(tmp434);
	let tmp227: f32 = (tmp226 * tmp223.v_p3);
	let tmp284: f32 = (tmp283 * tmp280.v_p3);
	let tmp150: vec2<f32> = smoothstep(tmp149, tmp148, tmp106);
	let tmp256: vec2<f32> = (((vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier), (u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier))) - tmp255);
	let tmp267: f32 = (tmp266 * tmp263.v_p3);
	let tmp294: f32 = (tmp293 * tmp290.v_p3);
	let tmp445: f32 = sin(tmp444);
	let tmp299: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero);
	let tmp217: f32 = (tmp216 * tmp213.v_p3);
	let tmp068: f32 = (tmp067 - tmp069);
	let tmp232: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero);
	let tmp368: f32 = sin(tmp367);
	let tmp358: f32 = sin(tmp357);
	let tmp351: f32 = sin(tmp350);
	let tmp229: f32 = floor(tmp227);
	let tmp340: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul2)) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier), ((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier))));
	let tmp058: f32 = (tmp057 - tmp059);
	let tmp189: vec2<f32> = (((vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier), (u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier))) - tmp188);
	let tmp202: f32 = floor(tmp200);
	let tmp407: vec2<f32> = floor(((vec2<f32>(dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul2)) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier), ((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier))));
	let tmp209: f32 = floor(tmp207);
	let tmp051: f32 = (tmp050 - tmp052);
	let tmp078: f32 = (tmp077 - tmp079);
	let tmp083: vec2<f32> = smoothstep(tmp082, tmp081, tmp039);
	let tmp418: f32 = sin(tmp417);
	let tmp425: f32 = sin(tmp424);
	let tmp118: f32 = (tmp117 - tmp119);
	let tmp219: f32 = floor(tmp217);
	let tmp378: f32 = sin(tmp377);
	let tmp359: f32 = (tmp358 * tmp355.v_p3);
	let tmp371: f32 = floor((tmp368 * tmp365.v_p3));
	let tmp361: f32 = floor(tmp359);
	let tmp218: f32 = (tmp217 - tmp219);
	let tmp448: f32 = floor((tmp445 * tmp442.v_p3));
	let tmp285: f32 = (tmp284 - tmp286);
	let tmp300: vec2<f32> = smoothstep(tmp299, tmp298, tmp256);
	let tmp129: f32 = mix(tmp145, tmp135, tmp150.x);
	let tmp354: f32 = floor((tmp351 * tmp348.v_p3));
	let tmp045: f32 = mix(tmp058, tmp051, tmp083.x);
	let tmp426: f32 = (tmp425 * tmp422.v_p3);
	let tmp446: f32 = (tmp445 * tmp442.v_p3);
	let tmp041: vec2<f32> = tmp083;
	let tmp275: f32 = (tmp274 - tmp276);
	let tmp108: vec2<f32> = tmp150;
	let tmp352: f32 = (tmp351 * tmp348.v_p3);
	let tmp295: f32 = (tmp294 - tmp296);
	let tmp428: f32 = floor(tmp426);
	let tmp268: f32 = (tmp267 - tmp269);
	let tmp341: vec2<f32> = (((vec2<f32>(dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul2)) - vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier), ((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier))) - tmp340);
	let tmp419: f32 = (tmp418 * tmp415.v_p3);
	let tmp369: f32 = (tmp368 * tmp365.v_p3);
	let tmp201: f32 = (tmp200 - tmp202);
	let tmp233: vec2<f32> = smoothstep(tmp232, tmp231, tmp189);
	let tmp451: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero);
	let tmp381: f32 = floor((tmp378 * tmp375.v_p3));
	let tmp112: f32 = mix(tmp125, tmp118, tmp108.x);
	let tmp228: f32 = (tmp227 - tmp229);
	let tmp421: f32 = floor(tmp419);
	let tmp436: f32 = (tmp435 * tmp432.v_p3);
	let tmp450: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one);
	let tmp408: vec2<f32> = (((vec2<f32>(dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1), dot(vec2<f32>(((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier), (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2)), c_sea_surface_params.v_octave_mul2)) + vec2<f32>(((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((u_animation.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one))) * vec2<f32>(((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier), ((u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier) * c_sea_surface_params.v_freq_multiplier))) - tmp407);
	let tmp438: f32 = floor(tmp436);
	let tmp208: f32 = (tmp207 - tmp209);
	let tmp062: f32 = mix(tmp078, tmp068, tmp041.x);
	let tmp384: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_zero, c_noise2to1_consts.v_zero);
	let tmp383: vec2<f32> = vec2<f32>(c_noise2to1_consts.v_one, c_noise2to1_consts.v_one);
	let tmp379: f32 = (tmp378 * tmp375.v_p3);
	let tmp191: vec2<f32> = tmp233;
	let tmp360: f32 = (tmp359 - tmp361);
	let tmp258: vec2<f32> = tmp300;
	let tmp279: f32 = mix(tmp295, tmp285, tmp258.x);
	let tmp353: f32 = (tmp352 - tmp354);
	let tmp452: vec2<f32> = smoothstep(tmp451, tmp450, tmp408);
	let tmp195: f32 = mix(tmp208, tmp201, tmp191.x);
	let tmp608: t_animation = u_animation;
	let tmp111: f32 = mix(tmp129, tmp112, tmp108.y);
	let tmp447: f32 = (tmp446 - tmp448);
	let tmp437: f32 = (tmp436 - tmp438);
	let tmp044: f32 = mix(tmp062, tmp045, tmp041.y);
	let tmp420: f32 = (tmp419 - tmp421);
	let tmp212: f32 = mix(tmp228, tmp218, tmp191.x);
	let tmp026: f32 = ((vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).x * c_sea_surface_params.v_uv_multiplier);
	let tmp385: vec2<f32> = smoothstep(tmp384, tmp383, tmp341);
	let tmp370: f32 = (tmp369 - tmp371);
	let tmp427: f32 = (tmp426 - tmp428);
	let tmp380: f32 = (tmp379 - tmp381);
	let tmp262: f32 = mix(tmp275, tmp268, tmp258.x);
	let tmp177: vec2<f32> = vec2<f32>(((tmp608.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one), ((tmp608.v_time * u_sea_params.v_speed) + c_sea_surface_params.v_one));
	let tmp364: f32 = mix(tmp380, tmp370, tmp385.x);
	let tmp347: f32 = mix(tmp360, tmp353, tmp385.x);
	let tmp328: f32 = (tmp608.v_time * u_sea_params.v_speed);
	let tmp261: f32 = mix(tmp279, tmp262, tmp258.y);
	let tmp040: t_noise2to1_consts = c_noise2to1_consts;
	let tmp043: f32 = (tmp044 * tmp040.v_two);
	let tmp194: f32 = mix(tmp212, tmp195, tmp191.y);
	let tmp431: f32 = mix(tmp447, tmp437, tmp452.x);
	let tmp033: f32 = dot(vec2<f32>(tmp026, (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul1);
	let tmp032: f32 = dot(vec2<f32>(tmp026, (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y), c_sea_surface_params.v_octave_mul2);
	let tmp110: f32 = (tmp111 * c_noise2to1_consts.v_two);
	let tmp414: f32 = mix(tmp427, tmp420, tmp452.x);
	let tmp107: t_noise2to1_consts = c_noise2to1_consts;
	let tmp025: vec2<f32> = vec2<f32>(tmp026, (vec3<f32>(t_position(a_pos).v_pos.x, t_position(a_pos).v_pos.z, t_position(a_pos).v_pos.y) * vec3<f32>(u_sea_scaling.v_scale, u_sea_scaling.v_scale, u_sea_scaling.v_scale)).y);
	let tmp410: vec2<f32> = tmp452;
	let tmp343: vec2<f32> = tmp385;
	let tmp329: f32 = (tmp328 + c_sea_surface_params.v_one);
	let tmp327: vec2<f32> = vec2<f32>(tmp329, tmp329);
	let tmp413: f32 = mix(tmp431, tmp414, tmp410.y);
	let tmp031: vec2<f32> = vec2<f32>(tmp033, tmp032);
	let tmp183: f32 = dot(tmp031, c_sea_surface_params.v_octave_mul1);
	let tmp042: f32 = (tmp043 + tmp040.v_minus_one);
	let tmp182: f32 = dot(tmp031, c_sea_surface_params.v_octave_mul2);
	let tmp030: f32 = (u_sea_params.v_frequency * c_sea_surface_params.v_freq_multiplier);
	let tmp190: t_noise2to1_consts = c_noise2to1_consts;
	let tmp346: f32 = mix(tmp364, tmp347, tmp343.y);
	let tmp257: t_noise2to1_consts = c_noise2to1_consts;
	let tmp176: vec2<f32> = (tmp025 + tmp177);
	let tmp193: f32 = (tmp194 * tmp190.v_two);
	let tmp175: vec2<f32> = (tmp025 - tmp177);
	let tmp173: vec2<f32> = vec2<f32>(u_sea_params.v_frequency, u_sea_params.v_frequency);
	let tmp109: f32 = (tmp110 + tmp107.v_minus_one);
	let tmp260: f32 = (tmp261 * tmp257.v_two);
	let tmp180: f32 = (tmp030 * c_sea_surface_params.v_freq_multiplier);
	let tmp409: t_noise2to1_consts = c_noise2to1_consts;
	let tmp342: t_noise2to1_consts = c_noise2to1_consts;
	let tmp325: vec2<f32> = (tmp031 - tmp327);
	let tmp326: vec2<f32> = (tmp031 + tmp327);
	let tmp172: vec2<f32> = (tmp175 * tmp173);
	let tmp412: f32 = (tmp413 * tmp409.v_two);
	let tmp174: vec2<f32> = (tmp176 * tmp173);
	let tmp323: vec2<f32> = vec2<f32>(tmp030, tmp030);
	let tmp181: vec2<f32> = vec2<f32>(tmp183, tmp182);
	let tmp259: f32 = (tmp260 + tmp257.v_minus_one);
	let tmp192: f32 = (tmp193 + tmp190.v_minus_one);
	let tmp345: f32 = (tmp346 * tmp342.v_two);
	let tmp153: vec2<f32> = vec2<f32>(tmp109, tmp109);
	let tmp086: vec2<f32> = vec2<f32>(tmp042, tmp042);
	let tmp479: vec2<f32> = vec2<f32>(tmp329, tmp329);
	let tmp324: vec2<f32> = (tmp326 * tmp323);
	let tmp322: vec2<f32> = (tmp325 * tmp323);
	let tmp236: vec2<f32> = vec2<f32>(tmp192, tmp192);
	let tmp344: f32 = (tmp345 + tmp342.v_minus_one);
	let tmp152: vec2<f32> = (tmp153 + tmp174);
	let tmp085: vec2<f32> = (tmp086 + tmp172);
	let tmp411: f32 = (tmp412 + tmp409.v_minus_one);
	let tmp475: vec2<f32> = vec2<f32>(tmp180, tmp180);
	let tmp477: vec2<f32> = (tmp181 - tmp479);
	let tmp478: vec2<f32> = (tmp181 + tmp479);
	let tmp303: vec2<f32> = vec2<f32>(tmp259, tmp259);
	let tmp476: vec2<f32> = (tmp478 * tmp475);
	let tmp474: vec2<f32> = (tmp477 * tmp475);
	let tmp089: f32 = sin(tmp085.y);
	let tmp088: f32 = sin(tmp085.x);
	let tmp156: f32 = sin(tmp152.y);
	let tmp155: f32 = sin(tmp152.x);
	let tmp455: vec2<f32> = vec2<f32>(tmp411, tmp411);
	let tmp087: vec2<f32> = tmp085;
	let tmp154: vec2<f32> = tmp152;
	let tmp235: vec2<f32> = (tmp236 + tmp322);
	let tmp302: vec2<f32> = (tmp303 + tmp324);
	let tmp388: vec2<f32> = vec2<f32>(tmp344, tmp344);
	let tmp304: vec2<f32> = tmp302;
	let tmp157: vec2<f32> = vec2<f32>(tmp155, tmp156);
	let tmp090: vec2<f32> = vec2<f32>(tmp088, tmp089);
	let tmp454: vec2<f32> = (tmp455 + tmp476);
	let tmp096: f32 = cos(tmp087.y);
	let tmp095: f32 = cos(tmp087.x);
	let tmp239: f32 = sin(tmp235.y);
	let tmp238: f32 = sin(tmp235.x);
	let tmp237: vec2<f32> = tmp235;
	let tmp163: f32 = cos(tmp154.y);
	let tmp162: f32 = cos(tmp154.x);
	let tmp305: f32 = sin(tmp304.x);
	let tmp306: f32 = sin(tmp304.y);
	let tmp387: vec2<f32> = (tmp388 + tmp474);
	let tmp458: f32 = sin(tmp454.y);
	let tmp245: f32 = cos(tmp237.x);
	let tmp457: f32 = sin(tmp454.x);
	let tmp091: vec2<f32> = abs(tmp090);
	let tmp164: vec2<f32> = vec2<f32>(tmp162, tmp163);
	let tmp246: f32 = cos(tmp237.y);
	let tmp160: vec2<f32> = vec2<f32>(c_octave_params.v_one, c_octave_params.v_one);
	let tmp158: vec2<f32> = abs(tmp157);
	let tmp389: vec2<f32> = tmp387;
	let tmp093: vec2<f32> = vec2<f32>(c_octave_params.v_one, c_octave_params.v_one);
	let tmp097: vec2<f32> = vec2<f32>(tmp095, tmp096);
	let tmp307: vec2<f32> = vec2<f32>(tmp305, tmp306);
	let tmp391: f32 = sin(tmp389.y);
	let tmp390: f32 = sin(tmp389.x);
	let tmp456: vec2<f32> = tmp454;
	let tmp312: f32 = cos(tmp304.x);
	let tmp240: vec2<f32> = vec2<f32>(tmp238, tmp239);
	let tmp313: f32 = cos(tmp304.y);
	let tmp247: vec2<f32> = vec2<f32>(tmp245, tmp246);
	let tmp397: f32 = cos(tmp389.x);
	let tmp464: f32 = cos(tmp456.x);
	let tmp314: vec2<f32> = vec2<f32>(tmp312, tmp313);
	let tmp459: vec2<f32> = vec2<f32>(tmp457, tmp458);
	let tmp161: vec2<f32> = (tmp160 - tmp158);
	let tmp094: vec2<f32> = (tmp093 - tmp091);
	let tmp243: vec2<f32> = vec2<f32>(c_octave_params.v_one, c_octave_params.v_one);
	let tmp165: vec2<f32> = abs(tmp164);
	let tmp098: vec2<f32> = abs(tmp097);
	let tmp241: vec2<f32> = abs(tmp240);
	let tmp398: f32 = cos(tmp389.y);
	let tmp392: vec2<f32> = vec2<f32>(tmp390, tmp391);
	let tmp310: vec2<f32> = vec2<f32>(c_octave_params.v_one, c_octave_params.v_one);
	let tmp308: vec2<f32> = abs(tmp307);
	let tmp465: f32 = cos(tmp456.y);
	let tmp244: vec2<f32> = (tmp243 - tmp241);
	let tmp166: vec2<f32> = mix(tmp161, tmp165, tmp161);
	let tmp248: vec2<f32> = abs(tmp247);
	let tmp099: vec2<f32> = mix(tmp094, tmp098, tmp094);
	let tmp399: vec2<f32> = vec2<f32>(tmp397, tmp398);
	let tmp460: vec2<f32> = abs(tmp459);
	let tmp395: vec2<f32> = vec2<f32>(c_octave_params.v_one, c_octave_params.v_one);
	let tmp393: vec2<f32> = abs(tmp392);
	let tmp466: vec2<f32> = vec2<f32>(tmp464, tmp465);
	let tmp311: vec2<f32> = (tmp310 - tmp308);
	let tmp315: vec2<f32> = abs(tmp314);
	let tmp462: vec2<f32> = vec2<f32>(c_octave_params.v_one, c_octave_params.v_one);
	let tmp400: vec2<f32> = abs(tmp399);
	let tmp249: vec2<f32> = mix(tmp244, tmp248, tmp244);
	let tmp396: vec2<f32> = (tmp395 - tmp393);
	let tmp463: vec2<f32> = (tmp462 - tmp460);
	let tmp167: vec2<f32> = tmp166;
	let tmp100: vec2<f32> = tmp099;
	let tmp467: vec2<f32> = abs(tmp466);
	let tmp316: vec2<f32> = mix(tmp311, tmp315, tmp311);
	let tmp101: f32 = (tmp100.x * tmp100.y);
	let tmp401: vec2<f32> = mix(tmp396, tmp400, tmp396);
	let tmp168: f32 = (tmp167.x * tmp167.y);
	let tmp317: vec2<f32> = tmp316;
	let tmp250: vec2<f32> = tmp249;
	let tmp468: vec2<f32> = mix(tmp463, tmp467, tmp463);
	let tmp318: f32 = (tmp317.x * tmp317.y);
	let tmp402: vec2<f32> = tmp401;
	let tmp251: f32 = (tmp250.x * tmp250.y);
	let tmp469: vec2<f32> = tmp468;
	let tmp159: t_octave_params = c_octave_params;
	let tmp092: t_octave_params = c_octave_params;
	let tmp102: f32 = pow(tmp101, tmp092.v_power);
	let tmp169: f32 = pow(tmp168, tmp159.v_power);
	let tmp252: f32 = pow(tmp251, c_octave_params.v_power);
	let tmp470: f32 = (tmp469.x * tmp469.y);
	let tmp403: f32 = (tmp402.x * tmp402.y);
	let tmp319: f32 = pow(tmp318, c_octave_params.v_power);
	let tmp170: f32 = (tmp159.v_one - tmp169);
	let tmp242: t_octave_params = c_octave_params;
	let tmp309: t_octave_params = c_octave_params;
	let tmp103: f32 = (tmp092.v_one - tmp102);
	let tmp171: f32 = pow(tmp170, u_sea_params.v_choppy);
	let tmp404: f32 = pow(tmp403, c_octave_params.v_power);
	let tmp471: f32 = pow(tmp470, c_octave_params.v_power);
	let tmp028: f32 = mix(u_sea_params.v_choppy, c_sea_surface_params.v_one, c_sea_surface_params.v_choppy_mix);
	let tmp394: t_octave_params = c_octave_params;
	let tmp253: f32 = (tmp242.v_one - tmp252);
	let tmp320: f32 = (tmp309.v_one - tmp319);
	let tmp104: f32 = pow(tmp103, u_sea_params.v_choppy);
	let tmp461: t_octave_params = c_octave_params;
	let tmp178: f32 = mix(tmp028, c_sea_surface_params.v_one, c_sea_surface_params.v_choppy_mix);
	let tmp472: f32 = (tmp461.v_one - tmp471);
	let tmp405: f32 = (tmp394.v_one - tmp404);
	let tmp001: t_position = t_position(a_pos);
	let tmp321: f32 = pow(tmp320, tmp028);
	let tmp022: t_sea_params = u_sea_params;
	let tmp254: f32 = pow(tmp253, tmp028);
	let tmp037: f32 = (tmp171 + tmp104);
	let tmp034: t_sea_surface_params = c_sea_surface_params;
	let tmp029: f32 = (tmp022.v_amplitude * tmp034.v_amplitude_multiplier);
	let tmp187: f32 = (tmp321 + tmp254);
	let tmp036: f32 = (tmp037 * tmp022.v_amplitude);
	let tmp473: f32 = pow(tmp472, tmp178);
	let tmp607: vec3<f32> = tmp001.v_pos;
	let tmp481: t_sea_scaling = u_sea_scaling;
	let tmp406: f32 = pow(tmp405, tmp178);
	let tmp023: t_sea_surface_params = c_sea_surface_params;
	let tmp184: t_sea_surface_params = c_sea_surface_params;
	let tmp179: f32 = (tmp029 * tmp184.v_amplitude_multiplier);
	let tmp606: vec3<f32> = vec3<f32>(tmp607.x, tmp607.z, tmp607.y);
	let tmp482: vec3<f32> = vec3<f32>(tmp481.v_scale, tmp481.v_scale, tmp481.v_scale);
	let tmp186: f32 = (tmp187 * tmp029);
	let tmp339: f32 = (tmp473 + tmp406);
	let tmp035: f32 = (tmp023.v_zero + tmp036);
	let tmp004: vec2<f32> = vec2<f32>(tmp606.x, tmp606.y);
	let tmp338: f32 = (tmp339 * tmp179);
	let tmp480: vec3<f32> = (tmp606 * tmp482);
	let tmp006: t_params = u_params;
	let tmp002: vec3<f32> = tmp606;
	let tmp005: f32 = length(tmp004);
	let tmp185: f32 = (tmp035 + tmp186);
	let tmp337: f32 = (tmp185 + tmp338);
	let tmp024: vec3<f32> = tmp480;
	let tmp007: f32 = (tmp005 - tmp006.v_radius);
	let tmp008: f32 = (tmp006.v_bottom - tmp002.z);
	let tmp027: f32 = (tmp024.z - tmp337);
	let tmp009: f32 = max(tmp007, tmp008);
	let tmp010: f32 = max(tmp027, tmp009);
	return t_outlet(tmp010);
}

