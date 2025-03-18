//// PREAMBLE

fn signed_distance_function(pos_: vec3<f32>) -> f32 {
	var pos = pos_;
	pos -= vec3(0.0, 0.1, 0.0);
	pos /= 7.0;
    return compute_main_digraph(pos).v_dist * 7.0;
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

struct t_neo_elem_09_prim {
	v_angle: f32,
	v_r: f32,
	v_wi: f32,
	v_le: f32,
	v_th: f32,
	v_ra: f32,
}

struct t_neo_elem_09_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_00_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_01_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_10_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_00_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_11_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_02_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_00_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_02_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_01_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_10_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_05_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_01_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_11_prim {
	v_dims: vec2<f32>,
}

struct t_neo_elem_02_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_12_prim {
	v_dims: vec2<f32>,
}

struct t_neo_elem_03_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_12_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_03_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_03_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_13_prim {
	v_angle: f32,
	v_r: f32,
	v_wi: f32,
	v_le: f32,
	v_th: f32,
	v_ra: f32,
}

struct t_neo_elem_08_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_04_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_13_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_04_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_04_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_05_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_05_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_06_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_06_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_08_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_06_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_07_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_07_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_07_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_08_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_09_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_10_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_11_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_12_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_neo_elem_13_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
	v_blend: f32,
	v_sym: vec3<f32>,
}

struct t_glsl_const_01 {
	v_o: f32,
}

struct t_glsl_const_03 {
	v_o: f32,
}

struct t_glsl_const_00 {
	v_o: f32,
}

struct t_glsl_const_02 {
	v_o: f32,
}

struct t_glsl_const_04 {
	v_o: f32,
}

struct t_glsl_const_05 {
	v_o: f32,
}

struct t_position {
	v_pos: vec3<f32>,
}
struct t_outlet {
	v_dist: f32,
}

//// INSTANCES

const u_neo_elem_09_prim: t_neo_elem_09_prim = t_neo_elem_09_prim(f32(0.5), f32(0.015), f32(0), f32(0), f32(0), f32(0.002));
const u_neo_elem_09_mod: t_neo_elem_09_mod = t_neo_elem_09_mod(f32(0.002), vec2(0.002, 0.002));
const u_neo_elem_00_prim: t_neo_elem_00_prim = t_neo_elem_00_prim(vec2(0.048, 0.08), vec4(0.01, 0.05, 0.01, 0.05));
const u_neo_elem_01_mod: t_neo_elem_01_mod = t_neo_elem_01_mod(f32(0.05), vec2(0, 0));
const u_neo_elem_10_prim: t_neo_elem_10_prim = t_neo_elem_10_prim(vec2(0.01, 0.002), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_00_transform: t_neo_elem_00_transform = t_neo_elem_00_transform(vec3(0, 0, 0), f32(1), vec4(1, 0, 0, 1), f32(0), vec3(-1, -1, -1));
const u_neo_elem_11_mod: t_neo_elem_11_mod = t_neo_elem_11_mod(f32(0.01), vec2(0, 0));
const u_neo_elem_02_prim: t_neo_elem_02_prim = t_neo_elem_02_prim(vec2(0.017, 0.017), vec4(0.017, 0.017, 0.017, 0.017));
const u_neo_elem_00_mod: t_neo_elem_00_mod = t_neo_elem_00_mod(f32(0.027), vec2(0.01, 0.01));
const u_neo_elem_02_mod: t_neo_elem_02_mod = t_neo_elem_02_mod(f32(0.05), vec2(0, 0));
const u_neo_elem_01_prim: t_neo_elem_01_prim = t_neo_elem_01_prim(vec2(0.038, 0.038), vec4(0.038, 0.038, 0.038, 0.038));
const u_neo_elem_10_mod: t_neo_elem_10_mod = t_neo_elem_10_mod(f32(0.002), vec2(0.002, 0.002));
const u_neo_elem_05_transform: t_neo_elem_05_transform = t_neo_elem_05_transform(vec3(0.014, 0.0527, 0), f32(1), vec4(1, 0, 0, 1), f32(0.003), vec3(-1, -1, -1));
const u_neo_elem_01_transform: t_neo_elem_01_transform = t_neo_elem_01_transform(vec3(0.014, 0.0507, 0), f32(1), vec4(1, 0, 0, 1), f32(0.003), vec3(-1, -1, -1));
const u_neo_elem_11_prim: t_neo_elem_11_prim = t_neo_elem_11_prim(vec2(0.01, 0.001));
const u_neo_elem_02_transform: t_neo_elem_02_transform = t_neo_elem_02_transform(vec3(0.05, 0.032, 0), f32(1), vec4(1, 0, 0, 1), f32(0.003), vec3(-1, -1, -1));
const u_neo_elem_12_prim: t_neo_elem_12_prim = t_neo_elem_12_prim(vec2(0.011, 0.002));
const u_neo_elem_03_prim: t_neo_elem_03_prim = t_neo_elem_03_prim(vec2(0.022, 0.022), vec4(0.022, 0.022, 0.022, 0.022));
const u_neo_elem_12_mod: t_neo_elem_12_mod = t_neo_elem_12_mod(f32(0.0002), vec2(0.0002, 0.0002));
const u_neo_elem_03_mod: t_neo_elem_03_mod = t_neo_elem_03_mod(f32(0.05), vec2(0, 0));
const u_neo_elem_03_transform: t_neo_elem_03_transform = t_neo_elem_03_transform(vec3(-0.02, 0.083, 0), f32(1), vec4(1, 0, 0, 1), f32(0.003), vec3(-1, -1, -1));
const u_neo_elem_13_prim: t_neo_elem_13_prim = t_neo_elem_13_prim(f32(1.4), f32(0.006), f32(0), f32(0), f32(0), f32(0.003));
const u_neo_elem_08_transform: t_neo_elem_08_transform = t_neo_elem_08_transform(vec3(0, -0.085, 0), f32(1), vec4(1, 0, 0, 1), f32(0), vec3(-1, -1, -1));
const u_neo_elem_04_prim: t_neo_elem_04_prim = t_neo_elem_04_prim(vec2(0.05, 0.085), vec4(0.01, 0.05, 0.01, 0.05));
const u_neo_elem_13_mod: t_neo_elem_13_mod = t_neo_elem_13_mod(f32(0.007), vec2(0.003, 0.003));
const u_neo_elem_04_mod: t_neo_elem_04_mod = t_neo_elem_04_mod(f32(0.028), vec2(0.01, 0.01));
const u_neo_elem_04_transform: t_neo_elem_04_transform = t_neo_elem_04_transform(vec3(0, 0, 0), f32(1), vec4(1, 0, 0, 1), f32(0), vec3(-1, -1, -1));
const u_neo_elem_05_prim: t_neo_elem_05_prim = t_neo_elem_05_prim(vec2(0.036, 0.036), vec4(0.036, 0.036, 0.036, 0.036));
const u_neo_elem_05_mod: t_neo_elem_05_mod = t_neo_elem_05_mod(f32(0.05), vec2(0, 0));
const u_neo_elem_06_prim: t_neo_elem_06_prim = t_neo_elem_06_prim(vec2(0.015, 0.015), vec4(0.015, 0.015, 0.015, 0.015));
const u_neo_elem_06_mod: t_neo_elem_06_mod = t_neo_elem_06_mod(f32(0.05), vec2(0, 0));
const u_neo_elem_08_prim: t_neo_elem_08_prim = t_neo_elem_08_prim(vec2(0.015, 0.0595), vec4(0.015, 0.015, 0.015, 0.015));
const u_neo_elem_06_transform: t_neo_elem_06_transform = t_neo_elem_06_transform(vec3(0.05, 0.034, 0), f32(1), vec4(1, 0, 0, 1), f32(0.003), vec3(-1, -1, -1));
const u_neo_elem_07_prim: t_neo_elem_07_prim = t_neo_elem_07_prim(vec2(0.02, 0.02), vec4(0.02, 0.02, 0.02, 0.02));
const u_neo_elem_07_mod: t_neo_elem_07_mod = t_neo_elem_07_mod(f32(0.05), vec2(0, 0));
const u_neo_elem_07_transform: t_neo_elem_07_transform = t_neo_elem_07_transform(vec3(-0.02, 0.085, 0), f32(1), vec4(1, 0, 0, 1), f32(0.003), vec3(-1, -1, -1));
const u_neo_elem_08_mod: t_neo_elem_08_mod = t_neo_elem_08_mod(f32(0.004), vec2(0.002, 0.002));
const u_neo_elem_09_transform: t_neo_elem_09_transform = t_neo_elem_09_transform(vec3(0.021, -0.026, 0.031), f32(1), vec4(0.92388, 0.382683, 0, 0), f32(0), vec3(1, -1, -1));
const u_neo_elem_10_transform: t_neo_elem_10_transform = t_neo_elem_10_transform(vec3(0.021, -0.026, 0.029), f32(1), vec4(0.653282, -0.270598, -0.270598, 0.653281), f32(0), vec3(1, -1, -1));
const u_neo_elem_11_transform: t_neo_elem_11_transform = t_neo_elem_11_transform(vec3(0, -0.049, 0.027), f32(1), vec4(-1, 0, 0, 1), f32(0.003), vec3(-1, -1, -1));
const u_neo_elem_12_transform: t_neo_elem_12_transform = t_neo_elem_12_transform(vec3(0, -0.049, 0.028), f32(1), vec4(-1, 0, 0, 1), f32(0.004), vec3(-1, -1, -1));
const u_neo_elem_13_transform: t_neo_elem_13_transform = t_neo_elem_13_transform(vec3(0, -0.047, 0.03), f32(1), vec4(1, 1, -1, 1), f32(0), vec3(-1, -1, -1));

const c_glsl_const_01: t_glsl_const_01 = t_glsl_const_01(f32(1e-05));
const c_glsl_const_03: t_glsl_const_03 = t_glsl_const_03(f32(2));
const c_glsl_const_00: t_glsl_const_00 = t_glsl_const_00(f32(0));
const c_glsl_const_02: t_glsl_const_02 = t_glsl_const_02(f32(0.25));
const c_glsl_const_04: t_glsl_const_04 = t_glsl_const_04(f32(1));
const c_glsl_const_05: t_glsl_const_05 = t_glsl_const_05(f32(1000));

//// IMPLEMENTATIONS

// FID[0399] ComposeFuncType::Terminal main:(v3 pos)->(sc dist)
// FID[0398] ComposeFuncType::Inlet position:()->(v3 pos)
// FID[0396] ComposeFuncType::Outlet outlet:(sc dist)->()
fn compute_main_digraph(a_pos: vec3<f32>) -> t_outlet {
	let tmp1521: vec3<f32> = (u_neo_elem_01_transform.v_sym);
	let tmp1196: vec3<f32> = ((((((((((((t_position(a_pos).v_pos))))))))))));
	let tmp1334: vec3<f32> = (tmp1196);
	let tmp1522: vec3<f32> = (tmp1334);
	let tmp1500: vec3<f32> = tmp1521;
	let tmp1486: vec3<f32> = (u_neo_elem_00_transform.v_sym);
	let tmp1520: vec3<f32> = tmp1521;
	let tmp1335: vec3<f32> = (tmp1196);
	let tmp1510: vec3<f32> = tmp1521;
	let tmp1518: vec3<f32> = tmp1522;
	let tmp1508: vec3<f32> = tmp1522;
	let tmp1498: vec3<f32> = tmp1522;
	let tmp1475: vec3<f32> = tmp1486;
	let tmp1497: f32 = (tmp1498.z);
	let tmp1509: f32 = (tmp1510.y);
	let tmp1465: vec3<f32> = tmp1486;
	let tmp1463: vec3<f32> = (tmp1335);
	let tmp1499: f32 = (tmp1500.z);
	let tmp1507: f32 = (tmp1508.y);
	let tmp1493: t_glsl_const_00 = c_glsl_const_00;
	let tmp1519: f32 = (tmp1520.x);
	let tmp1487: vec3<f32> = (tmp1335);
	let tmp1517: f32 = (tmp1518.x);
	let tmp1483: vec3<f32> = tmp1487;
	let tmp1505: vec3<f32> = tmp1522;
	let tmp1503: t_glsl_const_00 = c_glsl_const_00;
	let tmp1495: vec3<f32> = tmp1522;
	let tmp1485: vec3<f32> = tmp1486;
	let tmp1513: t_glsl_const_00 = c_glsl_const_00;
	let tmp1515: vec3<f32> = tmp1522;
	let tmp1473: vec3<f32> = tmp1487;
	let tmp1460: vec3<f32> = tmp1487;
	let tmp1482: f32 = (tmp1483.x);
	let tmp1512: f32 = step(tmp1513.v_o, tmp1519);
	let tmp1484: f32 = (tmp1485.x);
	let tmp1504: f32 = (tmp1505.y);
	let tmp1947: t_neo_elem_01_prim = u_neo_elem_01_prim;
	let tmp1480: vec3<f32> = tmp1487;
	let tmp1494: f32 = (tmp1495.z);
	let tmp1496: f32 = abs(tmp1497);
	let tmp1502: f32 = step(tmp1503.v_o, tmp1509);
	let tmp1492: f32 = step(tmp1493.v_o, tmp1499);
	let tmp1992: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))) - ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) - ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) - ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1515.x), abs(tmp1517), tmp1512), mix(tmp1504, abs(tmp1507), tmp1502), mix(tmp1494, tmp1496, tmp1492))) - (u_neo_elem_01_transform.v_trans))) / vec3<f32>((u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))) - ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) - ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) - ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).y) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).x) / length((u_neo_elem_01_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).w) / length((u_neo_elem_01_transform.v_quat)))) + ((((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat))) * (((u_neo_elem_01_transform.v_quat).z) / length((u_neo_elem_01_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1515.x), abs(tmp1517), tmp1512), mix(tmp1504, abs(tmp1507), tmp1502), mix(tmp1494, tmp1496, tmp1492))) - (u_neo_elem_01_transform.v_trans))) / vec3<f32>((u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale))))).z);
	let tmp1514: f32 = (tmp1515.x);
	let tmp1506: f32 = abs(tmp1507);
	let tmp1458: t_glsl_const_00 = c_glsl_const_00;
	let tmp1057: vec3<f32> = (((((((((((t_position(a_pos).v_pos)))))))))));
	let tmp1462: f32 = (tmp1463.z);
	let tmp1474: f32 = (tmp1475.y);
	let tmp1464: f32 = (tmp1465.z);
	let tmp1468: t_glsl_const_00 = c_glsl_const_00;
	let tmp1470: vec3<f32> = tmp1487;
	let tmp1472: f32 = (tmp1473.y);
	let tmp1516: f32 = abs(tmp1517);
	let tmp1478: t_glsl_const_00 = c_glsl_const_00;
	let tmp1459: f32 = (tmp1460.z);
	let tmp1914: vec4<f32> = (u_neo_elem_01_transform.v_quat);
	let tmp1906: vec4<f32> = tmp1914;
	let tmp1461: f32 = abs(tmp1462);
	let tmp1949: vec2<f32> = (tmp1947.v_dims);
	let tmp2070: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))) - ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) - ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) - ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1480.x), abs(tmp1482), step(tmp1478.v_o, tmp1484)), mix((tmp1470.y), abs(tmp1472), step(tmp1468.v_o, tmp1474)), mix(tmp1459, tmp1461, step(tmp1458.v_o, tmp1464)))) - (u_neo_elem_00_transform.v_trans))) / vec3<f32>((u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))) - ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) - ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) - ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).y) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).x) / length((u_neo_elem_00_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).w) / length((u_neo_elem_00_transform.v_quat)))) + ((((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat))) * (((u_neo_elem_00_transform.v_quat).z) / length((u_neo_elem_00_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1480.x), abs(tmp1482), step(tmp1478.v_o, tmp1484)), mix((tmp1470.y), abs(tmp1472), step(tmp1468.v_o, tmp1474)), mix(tmp1459, tmp1461, step(tmp1458.v_o, tmp1464)))) - (u_neo_elem_00_transform.v_trans))) / vec3<f32>((u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale))))).z);
	let tmp1903: vec4<f32> = tmp1914;
	let tmp1912: vec4<f32> = tmp1914;
	let tmp1963: vec2<f32> = (tmp1992);
	let tmp1467: f32 = step(tmp1468.v_o, tmp1474);
	let tmp1501: f32 = mix(tmp1504, tmp1506, tmp1502);
	let tmp2025: t_neo_elem_00_prim = u_neo_elem_00_prim;
	let tmp1469: f32 = (tmp1470.y);
	let tmp1457: f32 = step(tmp1458.v_o, tmp1464);
	let tmp1511: f32 = mix(tmp1514, tmp1516, tmp1512);
	let tmp1471: f32 = abs(tmp1472);
	let tmp1977: vec2<f32> = abs((tmp1992));
	let tmp1909: vec4<f32> = tmp1914;
	let tmp1954: vec2<f32> = (tmp1992);
	let tmp1479: f32 = (tmp1480.x);
	let tmp1948: vec2<f32> = (tmp1992);
	let tmp1369: vec3<f32> = (u_neo_elem_02_transform.v_sym);
	let tmp1491: f32 = mix(tmp1494, tmp1496, tmp1492);
	let tmp1477: f32 = step(tmp1478.v_o, tmp1484);
	let tmp1195: vec3<f32> = (tmp1057);
	let tmp1481: f32 = abs(tmp1482);
	let tmp1950: vec4<f32> = (tmp1947.v_radius);
	let tmp2041: vec2<f32> = (tmp2070);
	let tmp1956: vec4<f32> = tmp1950;
	let tmp1955: f32 = (tmp1954.x);
	let tmp1366: vec3<f32> = (tmp1195);
	let tmp1905: f32 = (tmp1906.y);
	let tmp1979: vec2<f32> = vec2<f32>(mix(mix((tmp1950.w), (tmp1950.y), step(c_glsl_const_00.v_o, (tmp1963.x))), mix((tmp1950.z), (tmp1956.x), step(c_glsl_const_00.v_o, tmp1955)), step(c_glsl_const_00.v_o, (tmp1948.y))), mix(mix((tmp1950.w), (tmp1950.y), step(c_glsl_const_00.v_o, (tmp1963.x))), mix((tmp1950.z), (tmp1956.x), step(c_glsl_const_00.v_o, tmp1955)), step(c_glsl_const_00.v_o, (tmp1948.y))));
	let tmp1978: vec2<f32> = (tmp1977 - tmp1949);
	let tmp1911: f32 = (tmp1912.w);
	let tmp1358: vec3<f32> = tmp1369;
	let tmp1356: vec3<f32> = (tmp1195);
	let tmp1348: vec3<f32> = tmp1369;
	let tmp2032: vec2<f32> = (tmp2070);
	let tmp1368: vec3<f32> = tmp1369;
	let tmp1346: vec3<f32> = (tmp1195);
	let tmp1476: f32 = mix(tmp1479, tmp1481, tmp1477);
	let tmp1466: f32 = mix(tmp1469, tmp1471, tmp1467);
	let tmp1967: vec4<f32> = tmp1950;
	let tmp1908: f32 = (tmp1909.x);
	let tmp2028: vec4<f32> = (tmp2025.v_radius);
	let tmp1844: vec4<f32> = (u_neo_elem_00_transform.v_quat);
	let tmp1965: vec4<f32> = tmp1950;
	let tmp1964: f32 = (tmp1963.x);
	let tmp1902: f32 = (tmp1903.z);
	let tmp1842: vec4<f32> = tmp1844;
	let tmp1972: vec2<f32> = tmp1948;
	let tmp1960: t_glsl_const_00 = c_glsl_const_00;
	let tmp1839: vec4<f32> = tmp1844;
	let tmp1836: vec4<f32> = tmp1844;
	let tmp1833: vec4<f32> = tmp1844;
	let tmp2055: vec2<f32> = abs((tmp2070));
	let tmp1951: t_glsl_const_00 = c_glsl_const_00;
	let tmp2027: vec2<f32> = (tmp2025.v_dims);
	let tmp1958: vec4<f32> = tmp1950;
	let tmp1370: vec3<f32> = (tmp1195);
	let tmp2026: vec2<f32> = (tmp2070);
	let tmp1969: t_glsl_const_00 = c_glsl_const_00;
	let tmp1952: t_glsl_const_00 = c_glsl_const_00;
	let tmp1456: f32 = mix(tmp1459, tmp1461, tmp1457);
	let tmp1490: vec3<f32> = vec3<f32>(tmp1511, tmp1501, tmp1491);
	let tmp1913: f32 = length(tmp1914);
	let tmp1966: f32 = (tmp1965.y);
	let tmp1961: f32 = step(tmp1960.v_o, tmp1955);
	let tmp1959: f32 = (tmp1958.z);
	let tmp1957: f32 = (tmp1956.x);
	let tmp1953: vec2<f32> = vec2<f32>(tmp1951.v_o, tmp1952.v_o);
	let tmp1980: vec2<f32> = (tmp1978 + tmp1979);
	let tmp1910: f32 = (tmp1911 / tmp1913);
	let tmp1843: f32 = length(tmp1844);
	let tmp1832: f32 = (tmp1833.z);
	let tmp1835: f32 = (tmp1836.y);
	let tmp1838: f32 = (tmp1839.x);
	let tmp1841: f32 = (tmp1842.w);
	let tmp1899: f32 = (tmp1910 * tmp1910);
	let tmp1898: f32 = ((tmp1908 / tmp1913) * (tmp1908 / tmp1913));
	let tmp1854: f32 = ((tmp1902 / tmp1913) * (tmp1902 / tmp1913));
	let tmp1855: f32 = (tmp1910 * tmp1910);
	let tmp1876: f32 = ((tmp1905 / tmp1913) * (tmp1905 / tmp1913));
	let tmp1877: f32 = (tmp1910 * tmp1910);
	let tmp1613: vec3<f32> = (u_neo_elem_01_transform.v_trans);
	let tmp1614: vec3<f32> = (tmp1490);
	let tmp2057: vec2<f32> = vec2<f32>(mix(mix((tmp2028.w), (tmp2028.y), step(c_glsl_const_00.v_o, (tmp2041.x))), mix((tmp2028.z), (tmp2028.x), step(c_glsl_const_00.v_o, (tmp2032.x))), step(c_glsl_const_00.v_o, (tmp2026.y))), mix(mix((tmp2028.w), (tmp2028.y), step(c_glsl_const_00.v_o, (tmp2041.x))), mix((tmp2028.z), (tmp2028.x), step(c_glsl_const_00.v_o, (tmp2032.x))), step(c_glsl_const_00.v_o, (tmp2026.y))));
	let tmp2056: vec2<f32> = (tmp2055 - tmp2027);
	let tmp1341: t_glsl_const_00 = c_glsl_const_00;
	let tmp1343: vec3<f32> = tmp1370;
	let tmp1345: f32 = (tmp1346.z);
	let tmp2050: vec2<f32> = tmp2026;
	let tmp1347: f32 = (tmp1348.z);
	let tmp1351: t_glsl_const_00 = c_glsl_const_00;
	let tmp2047: t_glsl_const_00 = c_glsl_const_00;
	let tmp1353: vec3<f32> = tmp1370;
	let tmp2045: vec4<f32> = tmp2028;
	let tmp1355: f32 = (tmp1356.y);
	let tmp2043: vec4<f32> = tmp2028;
	let tmp2042: f32 = (tmp2041.x);
	let tmp1357: f32 = (tmp1358.y);
	let tmp1361: t_glsl_const_00 = c_glsl_const_00;
	let tmp1363: vec3<f32> = tmp1370;
	let tmp2038: t_glsl_const_00 = c_glsl_const_00;
	let tmp1365: f32 = (tmp1366.x);
	let tmp1367: f32 = (tmp1368.x);
	let tmp2036: vec4<f32> = tmp2028;
	let tmp1904: f32 = (tmp1905 / tmp1913);
	let tmp1901: f32 = (tmp1902 / tmp1913);
	let tmp2034: vec4<f32> = tmp2028;
	let tmp2033: f32 = (tmp2032.x);
	let tmp2030: t_glsl_const_00 = c_glsl_const_00;
	let tmp2029: t_glsl_const_00 = c_glsl_const_00;
	let tmp1907: f32 = (tmp1908 / tmp1913);
	let tmp1983: vec2<f32> = tmp1980;
	let tmp1455: vec3<f32> = vec3<f32>(tmp1476, tmp1466, tmp1456);
	let tmp1981: vec2<f32> = tmp1980;
	let tmp1974: t_glsl_const_00 = c_glsl_const_00;
	let tmp1973: f32 = (tmp1972.y);
	let tmp1970: f32 = step(tmp1969.v_o, tmp1964);
	let tmp1968: f32 = (tmp1967.w);
	let tmp2046: f32 = (tmp2045.w);
	let tmp1892: f32 = (tmp1907 * tmp1904);
	let tmp1829: f32 = ((tmp1841 / tmp1843) * (tmp1841 / tmp1843));
	let tmp1840: f32 = (tmp1841 / tmp1843);
	let tmp1881: f32 = (tmp1910 * tmp1901);
	let tmp1988: vec2<f32> = max(tmp1980, tmp1953);
	let tmp1975: f32 = step(tmp1974.v_o, tmp1973);
	let tmp1828: f32 = ((tmp1838 / tmp1843) * (tmp1838 / tmp1843));
	let tmp1886: f32 = (tmp1910 * tmp1904);
	let tmp1887: f32 = (tmp1907 * tmp1901);
	let tmp918: vec3<f32> = ((((((((((t_position(a_pos).v_pos))))))))));
	let tmp1982: f32 = (tmp1981.x);
	let tmp1807: f32 = (tmp1840 * tmp1840);
	let tmp1784: f32 = ((tmp1832 / tmp1843) * (tmp1832 / tmp1843));
	let tmp1785: f32 = (tmp1840 * tmp1840);
	let tmp2061: vec2<f32> = (tmp2056 + tmp2057);
	let tmp1704: f32 = (u_neo_elem_01_transform.v_scale);
	let tmp2059: vec2<f32> = (tmp2056 + tmp2057);
	let tmp1900: t_glsl_const_03 = c_glsl_const_03;
	let tmp2052: t_glsl_const_00 = c_glsl_const_00;
	let tmp2051: f32 = (tmp2050.y);
	let tmp1984: f32 = (tmp1983.y);
	let tmp2048: f32 = step(tmp2047.v_o, tmp2042);
	let tmp1891: f32 = (tmp1910 * tmp1901);
	let tmp2044: f32 = (tmp2043.y);
	let tmp1837: f32 = (tmp1838 / tmp1843);
	let tmp1806: f32 = ((tmp1835 / tmp1843) * (tmp1835 / tmp1843));
	let tmp2039: f32 = step(tmp2038.v_o, tmp2033);
	let tmp2058: vec2<f32> = (tmp2056 + tmp2057);
	let tmp1853: f32 = (tmp1855 + tmp1854);
	let tmp1856: t_glsl_const_03 = c_glsl_const_03;
	let tmp1859: f32 = (tmp1910 * tmp1907);
	let tmp1860: f32 = (tmp1904 * tmp1901);
	let tmp1864: f32 = (tmp1910 * tmp1904);
	let tmp1865: f32 = (tmp1907 * tmp1901);
	let tmp1869: f32 = (tmp1910 * tmp1907);
	let tmp1870: f32 = (tmp1904 * tmp1901);
	let tmp1875: f32 = (tmp1877 + tmp1876);
	let tmp1608: vec3<f32> = (u_neo_elem_00_transform.v_trans);
	let tmp1609: vec3<f32> = (tmp1455);
	let tmp1878: t_glsl_const_03 = c_glsl_const_03;
	let tmp1612: vec3<f32> = (tmp1614 - tmp1613);
	let tmp1962: f32 = mix(tmp1959, tmp1957, tmp1961);
	let tmp2148: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))) - ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) - ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) - ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1363.x), abs(tmp1365), step(tmp1361.v_o, tmp1367)), mix((tmp1353.y), abs(tmp1355), step(tmp1351.v_o, tmp1357)), mix((tmp1343.z), abs(tmp1345), step(tmp1341.v_o, tmp1347)))) - (u_neo_elem_02_transform.v_trans))) / vec3<f32>((u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))) - ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) - ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) - ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).y) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).x) / length((u_neo_elem_02_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).w) / length((u_neo_elem_02_transform.v_quat)))) + ((((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat))) * (((u_neo_elem_02_transform.v_quat).z) / length((u_neo_elem_02_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1363.x), abs(tmp1365), step(tmp1361.v_o, tmp1367)), mix((tmp1353.y), abs(tmp1355), step(tmp1351.v_o, tmp1357)), mix((tmp1343.z), abs(tmp1345), step(tmp1341.v_o, tmp1347)))) - (u_neo_elem_02_transform.v_trans))) / vec3<f32>((u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale))))).z);
	let tmp1831: f32 = (tmp1832 / tmp1843);
	let tmp1354: f32 = abs(tmp1355);
	let tmp1340: f32 = step(tmp1341.v_o, tmp1347);
	let tmp1342: f32 = (tmp1343.z);
	let tmp2103: t_neo_elem_02_prim = u_neo_elem_02_prim;
	let tmp1344: f32 = abs(tmp1345);
	let tmp1882: f32 = (tmp1907 * tmp1904);
	let tmp2031: vec2<f32> = vec2<f32>(tmp2029.v_o, tmp2030.v_o);
	let tmp1350: f32 = step(tmp1351.v_o, tmp1357);
	let tmp1352: f32 = (tmp1353.y);
	let tmp1834: f32 = (tmp1835 / tmp1843);
	let tmp1360: f32 = step(tmp1361.v_o, tmp1367);
	let tmp1897: f32 = (tmp1899 + tmp1898);
	let tmp1362: f32 = (tmp1363.x);
	let tmp1364: f32 = abs(tmp1365);
	let tmp2035: f32 = (tmp2034.x);
	let tmp1971: f32 = mix(tmp1968, tmp1966, tmp1970);
	let tmp2037: f32 = (tmp2036.z);
	let tmp1808: t_glsl_const_03 = c_glsl_const_03;
	let tmp1989: f32 = length(tmp1988);
	let tmp1795: f32 = (tmp1837 * tmp1831);
	let tmp1896: f32 = (tmp1900.v_o * tmp1897);
	let tmp1851: t_glsl_const_04 = c_glsl_const_04;
	let tmp1852: f32 = (tmp1856.v_o * tmp1853);
	let tmp1811: f32 = (tmp1840 * tmp1831);
	let tmp1812: f32 = (tmp1837 * tmp1834);
	let tmp1056: vec3<f32> = (tmp918);
	let tmp2110: vec2<f32> = (tmp2148);
	let tmp1858: f32 = (tmp1860 + tmp1859);
	let tmp1830: t_glsl_const_03 = c_glsl_const_03;
	let tmp1893: t_glsl_const_03 = c_glsl_const_03;
	let tmp1861: t_glsl_const_03 = c_glsl_const_03;
	let tmp1863: f32 = (tmp1865 - tmp1864);
	let tmp2105: vec2<f32> = (tmp2103.v_dims);
	let tmp1885: f32 = (tmp1887 + tmp1886);
	let tmp1866: t_glsl_const_03 = c_glsl_const_03;
	let tmp1868: f32 = (tmp1870 - tmp1869);
	let tmp2066: vec2<f32> = max(tmp2058, tmp2031);
	let tmp1816: f32 = (tmp1840 * tmp1834);
	let tmp1871: t_glsl_const_03 = c_glsl_const_03;
	let tmp1873: t_glsl_const_04 = c_glsl_const_04;
	let tmp1874: f32 = (tmp1878.v_o * tmp1875);
	let tmp1817: f32 = (tmp1837 * tmp1831);
	let tmp2106: vec4<f32> = (tmp2103.v_radius);
	let tmp1607: vec3<f32> = (tmp1609 - tmp1608);
	let tmp2062: f32 = (tmp2061.y);
	let tmp2060: f32 = (tmp2059.x);
	let tmp1976: f32 = mix(tmp1971, tmp1962, tmp1975);
	let tmp2053: f32 = step(tmp2052.v_o, tmp2051);
	let tmp2049: f32 = mix(tmp2046, tmp2044, tmp2048);
	let tmp2119: vec2<f32> = (tmp2148);
	let tmp2040: f32 = mix(tmp2037, tmp2035, tmp2039);
	let tmp1880: f32 = (tmp1882 + tmp1881);
	let tmp1986: t_glsl_const_00 = c_glsl_const_00;
	let tmp1774: vec4<f32> = (u_neo_elem_02_transform.v_quat);
	let tmp1883: t_glsl_const_03 = c_glsl_const_03;
	let tmp1339: f32 = mix(tmp1342, tmp1344, tmp1340);
	let tmp1783: f32 = (tmp1785 + tmp1784);
	let tmp1763: vec4<f32> = tmp1774;
	let tmp1786: t_glsl_const_03 = c_glsl_const_03;
	let tmp1888: t_glsl_const_03 = c_glsl_const_03;
	let tmp1821: f32 = (tmp1840 * tmp1831);
	let tmp1766: vec4<f32> = tmp1774;
	let tmp1789: f32 = (tmp1840 * tmp1837);
	let tmp1790: f32 = (tmp1834 * tmp1831);
	let tmp1705: vec3<f32> = (tmp1612);
	let tmp1703: vec3<f32> = vec3<f32>(tmp1704, tmp1704, tmp1704);
	let tmp2104: vec2<f32> = (tmp2148);
	let tmp1822: f32 = (tmp1837 * tmp1834);
	let tmp1769: vec4<f32> = tmp1774;
	let tmp1895: t_glsl_const_04 = c_glsl_const_04;
	let tmp1794: f32 = (tmp1840 * tmp1834);
	let tmp1890: f32 = (tmp1892 - tmp1891);
	let tmp1985: f32 = max(tmp1982, tmp1984);
	let tmp1799: f32 = (tmp1840 * tmp1837);
	let tmp1772: vec4<f32> = tmp1774;
	let tmp1800: f32 = (tmp1834 * tmp1831);
	let tmp1230: vec3<f32> = (u_neo_elem_03_transform.v_sym);
	let tmp1697: f32 = (u_neo_elem_00_transform.v_scale);
	let tmp1827: f32 = (tmp1829 + tmp1828);
	let tmp1805: f32 = (tmp1807 + tmp1806);
	let tmp2133: vec2<f32> = abs(tmp2104);
	let tmp1359: f32 = mix(tmp1362, tmp1364, tmp1360);
	let tmp1349: f32 = mix(tmp1352, tmp1354, tmp1350);
	let tmp1894: f32 = (tmp1896 - tmp1895.v_o);
	let tmp1820: f32 = (tmp1822 - tmp1821);
	let tmp1823: t_glsl_const_03 = c_glsl_const_03;
	let tmp1825: t_glsl_const_04 = c_glsl_const_04;
	let tmp1826: f32 = (tmp1830.v_o * tmp1827);
	let tmp1231: vec3<f32> = (tmp1056);
	let tmp1987: f32 = min(tmp1985, tmp1986.v_o);
	let tmp1818: t_glsl_const_03 = c_glsl_const_03;
	let tmp1879: f32 = (tmp1883.v_o * tmp1880);
	let tmp2116: t_glsl_const_00 = c_glsl_const_00;
	let tmp2114: vec4<f32> = tmp2106;
	let tmp1207: vec3<f32> = tmp1231;
	let tmp1209: vec3<f32> = tmp1230;
	let tmp1217: vec3<f32> = tmp1231;
	let tmp1219: vec3<f32> = tmp1230;
	let tmp2054: f32 = mix(tmp2049, tmp2040, tmp2053);
	let tmp1229: vec3<f32> = tmp1230;
	let tmp1990: f32 = (tmp1989 - tmp1976);
	let tmp2112: vec4<f32> = tmp2106;
	let tmp1338: vec3<f32> = vec3<f32>(tmp1359, tmp1349, tmp1339);
	let tmp1850: f32 = (tmp1852 - tmp1851.v_o);
	let tmp2111: f32 = (tmp2110.x);
	let tmp2108: t_glsl_const_00 = c_glsl_const_00;
	let tmp2107: t_glsl_const_00 = c_glsl_const_00;
	let tmp1765: f32 = (tmp1766.y);
	let tmp2067: f32 = length(tmp2066);
	let tmp1762: f32 = (tmp1763.z);
	let tmp2064: t_glsl_const_00 = c_glsl_const_00;
	let tmp2063: f32 = max(tmp2060, tmp2062);
	let tmp1768: f32 = (tmp1769.x);
	let tmp1857: f32 = (tmp1861.v_o * tmp1858);
	let tmp1696: vec3<f32> = vec3<f32>(tmp1697, tmp1697, tmp1697);
	let tmp1698: vec3<f32> = (tmp1607);
	let tmp1781: t_glsl_const_04 = c_glsl_const_04;
	let tmp1782: f32 = (tmp1786.v_o * tmp1783);
	let tmp1862: f32 = (tmp1866.v_o * tmp1863);
	let tmp1788: f32 = (tmp1790 + tmp1789);
	let tmp1884: f32 = (tmp1888.v_o * tmp1885);
	let tmp1227: vec3<f32> = tmp1231;
	let tmp1773: f32 = length(tmp1774);
	let tmp1791: t_glsl_const_03 = c_glsl_const_03;
	let tmp1771: f32 = (tmp1772.w);
	let tmp1702: vec3<f32> = (tmp1705 / tmp1703);
	let tmp1889: f32 = (tmp1893.v_o * tmp1890);
	let tmp1793: f32 = (tmp1795 - tmp1794);
	let tmp1867: f32 = (tmp1871.v_o * tmp1868);
	let tmp1796: t_glsl_const_03 = c_glsl_const_03;
	let tmp1798: f32 = (tmp1800 - tmp1799);
	let tmp1801: t_glsl_const_03 = c_glsl_const_03;
	let tmp1803: t_glsl_const_04 = c_glsl_const_04;
	let tmp1872: f32 = (tmp1874 - tmp1873.v_o);
	let tmp1804: f32 = (tmp1808.v_o * tmp1805);
	let tmp2135: vec2<f32> = vec2<f32>(mix(mix((tmp2106.w), (tmp2106.y), step(c_glsl_const_00.v_o, (tmp2119.x))), mix((tmp2114.z), (tmp2112.x), step(tmp2116.v_o, tmp2111)), step(c_glsl_const_00.v_o, (tmp2104.y))), mix(mix((tmp2106.w), (tmp2106.y), step(c_glsl_const_00.v_o, (tmp2119.x))), mix((tmp2114.z), (tmp2112.x), step(tmp2116.v_o, tmp2111)), step(c_glsl_const_00.v_o, (tmp2104.y))));
	let tmp2134: vec2<f32> = (tmp2133 - tmp2105);
	let tmp1810: f32 = (tmp1812 + tmp1811);
	let tmp1813: t_glsl_const_03 = c_glsl_const_03;
	let tmp2128: vec2<f32> = tmp2104;
	let tmp2125: t_glsl_const_00 = c_glsl_const_00;
	let tmp1815: f32 = (tmp1817 + tmp1816);
	let tmp2123: vec4<f32> = tmp2106;
	let tmp2121: vec4<f32> = tmp2106;
	let tmp2120: f32 = (tmp2119.x);
	let tmp2129: f32 = (tmp2128.y);
	let tmp2130: t_glsl_const_00 = c_glsl_const_00;
	let tmp2137: vec2<f32> = (tmp2134 + tmp2135);
	let tmp1228: f32 = (tmp1229.x);
	let tmp1526: vec3<f32> = (u_neo_elem_02_transform.v_trans);
	let tmp1770: f32 = (tmp1771 / tmp1773);
	let tmp1226: f32 = (tmp1227.x);
	let tmp1767: f32 = (tmp1768 / tmp1773);
	let tmp1224: vec3<f32> = tmp1231;
	let tmp1222: t_glsl_const_00 = c_glsl_const_00;
	let tmp1218: f32 = (tmp1219.y);
	let tmp1216: f32 = (tmp1217.y);
	let tmp2139: vec2<f32> = (tmp2134 + tmp2135);
	let tmp1527: vec3<f32> = (tmp1338);
	let tmp1214: vec3<f32> = tmp1231;
	let tmp1212: t_glsl_const_00 = c_glsl_const_00;
	let tmp1208: f32 = (tmp1209.z);
	let tmp1206: f32 = (tmp1207.z);
	let tmp1204: vec3<f32> = tmp1231;
	let tmp1202: t_glsl_const_00 = c_glsl_const_00;
	let tmp1695: vec3<f32> = (tmp1698 / tmp1696);
	let tmp1714: f32 = ((tmp1762 / tmp1773) * (tmp1762 / tmp1773));
	let tmp1715: f32 = (tmp1770 * tmp1770);
	let tmp1737: f32 = (tmp1770 * tmp1770);
	let tmp1758: f32 = (tmp1767 * tmp1767);
	let tmp1759: f32 = (tmp1770 * tmp1770);
	let tmp1780: f32 = (tmp1782 - tmp1781.v_o);
	let tmp1787: f32 = (tmp1791.v_o * tmp1788);
	let tmp1792: f32 = (tmp1796.v_o * tmp1793);
	let tmp1797: f32 = (tmp1801.v_o * tmp1798);
	let tmp1764: f32 = (tmp1765 / tmp1773);
	let tmp1802: f32 = (tmp1804 - tmp1803.v_o);
	let tmp1809: f32 = (tmp1813.v_o * tmp1810);
	let tmp1814: f32 = (tmp1818.v_o * tmp1815);
	let tmp1819: f32 = (tmp1823.v_o * tmp1820);
	let tmp1824: f32 = (tmp1826 - tmp1825.v_o);
	let tmp1849: mat3x3<f32> = mat3x3<f32>(tmp1894, tmp1889, tmp1884, tmp1879, tmp1872, tmp1867, tmp1862, tmp1857, tmp1850);
	let tmp1736: f32 = (tmp1764 * tmp1764);
	let tmp1915: vec3<f32> = (tmp1702);
	let tmp1919: f32 = (u_neo_elem_01_mod.v_height);
	let tmp1991: f32 = (tmp1987 + tmp1990);
	let tmp2065: f32 = min(tmp2063, tmp2064.v_o);
	let tmp2068: f32 = (tmp2067 - tmp2054);
	let tmp2109: vec2<f32> = vec2<f32>(tmp2107.v_o, tmp2108.v_o);
	let tmp2113: f32 = (tmp2112.x);
	let tmp2115: f32 = (tmp2114.z);
	let tmp1761: f32 = (tmp1762 / tmp1773);
	let tmp2117: f32 = step(tmp2116.v_o, tmp2111);
	let tmp2136: vec2<f32> = (tmp2134 + tmp2135);
	let tmp2122: f32 = (tmp2121.y);
	let tmp2124: f32 = (tmp2123.w);
	let tmp2126: f32 = step(tmp2125.v_o, tmp2120);
	let tmp1757: f32 = (tmp1759 + tmp1758);
	let tmp1725: f32 = (tmp1767 * tmp1761);
	let tmp1719: f32 = (tmp1770 * tmp1767);
	let tmp1716: t_glsl_const_03 = c_glsl_const_03;
	let tmp2226: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))) - ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) - ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) - ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1224.x), abs(tmp1226), step(tmp1222.v_o, tmp1228)), mix((tmp1214.y), abs(tmp1216), step(tmp1212.v_o, tmp1218)), mix((tmp1204.z), abs(tmp1206), step(tmp1202.v_o, tmp1208)))) - (u_neo_elem_03_transform.v_trans))) / vec3<f32>((u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))) - ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) - ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) - ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).y) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).x) / length((u_neo_elem_03_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).w) / length((u_neo_elem_03_transform.v_quat)))) + ((((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat))) * (((u_neo_elem_03_transform.v_quat).z) / length((u_neo_elem_03_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1224.x), abs(tmp1226), step(tmp1222.v_o, tmp1228)), mix((tmp1214.y), abs(tmp1216), step(tmp1212.v_o, tmp1218)), mix((tmp1204.z), abs(tmp1206), step(tmp1202.v_o, tmp1208)))) - (u_neo_elem_03_transform.v_trans))) / vec3<f32>((u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale))))).z);
	let tmp1713: f32 = (tmp1715 + tmp1714);
	let tmp2140: f32 = (tmp2139.y);
	let tmp1746: f32 = (tmp1770 * tmp1764);
	let tmp1724: f32 = (tmp1770 * tmp1764);
	let tmp1221: f32 = step(tmp1222.v_o, tmp1228);
	let tmp1741: f32 = (tmp1770 * tmp1761);
	let tmp2131: f32 = step(tmp2130.v_o, tmp2129);
	let tmp1620: f32 = (u_neo_elem_02_transform.v_scale);
	let tmp2138: f32 = (tmp2137.x);
	let tmp1916: t_neo_elem_01_mod = u_neo_elem_01_mod;
	let tmp2118: f32 = mix(tmp2115, tmp2113, tmp2117);
	let tmp1760: t_glsl_const_03 = c_glsl_const_03;
	let tmp1525: vec3<f32> = (tmp1527 - tmp1526);
	let tmp1742: f32 = (tmp1767 * tmp1764);
	let tmp2127: f32 = mix(tmp2124, tmp2122, tmp2126);
	let tmp1917: f32 = (tmp1991);
	let tmp1848: vec3<f32> = (tmp1849 * tmp1915);
	let tmp2144: vec2<f32> = max(tmp2136, tmp2109);
	let tmp2069: f32 = (tmp2065 + tmp2068);
	let tmp1751: f32 = (tmp1770 * tmp1761);
	let tmp1738: t_glsl_const_03 = c_glsl_const_03;
	let tmp1997: f32 = (u_neo_elem_00_mod.v_height);
	let tmp1201: f32 = step(tmp1202.v_o, tmp1208);
	let tmp1223: f32 = (tmp1224.x);
	let tmp1752: f32 = (tmp1767 * tmp1764);
	let tmp1845: vec3<f32> = (tmp1695);
	let tmp1203: f32 = (tmp1204.z);
	let tmp1933: f32 = abs((tmp1848.y));
	let tmp1205: f32 = abs(tmp1206);
	let tmp1735: f32 = (tmp1737 + tmp1736);
	let tmp2181: t_neo_elem_03_prim = u_neo_elem_03_prim;
	let tmp1779: mat3x3<f32> = mat3x3<f32>(tmp1824, tmp1819, tmp1814, tmp1809, tmp1802, tmp1797, tmp1792, tmp1787, tmp1780);
	let tmp1211: f32 = step(tmp1212.v_o, tmp1218);
	let tmp1730: f32 = (tmp1764 * tmp1761);
	let tmp1720: f32 = (tmp1764 * tmp1761);
	let tmp1213: f32 = (tmp1214.y);
	let tmp1225: f32 = abs(tmp1226);
	let tmp1215: f32 = abs(tmp1216);
	let tmp1928: f32 = (tmp1919 - mix(((tmp1916.v_radius).y), ((tmp1916.v_radius).x), step(c_glsl_const_00.v_o, (tmp1848.y))));
	let tmp1729: f32 = (tmp1770 * tmp1767);
	let tmp1747: f32 = (tmp1767 * tmp1761);
	let tmp2197: vec2<f32> = (tmp2226);
	let tmp783: vec3<f32> = (((((((((t_position(a_pos).v_pos)))))))));
	let tmp1920: vec2<f32> = (tmp1916.v_radius);
	let tmp2183: vec2<f32> = (tmp2181.v_dims);
	let tmp2141: f32 = max(tmp2138, tmp2140);
	let tmp1748: t_glsl_const_03 = c_glsl_const_03;
	let tmp1750: f32 = (tmp1752 - tmp1751);
	let tmp1932: f32 = (tmp1917 + mix((tmp1920.y), (tmp1920.x), step(c_glsl_const_00.v_o, (tmp1848.y))));
	let tmp1200: f32 = mix(tmp1203, tmp1205, tmp1201);
	let tmp1934: f32 = (tmp1933 - tmp1928);
	let tmp2211: vec2<f32> = abs((tmp2226));
	let tmp1210: f32 = mix(tmp1213, tmp1215, tmp1211);
	let tmp1930: t_glsl_const_00 = c_glsl_const_00;
	let tmp1929: t_glsl_const_00 = c_glsl_const_00;
	let tmp1778: vec3<f32> = (tmp1779 * tmp1845);
	let tmp2142: t_glsl_const_00 = c_glsl_const_00;
	let tmp1220: f32 = mix(tmp1223, tmp1225, tmp1221);
	let tmp1679: vec4<f32> = (u_neo_elem_03_transform.v_quat);
	let tmp1682: vec4<f32> = (u_neo_elem_03_transform.v_quat);
	let tmp1685: vec4<f32> = (u_neo_elem_03_transform.v_quat);
	let tmp1753: t_glsl_const_03 = c_glsl_const_03;
	let tmp1690: vec4<f32> = (u_neo_elem_03_transform.v_quat);
	let tmp1619: vec3<f32> = vec3<f32>(tmp1620, tmp1620, tmp1620);
	let tmp1621: vec3<f32> = (tmp1525);
	let tmp1688: vec4<f32> = tmp1690;
	let tmp1728: f32 = (tmp1730 - tmp1729);
	let tmp2184: vec4<f32> = (tmp2181.v_radius);
	let tmp1994: t_neo_elem_00_mod = u_neo_elem_00_mod;
	let tmp1711: t_glsl_const_04 = c_glsl_const_04;
	let tmp1712: f32 = (tmp1716.v_o * tmp1713);
	let tmp2011: f32 = abs((tmp1778.y));
	let tmp2182: vec2<f32> = (tmp2226);
	let tmp1755: t_glsl_const_04 = c_glsl_const_04;
	let tmp2132: f32 = mix(tmp2127, tmp2118, tmp2131);
	let tmp2006: f32 = (tmp1997 - mix(((tmp1994.v_radius).y), ((tmp1994.v_radius).x), step(c_glsl_const_00.v_o, (tmp1778.y))));
	let tmp1756: f32 = (tmp1760.v_o * tmp1757);
	let tmp1993: vec3<f32> = tmp1848;
	let tmp1995: f32 = (tmp2069);
	let tmp1718: f32 = (tmp1720 + tmp1719);
	let tmp1721: t_glsl_const_03 = c_glsl_const_03;
	let tmp1723: f32 = (tmp1725 - tmp1724);
	let tmp1726: t_glsl_const_03 = c_glsl_const_03;
	let tmp1731: t_glsl_const_03 = c_glsl_const_03;
	let tmp1733: t_glsl_const_04 = c_glsl_const_04;
	let tmp1734: f32 = (tmp1738.v_o * tmp1735);
	let tmp1740: f32 = (tmp1742 + tmp1741);
	let tmp1743: t_glsl_const_03 = c_glsl_const_03;
	let tmp1745: f32 = (tmp1747 + tmp1746);
	let tmp2145: f32 = length(tmp2144);
	let tmp2188: vec2<f32> = tmp2182;
	let tmp2198: f32 = (tmp2197.x);
	let tmp2199: vec4<f32> = tmp2184;
	let tmp2201: vec4<f32> = tmp2184;
	let tmp1722: f32 = (tmp1726.v_o * tmp1723);
	let tmp1681: f32 = (tmp1682.y);
	let tmp1754: f32 = (tmp1756 - tmp1755.v_o);
	let tmp1678: f32 = (tmp1679.z);
	let tmp1998: vec2<f32> = (tmp1994.v_radius);
	let tmp2010: f32 = (tmp1995 + mix((tmp1998.y), (tmp1998.x), step(c_glsl_const_00.v_o, (tmp1778.y))));
	let tmp1727: f32 = (tmp1731.v_o * tmp1728);
	let tmp1091: vec3<f32> = (u_neo_elem_04_transform.v_sym);
	let tmp1618: vec3<f32> = (tmp1621 / tmp1619);
	let tmp2213: vec2<f32> = vec2<f32>(mix(mix((tmp2201.w), (tmp2199.y), step(c_glsl_const_00.v_o, tmp2198)), mix((tmp2184.z), (tmp2184.x), step(c_glsl_const_00.v_o, (tmp2188.x))), step(c_glsl_const_00.v_o, (tmp2182.y))), mix(mix((tmp2201.w), (tmp2199.y), step(c_glsl_const_00.v_o, tmp2198)), mix((tmp2184.z), (tmp2184.x), step(c_glsl_const_00.v_o, (tmp2188.x))), step(c_glsl_const_00.v_o, (tmp2182.y))));
	let tmp2212: vec2<f32> = (tmp2211 - tmp2183);
	let tmp1710: f32 = (tmp1712 - tmp1711.v_o);
	let tmp1931: vec2<f32> = vec2<f32>(tmp1929.v_o, tmp1930.v_o);
	let tmp1732: f32 = (tmp1734 - tmp1733.v_o);
	let tmp2008: t_glsl_const_00 = c_glsl_const_00;
	let tmp1938: vec2<f32> = vec2<f32>(tmp1932, tmp1934);
	let tmp1935: vec2<f32> = vec2<f32>(tmp1932, tmp1934);
	let tmp1199: vec3<f32> = vec3<f32>(tmp1220, tmp1210, tmp1200);
	let tmp1739: f32 = (tmp1743.v_o * tmp1740);
	let tmp1687: f32 = (tmp1688.w);
	let tmp2146: f32 = (tmp2145 - tmp2132);
	let tmp1936: vec2<f32> = tmp1935;
	let tmp2012: f32 = (tmp2011 - tmp2006);
	let tmp1918: f32 = (tmp1993.y);
	let tmp1744: f32 = (tmp1748.v_o * tmp1745);
	let tmp1925: t_glsl_const_00 = c_glsl_const_00;
	let tmp2206: vec2<f32> = tmp2182;
	let tmp2185: t_glsl_const_00 = c_glsl_const_00;
	let tmp1684: f32 = (tmp1685.x);
	let tmp2186: t_glsl_const_00 = c_glsl_const_00;
	let tmp1717: f32 = (tmp1721.v_o * tmp1718);
	let tmp1689: f32 = length(tmp1690);
	let tmp2189: f32 = (tmp2188.x);
	let tmp2190: vec4<f32> = tmp2184;
	let tmp1923: vec2<f32> = tmp1920;
	let tmp2192: vec4<f32> = tmp2184;
	let tmp2143: f32 = min(tmp2141, tmp2142.v_o);
	let tmp2071: vec3<f32> = tmp1778;
	let tmp1749: f32 = (tmp1753.v_o * tmp1750);
	let tmp2194: t_glsl_const_00 = c_glsl_const_00;
	let tmp1921: vec2<f32> = tmp1920;
	let tmp2203: t_glsl_const_00 = c_glsl_const_00;
	let tmp2007: t_glsl_const_00 = c_glsl_const_00;
	let tmp1068: vec3<f32> = ((tmp783));
	let tmp2016: vec2<f32> = vec2<f32>(tmp2010, tmp2012);
	let tmp1070: vec3<f32> = tmp1091;
	let tmp1709: mat3x3<f32> = mat3x3<f32>(tmp1754, tmp1749, tmp1744, tmp1739, tmp1732, tmp1727, tmp1722, tmp1717, tmp1710);
	let tmp1686: f32 = (tmp1687 / tmp1689);
	let tmp1675: f32 = (tmp1686 * tmp1686);
	let tmp1674: f32 = ((tmp1684 / tmp1689) * (tmp1684 / tmp1689));
	let tmp1996: f32 = (tmp2071.y);
	let tmp2075: f32 = (u_neo_elem_02_mod.v_height);
	let tmp2147: f32 = (tmp2143 + tmp2146);
	let tmp1652: f32 = ((tmp1681 / tmp1689) * (tmp1681 / tmp1689));
	let tmp1078: vec3<f32> = ((tmp783));
	let tmp1653: f32 = (tmp1686 * tmp1686);
	let tmp1080: vec3<f32> = tmp1091;
	let tmp1088: vec3<f32> = ((tmp783));
	let tmp1090: vec3<f32> = tmp1091;
	let tmp1775: vec3<f32> = (tmp1618);
	let tmp1683: f32 = (tmp1684 / tmp1689);
	let tmp1926: f32 = step(tmp1925.v_o, tmp1918);
	let tmp1680: f32 = (tmp1681 / tmp1689);
	let tmp1677: f32 = (tmp1678 / tmp1689);
	let tmp1924: f32 = (tmp1923.y);
	let tmp1092: vec3<f32> = ((tmp783));
	let tmp1922: f32 = (tmp1921.x);
	let tmp2013: vec2<f32> = vec2<f32>(tmp2010, tmp2012);
	let tmp1630: f32 = (tmp1677 * tmp1677);
	let tmp1631: f32 = (tmp1686 * tmp1686);
	let tmp1374: vec3<f32> = (u_neo_elem_03_transform.v_trans);
	let tmp1375: vec3<f32> = (tmp1199);
	let tmp2187: vec2<f32> = vec2<f32>(tmp2185.v_o, tmp2186.v_o);
	let tmp2191: f32 = (tmp2190.x);
	let tmp2214: vec2<f32> = (tmp2212 + tmp2213);
	let tmp2195: f32 = step(tmp2194.v_o, tmp2189);
	let tmp2200: f32 = (tmp2199.y);
	let tmp2202: f32 = (tmp2201.w);
	let tmp2204: f32 = step(tmp2203.v_o, tmp2198);
	let tmp2207: f32 = (tmp2206.y);
	let tmp2208: t_glsl_const_00 = c_glsl_const_00;
	let tmp2215: vec2<f32> = tmp2214;
	let tmp2217: vec2<f32> = tmp2214;
	let tmp2193: f32 = (tmp2192.z);
	let tmp644: vec3<f32> = ((((((((t_position(a_pos).v_pos))))))));
	let tmp1937: f32 = (tmp1936.x);
	let tmp1939: f32 = (tmp1938.y);
	let tmp1943: vec2<f32> = max(tmp1935, tmp1931);
	let tmp1999: vec2<f32> = tmp1998;
	let tmp2001: vec2<f32> = tmp1998;
	let tmp2003: t_glsl_const_00 = c_glsl_const_00;
	let tmp2009: vec2<f32> = vec2<f32>(tmp2007.v_o, tmp2008.v_o);
	let tmp2014: vec2<f32> = tmp2013;
	let tmp1069: f32 = (tmp1070.z);
	let tmp1635: f32 = (tmp1686 * tmp1683);
	let tmp1083: t_glsl_const_00 = c_glsl_const_00;
	let tmp1073: t_glsl_const_00 = c_glsl_const_00;
	let tmp1085: vec3<f32> = tmp1092;
	let tmp1075: vec3<f32> = tmp1092;
	let tmp1676: t_glsl_const_03 = c_glsl_const_03;
	let tmp1077: f32 = (tmp1078.y);
	let tmp1079: f32 = (tmp1080.y);
	let tmp1087: f32 = (tmp1088.x);
	let tmp1646: f32 = (tmp1680 * tmp1677);
	let tmp2222: vec2<f32> = max(tmp2214, tmp2187);
	let tmp1632: t_glsl_const_03 = c_glsl_const_03;
	let tmp1940: f32 = max(tmp1937, tmp1939);
	let tmp1941: t_glsl_const_00 = c_glsl_const_00;
	let tmp2017: f32 = (tmp2016.y);
	let tmp2073: f32 = (tmp2147);
	let tmp1944: f32 = length(tmp1943);
	let tmp2000: f32 = (tmp1999.x);
	let tmp1663: f32 = (tmp1683 * tmp1677);
	let tmp1063: t_glsl_const_00 = c_glsl_const_00;
	let tmp2002: f32 = (tmp2001.y);
	let tmp1089: f32 = (tmp1090.x);
	let tmp2218: f32 = (tmp2217.y);
	let tmp2216: f32 = (tmp2215.x);
	let tmp2209: f32 = step(tmp2208.v_o, tmp2207);
	let tmp2089: f32 = abs(((tmp1709 * tmp1775).y));
	let tmp2004: f32 = step(tmp2003.v_o, tmp1996);
	let tmp2205: f32 = mix(tmp2202, tmp2200, tmp2204);
	let tmp1629: f32 = (tmp1631 + tmp1630);
	let tmp2196: f32 = mix(tmp2193, tmp2191, tmp2195);
	let tmp1927: f32 = mix(tmp1924, tmp1922, tmp1926);
	let tmp1065: vec3<f32> = tmp1092;
	let tmp1657: f32 = (tmp1686 * tmp1677);
	let tmp1373: vec3<f32> = (tmp1375 - tmp1374);
	let tmp2072: t_neo_elem_02_mod = u_neo_elem_02_mod;
	let tmp1708: vec3<f32> = (tmp1709 * tmp1775);
	let tmp2021: vec2<f32> = max(tmp2013, tmp2009);
	let tmp1067: f32 = (tmp1068.z);
	let tmp1667: f32 = (tmp1686 * tmp1677);
	let tmp1641: f32 = (tmp1683 * tmp1677);
	let tmp1640: f32 = (tmp1686 * tmp1680);
	let tmp1668: f32 = (tmp1683 * tmp1680);
	let tmp1658: f32 = (tmp1683 * tmp1680);
	let tmp1673: f32 = (tmp1675 + tmp1674);
	let tmp1654: t_glsl_const_03 = c_glsl_const_03;
	let tmp952: vec3<f32> = (u_neo_elem_05_transform.v_sym);
	let tmp1645: f32 = (tmp1686 * tmp1683);
	let tmp1651: f32 = (tmp1653 + tmp1652);
	let tmp1662: f32 = (tmp1686 * tmp1680);
	let tmp1533: f32 = (u_neo_elem_03_transform.v_scale);
	let tmp2084: f32 = (tmp2075 - mix(((tmp2072.v_radius).y), ((tmp2072.v_radius).x), step(c_glsl_const_00.v_o, (tmp1708.y))));
	let tmp2015: f32 = (tmp2014.x);
	let tmp1636: f32 = (tmp1680 * tmp1677);
	let tmp1082: f32 = step(tmp1083.v_o, tmp1089);
	let tmp1072: f32 = step(tmp1073.v_o, tmp1079);
	let tmp1074: f32 = (tmp1075.y);
	let tmp1076: f32 = abs(tmp1077);
	let tmp2223: f32 = length(tmp2222);
	let tmp2076: vec2<f32> = (tmp2072.v_radius);
	let tmp1066: f32 = abs(tmp1067);
	let tmp1942: f32 = min(tmp1940, tmp1941.v_o);
	let tmp1064: f32 = (tmp1065.z);
	let tmp1945: f32 = (tmp1944 - tmp1927);
	let tmp1062: f32 = step(tmp1063.v_o, tmp1069);
	let tmp2220: t_glsl_const_00 = c_glsl_const_00;
	let tmp2219: f32 = max(tmp2216, tmp2218);
	let tmp2088: f32 = (tmp2073 + mix((tmp2076.y), (tmp2076.x), step(c_glsl_const_00.v_o, (tmp1708.y))));
	let tmp2210: f32 = mix(tmp2205, tmp2196, tmp2209);
	let tmp2086: t_glsl_const_00 = c_glsl_const_00;
	let tmp2149: vec3<f32> = tmp1708;
	let tmp1644: f32 = (tmp1646 - tmp1645);
	let tmp1642: t_glsl_const_03 = c_glsl_const_03;
	let tmp1534: vec3<f32> = (tmp1373);
	let tmp1532: vec3<f32> = vec3<f32>(tmp1533, tmp1533, tmp1533);
	let tmp2085: t_glsl_const_00 = c_glsl_const_00;
	let tmp1639: f32 = (tmp1641 - tmp1640);
	let tmp1637: t_glsl_const_03 = c_glsl_const_03;
	let tmp1634: f32 = (tmp1636 + tmp1635);
	let tmp2005: f32 = mix(tmp2002, tmp2000, tmp2004);
	let tmp1628: f32 = (tmp1632.v_o * tmp1629);
	let tmp2259: t_neo_elem_04_prim = u_neo_elem_04_prim;
	let tmp1661: f32 = (tmp1663 + tmp1662);
	let tmp2018: f32 = max(tmp2015, tmp2017);
	let tmp2019: t_glsl_const_00 = c_glsl_const_00;
	let tmp2022: f32 = length(tmp2021);
	let tmp953: vec3<f32> = ((tmp644));
	let tmp1627: t_glsl_const_04 = c_glsl_const_04;
	let tmp2090: f32 = (tmp2089 - tmp2084);
	let tmp1659: t_glsl_const_03 = c_glsl_const_03;
	let tmp1672: f32 = (tmp1676.v_o * tmp1673);
	let tmp1671: t_glsl_const_04 = c_glsl_const_04;
	let tmp1669: t_glsl_const_03 = c_glsl_const_03;
	let tmp1666: f32 = (tmp1668 - tmp1667);
	let tmp1656: f32 = (tmp1658 + tmp1657);
	let tmp1664: t_glsl_const_03 = c_glsl_const_03;
	let tmp2304: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))) - ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) - ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) - ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1085.x), abs(tmp1087), tmp1082), mix(tmp1074, tmp1076, tmp1072), mix(tmp1064, tmp1066, tmp1062))) - (u_neo_elem_04_transform.v_trans))) / vec3<f32>((u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))) - ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) - ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) - ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).y) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).x) / length((u_neo_elem_04_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).w) / length((u_neo_elem_04_transform.v_quat)))) + ((((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat))) * (((u_neo_elem_04_transform.v_quat).z) / length((u_neo_elem_04_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp1085.x), abs(tmp1087), tmp1082), mix(tmp1074, tmp1076, tmp1072), mix(tmp1064, tmp1066, tmp1062))) - (u_neo_elem_04_transform.v_trans))) / vec3<f32>((u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale))))).z);
	let tmp1086: f32 = abs(tmp1087);
	let tmp1649: t_glsl_const_04 = c_glsl_const_04;
	let tmp1650: f32 = (tmp1654.v_o * tmp1651);
	let tmp1084: f32 = (tmp1085.x);
	let tmp1647: t_glsl_const_03 = c_glsl_const_03;
	let tmp1071: f32 = mix(tmp1074, tmp1076, tmp1072);
	let tmp1592: vec4<f32> = (u_neo_elem_04_transform.v_quat);
	let tmp2074: f32 = (tmp2149.y);
	let tmp2289: vec2<f32> = abs((tmp2304));
	let tmp1946: f32 = (tmp1942 + tmp1945);
	let tmp2023: f32 = (tmp2022 - tmp2005);
	let tmp1660: f32 = (tmp1664.v_o * tmp1661);
	let tmp2275: vec2<f32> = (tmp2304);
	let tmp1626: f32 = (tmp1628 - tmp1627.v_o);
	let tmp2020: f32 = min(tmp2018, tmp2019.v_o);
	let tmp1648: f32 = (tmp1650 - tmp1649.v_o);
	let tmp1601: vec4<f32> = (u_neo_elem_04_transform.v_quat);
	let tmp2266: vec2<f32> = (tmp2304);
	let tmp1598: vec4<f32> = (u_neo_elem_04_transform.v_quat);
	let tmp2262: vec4<f32> = (tmp2259.v_radius);
	let tmp2091: vec2<f32> = vec2<f32>(tmp2088, tmp2090);
	let tmp1595: vec4<f32> = (u_neo_elem_04_transform.v_quat);
	let tmp1670: f32 = (tmp1672 - tmp1671.v_o);
	let tmp2260: vec2<f32> = (tmp2304);
	let tmp1638: f32 = (tmp1642.v_o * tmp1639);
	let tmp1531: vec3<f32> = (tmp1534 / tmp1532);
	let tmp2261: vec2<f32> = (tmp2259.v_dims);
	let tmp1655: f32 = (tmp1659.v_o * tmp1656);
	let tmp2224: f32 = (tmp2223 - tmp2210);
	let tmp1643: f32 = (tmp1647.v_o * tmp1644);
	let tmp1665: f32 = (tmp1669.v_o * tmp1666);
	let tmp2094: vec2<f32> = tmp2091;
	let tmp2079: vec2<f32> = tmp2076;
	let tmp1603: vec4<f32> = (u_neo_elem_04_transform.v_quat);
	let tmp2092: vec2<f32> = tmp2091;
	let tmp2087: vec2<f32> = vec2<f32>(tmp2085.v_o, tmp2086.v_o);
	let tmp1633: f32 = (tmp1637.v_o * tmp1634);
	let tmp2077: vec2<f32> = tmp2076;
	let tmp2221: f32 = min(tmp2219, tmp2220.v_o);
	let tmp1061: f32 = mix(tmp1064, tmp1066, tmp1062);
	let tmp1081: f32 = mix(tmp1084, tmp1086, tmp1082);
	let tmp2081: t_glsl_const_00 = c_glsl_const_00;
	let tmp1594: f32 = (tmp1595.y);
	let tmp2382: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp953.x), abs((tmp953.x)), step(c_glsl_const_00.v_o, (tmp952.x))), mix((tmp953.y), abs((tmp953.y)), step(c_glsl_const_00.v_o, (tmp952.y))), mix((tmp953.z), abs((tmp953.z)), step(c_glsl_const_00.v_o, (tmp952.z))))) - (u_neo_elem_05_transform.v_trans))) / vec3<f32>((u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp953.x), abs((tmp953.x)), step(c_glsl_const_00.v_o, (tmp952.x))), mix((tmp953.y), abs((tmp953.y)), step(c_glsl_const_00.v_o, (tmp952.y))), mix((tmp953.z), abs((tmp953.z)), step(c_glsl_const_00.v_o, (tmp952.z))))) - (u_neo_elem_05_transform.v_trans))) / vec3<f32>((u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale))))).z);
	let tmp2225: f32 = (tmp2221 + tmp2224);
	let tmp1600: f32 = (tmp1601.w);
	let tmp1602: f32 = length(tmp1603);
	let tmp2024: f32 = (tmp2020 + tmp2023);
	let tmp2099: vec2<f32> = max(tmp2091, tmp2087);
	let tmp2093: f32 = (tmp2092.x);
	let tmp2082: f32 = step(tmp2081.v_o, tmp2074);
	let tmp2263: t_glsl_const_00 = c_glsl_const_00;
	let tmp1597: f32 = (tmp1598.x);
	let tmp1591: f32 = (tmp1592.z);
	let tmp2078: f32 = (tmp2077.x);
	let tmp2277: vec4<f32> = tmp2262;
	let tmp2267: f32 = (tmp2266.x);
	let tmp2268: vec4<f32> = tmp2262;
	let tmp505: vec3<f32> = (((((((t_position(a_pos).v_pos)))))));
	let tmp2153: f32 = (u_neo_elem_03_mod.v_height);
	let tmp2279: vec4<f32> = tmp2262;
	let tmp2290: vec2<f32> = (tmp2289 - tmp2261);
	let tmp2270: vec4<f32> = tmp2262;
	let tmp1691: vec3<f32> = (tmp1531);
	let tmp1625: mat3x3<f32> = mat3x3<f32>(tmp1670, tmp1665, tmp1660, tmp1655, tmp1648, tmp1643, tmp1638, tmp1633, tmp1626);
	let tmp2291: vec2<f32> = vec2<f32>(mix(mix((tmp2279.w), (tmp2277.y), step(c_glsl_const_00.v_o, (tmp2275.x))), mix((tmp2270.z), (tmp2268.x), step(c_glsl_const_00.v_o, tmp2267)), step(c_glsl_const_00.v_o, (tmp2260.y))), mix(mix((tmp2279.w), (tmp2277.y), step(c_glsl_const_00.v_o, (tmp2275.x))), mix((tmp2270.z), (tmp2268.x), step(c_glsl_const_00.v_o, tmp2267)), step(c_glsl_const_00.v_o, (tmp2260.y))));
	let tmp2281: t_glsl_const_00 = c_glsl_const_00;
	let tmp2276: f32 = (tmp2275.x);
	let tmp2264: t_glsl_const_00 = c_glsl_const_00;
	let tmp1847: f32 = (tmp1946);
	let tmp2095: f32 = (tmp2094.y);
	let tmp2272: t_glsl_const_00 = c_glsl_const_00;
	let tmp2080: f32 = (tmp2079.y);
	let tmp2337: t_neo_elem_05_prim = u_neo_elem_05_prim;
	let tmp2284: vec2<f32> = tmp2260;
	let tmp1060: vec3<f32> = vec3<f32>(tmp1081, tmp1071, tmp1061);
	let tmp1451: vec4<f32> = (u_neo_elem_05_transform.v_quat);
	let tmp2338: vec2<f32> = (tmp2382);
	let tmp2167: f32 = abs(((tmp1625 * tmp1691).y));
	let tmp2340: vec4<f32> = (tmp2337.v_radius);
	let tmp2292: vec2<f32> = (tmp2290 + tmp2291);
	let tmp2083: f32 = mix(tmp2080, tmp2078, tmp2082);
	let tmp817: vec3<f32> = (u_neo_elem_06_transform.v_sym);
	let tmp1543: f32 = ((tmp1591 / tmp1602) * (tmp1591 / tmp1602));
	let tmp1544: f32 = ((tmp1600 / tmp1602) * (tmp1600 / tmp1602));
	let tmp1565: f32 = ((tmp1594 / tmp1602) * (tmp1594 / tmp1602));
	let tmp1566: f32 = ((tmp1600 / tmp1602) * (tmp1600 / tmp1602));
	let tmp1587: f32 = ((tmp1597 / tmp1602) * (tmp1597 / tmp1602));
	let tmp1588: f32 = ((tmp1600 / tmp1602) * (tmp1600 / tmp1602));
	let tmp1599: f32 = (tmp1600 / tmp1602);
	let tmp1701: f32 = (tmp1847);
	let tmp1700: f32 = (u_neo_elem_01_transform.v_scale);
	let tmp2096: f32 = max(tmp2093, tmp2095);
	let tmp2097: t_glsl_const_00 = c_glsl_const_00;
	let tmp2100: f32 = length(tmp2099);
	let tmp2367: vec2<f32> = abs(tmp2338);
	let tmp2353: vec2<f32> = tmp2338;
	let tmp2344: vec2<f32> = tmp2338;
	let tmp2339: vec2<f32> = (tmp2337.v_dims);
	let tmp1777: f32 = (tmp2024);
	let tmp2151: f32 = (tmp2225);
	let tmp2162: f32 = (tmp2153 - mix(((u_neo_elem_03_mod.v_radius).y), ((u_neo_elem_03_mod.v_radius).x), step(c_glsl_const_00.v_o, ((tmp1625 * tmp1691).y))));
	let tmp2295: vec2<f32> = tmp2292;
	let tmp2293: vec2<f32> = tmp2292;
	let tmp2286: t_glsl_const_00 = c_glsl_const_00;
	let tmp2285: f32 = (tmp2284.y);
	let tmp2282: f32 = step(tmp2281.v_o, tmp2276);
	let tmp2280: f32 = (tmp2279.w);
	let tmp2278: f32 = (tmp2277.y);
	let tmp2273: f32 = step(tmp2272.v_o, tmp2267);
	let tmp2271: f32 = (tmp2270.z);
	let tmp2269: f32 = (tmp2268.x);
	let tmp2265: vec2<f32> = vec2<f32>(tmp2263.v_o, tmp2264.v_o);
	let tmp1624: vec3<f32> = (tmp1625 * tmp1691);
	let tmp1236: vec3<f32> = (tmp1060);
	let tmp1235: vec3<f32> = (u_neo_elem_04_transform.v_trans);
	let tmp2150: t_neo_elem_03_mod = u_neo_elem_03_mod;
	let tmp1593: f32 = (tmp1594 / tmp1602);
	let tmp1596: f32 = (tmp1597 / tmp1602);
	let tmp1590: f32 = (tmp1591 / tmp1602);
	let tmp1440: vec4<f32> = tmp1451;
	let tmp1443: vec4<f32> = tmp1451;
	let tmp1446: vec4<f32> = tmp1451;
	let tmp013: t_neo_elem_00_transform = u_neo_elem_00_transform;
	let tmp1449: vec4<f32> = tmp1451;
	let tmp1575: f32 = (tmp1599 * tmp1593);
	let tmp1558: f32 = (tmp1599 * tmp1596);
	let tmp2359: t_glsl_const_00 = c_glsl_const_00;
	let tmp1571: f32 = (tmp1596 * tmp1593);
	let tmp2357: vec4<f32> = tmp2340;
	let tmp1570: f32 = (tmp1599 * tmp1590);
	let tmp2355: vec4<f32> = tmp2340;
	let tmp2354: f32 = (tmp2353.x);
	let tmp2098: f32 = min(tmp2096, tmp2097.v_o);
	let tmp2300: vec2<f32> = max(tmp2292, tmp2265);
	let tmp2166: f32 = (tmp2151 + mix(((tmp2150.v_radius).y), ((tmp2150.v_radius).x), step(c_glsl_const_00.v_o, (tmp1624.y))));
	let tmp2350: t_glsl_const_00 = c_glsl_const_00;
	let tmp2168: f32 = (tmp2167 - tmp2162);
	let tmp2348: vec4<f32> = tmp2340;
	let tmp2294: f32 = (tmp2293.x);
	let tmp2346: vec4<f32> = tmp2340;
	let tmp2345: f32 = (tmp2344.x);
	let tmp2101: f32 = (tmp2100 - tmp2083);
	let tmp1567: t_glsl_const_03 = c_glsl_const_03;
	let tmp2342: t_glsl_const_00 = c_glsl_const_00;
	let tmp2341: t_glsl_const_00 = c_glsl_const_00;
	let tmp2163: t_glsl_const_00 = c_glsl_const_00;
	let tmp1581: f32 = (tmp1596 * tmp1593);
	let tmp1580: f32 = (tmp1599 * tmp1590);
	let tmp1542: f32 = (tmp1544 + tmp1543);
	let tmp1553: f32 = (tmp1599 * tmp1593);
	let tmp2154: vec2<f32> = (tmp2150.v_radius);
	let tmp1576: f32 = (tmp1596 * tmp1590);
	let tmp1554: f32 = (tmp1596 * tmp1590);
	let tmp2296: f32 = (tmp2295.y);
	let tmp1559: f32 = (tmp1593 * tmp1590);
	let tmp1549: f32 = (tmp1593 * tmp1590);
	let tmp1548: f32 = (tmp1599 * tmp1596);
	let tmp2287: f32 = step(tmp2286.v_o, tmp2285);
	let tmp2362: vec2<f32> = tmp2338;
	let tmp2283: f32 = mix(tmp2280, tmp2278, tmp2282);
	let tmp2368: vec2<f32> = (tmp2367 - tmp2339);
	let tmp2369: vec2<f32> = vec2<f32>(mix(mix((tmp2357.w), (tmp2355.y), step(tmp2359.v_o, tmp2354)), mix((tmp2348.z), (tmp2346.x), step(tmp2350.v_o, tmp2345)), step(c_glsl_const_00.v_o, (tmp2362.y))), mix(mix((tmp2357.w), (tmp2355.y), step(tmp2359.v_o, tmp2354)), mix((tmp2348.z), (tmp2346.x), step(tmp2350.v_o, tmp2345)), step(c_glsl_const_00.v_o, (tmp2362.y))));
	let tmp2274: f32 = mix(tmp2271, tmp2269, tmp2273);
	let tmp1545: t_glsl_const_03 = c_glsl_const_03;
	let tmp1693: f32 = (tmp013.v_scale);
	let tmp1694: f32 = (tmp1777);
	let tmp1699: f32 = (tmp1701 * tmp1700);
	let tmp1381: f32 = (u_neo_elem_04_transform.v_scale);
	let tmp1445: f32 = (tmp1446.x);
	let tmp1564: f32 = (tmp1566 + tmp1565);
	let tmp2164: t_glsl_const_00 = c_glsl_const_00;
	let tmp2227: vec3<f32> = tmp1624;
	let tmp1439: f32 = (tmp1440.z);
	let tmp1442: f32 = (tmp1443.y);
	let tmp1448: f32 = (tmp1449.w);
	let tmp818: vec3<f32> = ((tmp505));
	let tmp1589: t_glsl_const_03 = c_glsl_const_03;
	let tmp1234: vec3<f32> = (tmp1236 - tmp1235);
	let tmp1586: f32 = (tmp1588 + tmp1587);
	let tmp1450: f32 = length(tmp1451);
	let tmp2297: f32 = max(tmp2294, tmp2296);
	let tmp2370: vec2<f32> = (tmp2368 + tmp2369);
	let tmp2159: t_glsl_const_00 = c_glsl_const_00;
	let tmp2165: vec2<f32> = vec2<f32>(tmp2163.v_o, tmp2164.v_o);
	let tmp1550: t_glsl_const_03 = c_glsl_const_03;
	let tmp2360: f32 = step(tmp2359.v_o, tmp2354);
	let tmp2358: f32 = (tmp2357.w);
	let tmp2356: f32 = (tmp2355.y);
	let tmp1582: t_glsl_const_03 = c_glsl_const_03;
	let tmp2363: f32 = (tmp2362.y);
	let tmp2155: vec2<f32> = tmp2154;
	let tmp2351: f32 = step(tmp2350.v_o, tmp2345);
	let tmp2364: t_glsl_const_00 = c_glsl_const_00;
	let tmp2349: f32 = (tmp2348.z);
	let tmp2343: vec2<f32> = vec2<f32>(tmp2341.v_o, tmp2342.v_o);
	let tmp1547: f32 = (tmp1549 + tmp1548);
	let tmp2371: vec2<f32> = tmp2370;
	let tmp1380: vec3<f32> = vec3<f32>(tmp1381, tmp1381, tmp1381);
	let tmp1447: f32 = (tmp1448 / tmp1450);
	let tmp2157: vec2<f32> = tmp2154;
	let tmp2102: f32 = (tmp2098 + tmp2101);
	let tmp1413: f32 = ((tmp1442 / tmp1450) * (tmp1442 / tmp1450));
	let tmp1579: f32 = (tmp1581 - tmp1580);
	let tmp2169: vec2<f32> = vec2<f32>(tmp2166, tmp2168);
	let tmp1692: f32 = (tmp1694 * tmp1693);
	let tmp1414: f32 = (tmp1447 * tmp1447);
	let tmp1392: f32 = (tmp1447 * tmp1447);
	let tmp1577: t_glsl_const_03 = c_glsl_const_03;
	let tmp2347: f32 = (tmp2346.x);
	let tmp012: t_neo_elem_01_transform = u_neo_elem_01_transform;
	let tmp1096: vec3<f32> = (u_neo_elem_05_transform.v_trans);
	let tmp1574: f32 = (tmp1576 + tmp1575);
	let tmp2172: vec2<f32> = tmp2169;
	let tmp1097: vec3<f32> = (vec3<f32>(mix((tmp953.x), abs((tmp953.x)), step(c_glsl_const_00.v_o, (tmp952.x))), mix((tmp953.y), abs((tmp953.y)), step(c_glsl_const_00.v_o, (tmp952.y))), mix((tmp953.z), abs((tmp953.z)), step(c_glsl_const_00.v_o, (tmp952.z)))));
	let tmp1572: t_glsl_const_03 = c_glsl_const_03;
	let tmp1611: f32 = (tmp1699);
	let tmp1569: f32 = (tmp1571 + tmp1570);
	let tmp1391: f32 = ((tmp1439 / tmp1450) * (tmp1439 / tmp1450));
	let tmp2298: t_glsl_const_00 = c_glsl_const_00;
	let tmp1441: f32 = (tmp1442 / tmp1450);
	let tmp1563: f32 = (tmp1567.v_o * tmp1564);
	let tmp1444: f32 = (tmp1445 / tmp1450);
	let tmp1435: f32 = (tmp1444 * tmp1444);
	let tmp1436: f32 = (tmp1447 * tmp1447);
	let tmp1562: t_glsl_const_04 = c_glsl_const_04;
	let tmp1382: vec3<f32> = (tmp1234);
	let tmp1540: t_glsl_const_04 = c_glsl_const_04;
	let tmp2152: f32 = (tmp2227.y);
	let tmp1438: f32 = (tmp1439 / tmp1450);
	let tmp1560: t_glsl_const_03 = c_glsl_const_03;
	let tmp2170: vec2<f32> = tmp2169;
	let tmp1557: f32 = (tmp1559 - tmp1558);
	let tmp1555: t_glsl_const_03 = c_glsl_const_03;
	let tmp2301: f32 = length(tmp2300);
	let tmp2373: vec2<f32> = tmp2370;
	let tmp1585: f32 = (tmp1589.v_o * tmp1586);
	let tmp1320: f32 = (((((tmp1692)))) - (opp(((tmp1611)))));
	let tmp1552: f32 = (tmp1554 - tmp1553);
	let tmp2288: f32 = mix(tmp2283, tmp2274, tmp2287);
	let tmp1584: t_glsl_const_04 = c_glsl_const_04;
	let tmp1541: f32 = (tmp1545.v_o * tmp1542);
	let tmp2352: f32 = mix(tmp2349, tmp2347, tmp2351);
	let tmp2177: vec2<f32> = max(tmp2169, tmp2165);
	let tmp2173: f32 = (tmp2172.y);
	let tmp2171: f32 = (tmp2170.x);
	let tmp1402: f32 = (tmp1444 * tmp1438);
	let tmp1401: f32 = (tmp1447 * tmp1441);
	let tmp1397: f32 = (tmp1441 * tmp1438);
	let tmp1568: f32 = (tmp1572.v_o * tmp1569);
	let tmp1393: t_glsl_const_03 = c_glsl_const_03;
	let tmp1390: f32 = (tmp1392 + tmp1391);
	let tmp1379: vec3<f32> = (tmp1382 / tmp1380);
	let tmp1539: f32 = (tmp1541 - tmp1540.v_o);
	let tmp1242: f32 = (u_neo_elem_05_transform.v_scale);
	let tmp1489: f32 = (tmp1611);
	let tmp1396: f32 = (tmp1447 * tmp1444);
	let tmp366: vec3<f32> = ((((((t_position(a_pos).v_pos))))));
	let tmp1331: f32 = (tmp012.v_blend);
	let tmp1321: f32 = abs(tmp1320);
	let tmp2374: f32 = (tmp2373.y);
	let tmp1437: t_glsl_const_03 = c_glsl_const_03;
	let tmp2372: f32 = (tmp2371.x);
	let tmp2361: f32 = mix(tmp2358, tmp2356, tmp2360);
	let tmp1434: f32 = (tmp1436 + tmp1435);
	let tmp1429: f32 = (tmp1444 * tmp1441);
	let tmp1428: f32 = (tmp1447 * tmp1438);
	let tmp1095: vec3<f32> = (tmp1097 - tmp1096);
	let tmp1424: f32 = (tmp1444 * tmp1438);
	let tmp1423: f32 = (tmp1447 * tmp1441);
	let tmp2302: f32 = (tmp2301 - tmp2288);
	let tmp2299: f32 = min(tmp2297, tmp2298.v_o);
	let tmp1419: f32 = (tmp1444 * tmp1441);
	let tmp1418: f32 = (tmp1447 * tmp1438);
	let tmp1415: t_glsl_const_03 = c_glsl_const_03;
	let tmp1412: f32 = (tmp1414 + tmp1413);
	let tmp1407: f32 = (tmp1441 * tmp1438);
	let tmp2365: f32 = step(tmp2364.v_o, tmp2363);
	let tmp2156: f32 = (tmp2155.x);
	let tmp2460: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))) - ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) - ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) - ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp818.x), abs((tmp818.x)), step(c_glsl_const_00.v_o, (tmp817.x))), mix((tmp818.y), abs((tmp818.y)), step(c_glsl_const_00.v_o, (tmp817.y))), mix((tmp818.z), abs((tmp818.z)), step(c_glsl_const_00.v_o, (tmp817.z))))) - (u_neo_elem_06_transform.v_trans))) / vec3<f32>((u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))) - ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) - ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) - ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).y) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).x) / length((u_neo_elem_06_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).w) / length((u_neo_elem_06_transform.v_quat)))) + ((((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat))) * (((u_neo_elem_06_transform.v_quat).z) / length((u_neo_elem_06_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp818.x), abs((tmp818.x)), step(c_glsl_const_00.v_o, (tmp817.x))), mix((tmp818.y), abs((tmp818.y)), step(c_glsl_const_00.v_o, (tmp817.y))), mix((tmp818.z), abs((tmp818.z)), step(c_glsl_const_00.v_o, (tmp817.z))))) - (u_neo_elem_06_transform.v_trans))) / vec3<f32>((u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale))))).z);
	let tmp2158: f32 = (tmp2157.y);
	let tmp2378: vec2<f32> = max(tmp2370, tmp2343);
	let tmp1707: f32 = (tmp2102);
	let tmp2160: f32 = step(tmp2159.v_o, tmp2152);
	let tmp1606: f32 = (tmp1692);
	let tmp2415: t_neo_elem_06_prim = u_neo_elem_06_prim;
	let tmp1406: f32 = (tmp1447 * tmp1444);
	let tmp1583: f32 = (tmp1585 - tmp1584.v_o);
	let tmp1578: f32 = (tmp1582.v_o * tmp1579);
	let tmp1573: f32 = (tmp1577.v_o * tmp1574);
	let tmp1561: f32 = (tmp1563 - tmp1562.v_o);
	let tmp1556: f32 = (tmp1560.v_o * tmp1557);
	let tmp1551: f32 = (tmp1555.v_o * tmp1552);
	let tmp1546: f32 = (tmp1550.v_o * tmp1547);
	let tmp2366: f32 = mix(tmp2361, tmp2352, tmp2365);
	let tmp1420: t_glsl_const_03 = c_glsl_const_03;
	let tmp1454: f32 = (tmp1606);
	let tmp1301: vec4<f32> = (u_neo_elem_06_transform.v_quat);
	let tmp1422: f32 = (tmp1424 + tmp1423);
	let tmp2178: f32 = length(tmp2177);
	let tmp2431: vec2<f32> = (tmp2460);
	let tmp1241: vec3<f32> = vec3<f32>(tmp1242, tmp1242, tmp1242);
	let tmp1332: f32 = (tmp1489);
	let tmp2175: t_glsl_const_00 = c_glsl_const_00;
	let tmp1318: t_glsl_const_01 = c_glsl_const_01;
	let tmp2231: f32 = (u_neo_elem_04_mod.v_height);
	let tmp1316: f32 = (tmp1331);
	let tmp2174: f32 = max(tmp2171, tmp2173);
	let tmp1616: f32 = (u_neo_elem_02_transform.v_scale);
	let tmp1310: vec4<f32> = (u_neo_elem_06_transform.v_quat);
	let tmp1389: f32 = (tmp1393.v_o * tmp1390);
	let tmp1323: t_glsl_const_00 = c_glsl_const_00;
	let tmp1604: vec3<f32> = (tmp1379);
	let tmp1425: t_glsl_const_03 = c_glsl_const_03;
	let tmp2445: vec2<f32> = abs((tmp2460));
	let tmp2416: vec2<f32> = (tmp2460);
	let tmp1405: f32 = (tmp1407 - tmp1406);
	let tmp1307: vec4<f32> = (u_neo_elem_06_transform.v_quat);
	let tmp2375: f32 = max(tmp2372, tmp2374);
	let tmp2303: f32 = (tmp2299 + tmp2302);
	let tmp1617: f32 = (tmp1707);
	let tmp1430: t_glsl_const_03 = c_glsl_const_03;
	let tmp2422: vec2<f32> = tmp2416;
	let tmp1243: vec3<f32> = (tmp1095);
	let tmp1432: t_glsl_const_04 = c_glsl_const_04;
	let tmp1304: vec4<f32> = (u_neo_elem_06_transform.v_quat);
	let tmp2418: vec4<f32> = (tmp2415.v_radius);
	let tmp1427: f32 = (tmp1429 - tmp1428);
	let tmp1433: f32 = (tmp1437.v_o * tmp1434);
	let tmp1395: f32 = (tmp1397 + tmp1396);
	let tmp2161: f32 = mix(tmp2158, tmp2156, tmp2160);
	let tmp1403: t_glsl_const_03 = c_glsl_const_03;
	let tmp1388: t_glsl_const_04 = c_glsl_const_04;
	let tmp1312: vec4<f32> = (u_neo_elem_06_transform.v_quat);
	let tmp1322: f32 = (max(tmp1316, tmp1318.v_o) - tmp1321);
	let tmp1400: f32 = (tmp1402 - tmp1401);
	let tmp1398: t_glsl_const_03 = c_glsl_const_03;
	let tmp1538: mat3x3<f32> = mat3x3<f32>(tmp1583, tmp1578, tmp1573, tmp1568, tmp1561, tmp1556, tmp1551, tmp1546, tmp1539);
	let tmp2376: t_glsl_const_00 = c_glsl_const_00;
	let tmp1417: f32 = (tmp1419 + tmp1418);
	let tmp2379: f32 = length(tmp2378);
	let tmp678: vec3<f32> = (u_neo_elem_07_transform.v_sym);
	let tmp1411: f32 = (tmp1415.v_o * tmp1412);
	let tmp1410: t_glsl_const_04 = c_glsl_const_04;
	let tmp1408: t_glsl_const_03 = c_glsl_const_03;
	let tmp2417: vec2<f32> = (tmp2415.v_dims);
	let tmp2447: vec2<f32> = vec2<f32>(mix(mix((tmp2418.w), (tmp2418.y), step(c_glsl_const_00.v_o, (tmp2431.x))), mix((tmp2418.z), (tmp2418.x), step(c_glsl_const_00.v_o, (tmp2422.x))), step(c_glsl_const_00.v_o, (tmp2416.y))), mix(mix((tmp2418.w), (tmp2418.y), step(c_glsl_const_00.v_o, (tmp2431.x))), mix((tmp2418.z), (tmp2418.x), step(c_glsl_const_00.v_o, (tmp2422.x))), step(c_glsl_const_00.v_o, (tmp2416.y))));
	let tmp1306: f32 = (tmp1307.x);
	let tmp1399: f32 = (tmp1403.v_o * tmp1400);
	let tmp2179: f32 = (tmp2178 - tmp2161);
	let tmp1319: f32 = max(tmp1316, tmp1318.v_o);
	let tmp1324: f32 = max(tmp1322, tmp1323.v_o);
	let tmp1303: f32 = (tmp1304.y);
	let tmp2229: f32 = (tmp2303);
	let tmp1394: f32 = (tmp1398.v_o * tmp1395);
	let tmp1311: f32 = length(tmp1312);
	let tmp1300: f32 = (tmp1301.z);
	let tmp2176: f32 = min(tmp2174, tmp2175.v_o);
	let tmp1333: f32 = (tmp1454);
	let tmp1387: f32 = (tmp1389 - tmp1388.v_o);
	let tmp1330: f32 = opp(tmp1332);
	let tmp1326: t_glsl_const_02 = c_glsl_const_02;
	let tmp2245: f32 = abs(((tmp1538 * tmp1604).y));
	let tmp679: vec3<f32> = ((tmp366));
	let tmp1240: vec3<f32> = (tmp1243 / tmp1241);
	let tmp2240: f32 = (tmp2231 - mix(((u_neo_elem_04_mod.v_radius).y), ((u_neo_elem_04_mod.v_radius).x), step(c_glsl_const_00.v_o, ((tmp1538 * tmp1604).y))));
	let tmp1431: f32 = (tmp1433 - tmp1432.v_o);
	let tmp2228: t_neo_elem_04_mod = u_neo_elem_04_mod;
	let tmp1404: f32 = (tmp1408.v_o * tmp1405);
	let tmp1426: f32 = (tmp1430.v_o * tmp1427);
	let tmp1615: f32 = (tmp1617 * tmp1616);
	let tmp1421: f32 = (tmp1425.v_o * tmp1422);
	let tmp2426: vec4<f32> = tmp2418;
	let tmp2419: t_glsl_const_00 = c_glsl_const_00;
	let tmp2428: t_glsl_const_00 = c_glsl_const_00;
	let tmp2432: f32 = (tmp2431.x);
	let tmp1416: f32 = (tmp1420.v_o * tmp1417);
	let tmp1537: vec3<f32> = (tmp1538 * tmp1604);
	let tmp2377: f32 = min(tmp2375, tmp2376.v_o);
	let tmp2433: vec4<f32> = tmp2418;
	let tmp2435: vec4<f32> = tmp2418;
	let tmp2420: t_glsl_const_00 = c_glsl_const_00;
	let tmp2440: vec2<f32> = tmp2416;
	let tmp1409: f32 = (tmp1411 - tmp1410.v_o);
	let tmp1309: f32 = (tmp1310.w);
	let tmp2437: t_glsl_const_00 = c_glsl_const_00;
	let tmp2380: f32 = (tmp2379 - tmp2366);
	let tmp2446: vec2<f32> = (tmp2445 - tmp2417);
	let tmp2424: vec4<f32> = tmp2418;
	let tmp2423: f32 = (tmp2422.x);
	let tmp2449: vec2<f32> = (tmp2446 + tmp2447);
	let tmp1302: f32 = (tmp1303 / tmp1311);
	let tmp2309: f32 = (u_neo_elem_05_mod.v_height);
	let tmp1299: f32 = (tmp1300 / tmp1311);
	let tmp011: t_neo_elem_02_transform = u_neo_elem_02_transform;
	let tmp1252: f32 = (tmp1299 * tmp1299);
	let tmp2442: t_glsl_const_00 = c_glsl_const_00;
	let tmp2441: f32 = (tmp2440.y);
	let tmp2438: f32 = step(tmp2437.v_o, tmp2432);
	let tmp1181: f32 = ((((max((tmp1333), (tmp1330)) + ((tmp1324 * tmp1324) * (tmp1326.v_o / tmp1319))))) - (opp((((tmp1615))))));
	let tmp1297: f32 = ((tmp1309 / tmp1311) * (tmp1309 / tmp1311));
	let tmp2436: f32 = (tmp2435.w);
	let tmp2434: f32 = (tmp2433.y);
	let tmp1305: f32 = (tmp1306 / tmp1311);
	let tmp1296: f32 = (tmp1305 * tmp1305);
	let tmp2429: f32 = step(tmp2428.v_o, tmp2423);
	let tmp2232: vec2<f32> = (tmp2228.v_radius);
	let tmp2427: f32 = (tmp2426.z);
	let tmp1325: f32 = (tmp1324 * tmp1324);
	let tmp1275: f32 = ((tmp1309 / tmp1311) * (tmp1309 / tmp1311));
	let tmp2241: t_glsl_const_00 = c_glsl_const_00;
	let tmp2305: vec3<f32> = tmp1537;
	let tmp1452: vec3<f32> = (tmp1240);
	let tmp2242: t_glsl_const_00 = c_glsl_const_00;
	let tmp2244: f32 = (tmp2229 + mix((tmp2232.y), (tmp2232.x), step(c_glsl_const_00.v_o, (tmp2305.y))));
	let tmp1386: mat3x3<f32> = mat3x3<f32>(tmp1431, tmp1426, tmp1421, tmp1416, tmp1409, tmp1404, tmp1399, tmp1394, tmp1387);
	let tmp2246: f32 = (tmp2245 - tmp2240);
	let tmp1308: f32 = (tmp1309 / tmp1311);
	let tmp2180: f32 = (tmp2176 + tmp2179);
	let tmp1315: f32 = (tmp1330);
	let tmp2448: vec2<f32> = (tmp2446 + tmp2447);
	let tmp1524: f32 = (tmp1615);
	let tmp1314: f32 = (tmp1333);
	let tmp2451: vec2<f32> = tmp2448;
	let tmp1274: f32 = (tmp1302 * tmp1302);
	let tmp2381: f32 = (tmp2377 + tmp2380);
	let tmp2421: vec2<f32> = vec2<f32>(tmp2419.v_o, tmp2420.v_o);
	let tmp2425: f32 = (tmp2424.x);
	let tmp1327: f32 = (tmp1326.v_o / tmp1319);
	let tmp1253: f32 = (tmp1308 * tmp1308);
	let tmp1258: f32 = (tmp1302 * tmp1299);
	let tmp1257: f32 = (tmp1308 * tmp1305);
	let tmp1268: f32 = (tmp1302 * tmp1299);
	let tmp1254: t_glsl_const_03 = c_glsl_const_03;
	let tmp2318: f32 = (tmp2309 - mix(((u_neo_elem_05_mod.v_radius).y), ((u_neo_elem_05_mod.v_radius).x), step(c_glsl_const_00.v_o, ((tmp1386 * tmp1452).y))));
	let tmp2307: f32 = (tmp2381);
	let tmp1251: f32 = (tmp1253 + tmp1252);
	let tmp1192: f32 = (tmp011.v_blend);
	let tmp1182: f32 = abs(tmp1181);
	let tmp2450: f32 = (tmp2449.x);
	let tmp2452: f32 = (tmp2451.y);
	let tmp2538: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))) - ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) - ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) - ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp679.x), abs((tmp679.x)), step(c_glsl_const_00.v_o, (tmp678.x))), mix((tmp679.y), abs((tmp679.y)), step(c_glsl_const_00.v_o, (tmp678.y))), mix((tmp679.z), abs((tmp679.z)), step(c_glsl_const_00.v_o, (tmp678.z))))) - (u_neo_elem_07_transform.v_trans))) / vec3<f32>((u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))) - ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) - ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) - ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).y) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).x) / length((u_neo_elem_07_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).w) / length((u_neo_elem_07_transform.v_quat)))) + ((((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat))) * (((u_neo_elem_07_transform.v_quat).z) / length((u_neo_elem_07_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp679.x), abs((tmp679.x)), step(c_glsl_const_00.v_o, (tmp678.x))), mix((tmp679.y), abs((tmp679.y)), step(c_glsl_const_00.v_o, (tmp678.y))), mix((tmp679.z), abs((tmp679.z)), step(c_glsl_const_00.v_o, (tmp678.z))))) - (u_neo_elem_07_transform.v_trans))) / vec3<f32>((u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale))))).z);
	let tmp2443: f32 = step(tmp2442.v_o, tmp2441);
	let tmp2247: vec2<f32> = vec2<f32>(tmp2244, tmp2246);
	let tmp1385: vec3<f32> = (tmp1386 * tmp1452);
	let tmp2235: vec2<f32> = tmp2232;
	let tmp2237: t_glsl_const_00 = c_glsl_const_00;
	let tmp2230: f32 = (tmp2305.y);
	let tmp2493: t_neo_elem_07_prim = u_neo_elem_07_prim;
	let tmp1276: t_glsl_const_03 = c_glsl_const_03;
	let tmp1623: f32 = (tmp2180);
	let tmp1337: f32 = (tmp1524);
	let tmp1328: f32 = (tmp1325 * tmp1327);
	let tmp2250: vec2<f32> = tmp2247;
	let tmp1317: f32 = max(tmp1314, tmp1315);
	let tmp2243: vec2<f32> = vec2<f32>(tmp2241.v_o, tmp2242.v_o);
	let tmp1298: t_glsl_const_03 = c_glsl_const_03;
	let tmp1295: f32 = (tmp1297 + tmp1296);
	let tmp1290: f32 = (tmp1305 * tmp1302);
	let tmp1285: f32 = (tmp1305 * tmp1299);
	let tmp1284: f32 = (tmp1308 * tmp1302);
	let tmp2248: vec2<f32> = tmp2247;
	let tmp2306: t_neo_elem_05_mod = u_neo_elem_05_mod;
	let tmp1280: f32 = (tmp1305 * tmp1302);
	let tmp1279: f32 = (tmp1308 * tmp1299);
	let tmp2233: vec2<f32> = tmp2232;
	let tmp2430: f32 = mix(tmp2427, tmp2425, tmp2429);
	let tmp2323: f32 = abs((tmp1385.y));
	let tmp1273: f32 = (tmp1275 + tmp1274);
	let tmp2456: vec2<f32> = max(tmp2448, tmp2421);
	let tmp2439: f32 = mix(tmp2436, tmp2434, tmp2438);
	let tmp1103: f32 = (u_neo_elem_06_transform.v_scale);
	let tmp1267: f32 = (tmp1308 * tmp1305);
	let tmp1263: f32 = (tmp1305 * tmp1299);
	let tmp1262: f32 = (tmp1308 * tmp1302);
	let tmp1289: f32 = (tmp1308 * tmp1299);
	let tmp1266: f32 = (tmp1268 - tmp1267);
	let tmp1264: t_glsl_const_03 = c_glsl_const_03;
	let tmp2324: f32 = (tmp2323 - tmp2318);
	let tmp2322: f32 = (tmp2307 + mix(((tmp2306.v_radius).y), ((tmp2306.v_radius).x), step(c_glsl_const_00.v_o, (tmp1385.y))));
	let tmp1261: f32 = (tmp1263 - tmp1262);
	let tmp1259: t_glsl_const_03 = c_glsl_const_03;
	let tmp2320: t_glsl_const_00 = c_glsl_const_00;
	let tmp1193: f32 = (tmp1337);
	let tmp2319: t_glsl_const_00 = c_glsl_const_00;
	let tmp1184: t_glsl_const_00 = c_glsl_const_00;
	let tmp1183: f32 = (max((tmp1192), c_glsl_const_01.v_o) - tmp1182);
	let tmp1256: f32 = (tmp1258 + tmp1257);
	let tmp2255: vec2<f32> = max(tmp2247, tmp2243);
	let tmp1179: t_glsl_const_01 = c_glsl_const_01;
	let tmp1177: f32 = (tmp1192);
	let tmp2251: f32 = (tmp2250.y);
	let tmp1171: vec4<f32> = (u_neo_elem_07_transform.v_quat);
	let tmp1168: vec4<f32> = (u_neo_elem_07_transform.v_quat);
	let tmp1165: vec4<f32> = (u_neo_elem_07_transform.v_quat);
	let tmp1162: vec4<f32> = (u_neo_elem_07_transform.v_quat);
	let tmp1104: vec3<f32> = (((vec3<f32>(mix((tmp818.x), abs((tmp818.x)), step(c_glsl_const_00.v_o, (tmp817.x))), mix((tmp818.y), abs((tmp818.y)), step(c_glsl_const_00.v_o, (tmp817.y))), mix((tmp818.z), abs((tmp818.z)), step(c_glsl_const_00.v_o, (tmp817.z))))) - (u_neo_elem_06_transform.v_trans)));
	let tmp1102: vec3<f32> = vec3<f32>(tmp1103, tmp1103, tmp1103);
	let tmp2249: f32 = (tmp2248.x);
	let tmp2238: f32 = step(tmp2237.v_o, tmp2230);
	let tmp1250: f32 = (tmp1254.v_o * tmp1251);
	let tmp1249: t_glsl_const_04 = c_glsl_const_04;
	let tmp2236: f32 = (tmp2235.y);
	let tmp2234: f32 = (tmp2233.x);
	let tmp1293: t_glsl_const_04 = c_glsl_const_04;
	let tmp1530: f32 = (tmp1623);
	let tmp1529: f32 = (u_neo_elem_03_transform.v_scale);
	let tmp1173: vec4<f32> = (u_neo_elem_07_transform.v_quat);
	let tmp2496: vec4<f32> = (tmp2493.v_radius);
	let tmp2494: vec2<f32> = (tmp2538);
	let tmp2383: vec3<f32> = tmp1385;
	let tmp1294: f32 = (tmp1298.v_o * tmp1295);
	let tmp1291: t_glsl_const_03 = c_glsl_const_03;
	let tmp2444: f32 = mix(tmp2439, tmp2430, tmp2443);
	let tmp2310: vec2<f32> = (tmp2306.v_radius);
	let tmp1288: f32 = (tmp1290 - tmp1289);
	let tmp1286: t_glsl_const_03 = c_glsl_const_03;
	let tmp231: vec3<f32> = (((((t_position(a_pos).v_pos)))));
	let tmp2701: vec2<f32> = vec2<f32>(cos((u_neo_elem_09_prim.v_angle)), sin((u_neo_elem_09_prim.v_angle)));
	let tmp1283: f32 = (tmp1285 + tmp1284);
	let tmp1281: t_glsl_const_03 = c_glsl_const_03;
	let tmp2523: vec2<f32> = abs(tmp2494);
	let tmp1329: f32 = (tmp1317 + tmp1328);
	let tmp1278: f32 = (tmp1280 + tmp1279);
	let tmp2509: vec2<f32> = tmp2494;
	let tmp2500: vec2<f32> = tmp2494;
	let tmp2495: vec2<f32> = (tmp2493.v_dims);
	let tmp2457: f32 = length(tmp2456);
	let tmp1272: f32 = (tmp1276.v_o * tmp1273);
	let tmp1271: t_glsl_const_04 = c_glsl_const_04;
	let tmp1269: t_glsl_const_03 = c_glsl_const_03;
	let tmp2454: t_glsl_const_00 = c_glsl_const_00;
	let tmp2453: f32 = max(tmp2450, tmp2452);
	let tmp2256: f32 = length(tmp2255);
	let tmp2515: t_glsl_const_00 = c_glsl_const_00;
	let tmp1191: f32 = opp(tmp1193);
	let tmp1167: f32 = (tmp1168.x);
	let tmp2501: f32 = (tmp2500.x);
	let tmp2502: vec4<f32> = tmp2496;
	let tmp1187: t_glsl_const_02 = c_glsl_const_02;
	let tmp2504: vec4<f32> = tmp2496;
	let tmp2513: vec4<f32> = tmp2496;
	let tmp1270: f32 = (tmp1272 - tmp1271.v_o);
	let tmp2328: vec2<f32> = vec2<f32>(tmp2322, tmp2324);
	let tmp2525: vec2<f32> = vec2<f32>(mix(mix((tmp2513.w), (tmp2496.y), step(tmp2515.v_o, (tmp2509.x))), mix((tmp2504.z), (tmp2502.x), step(c_glsl_const_00.v_o, tmp2501)), step(c_glsl_const_00.v_o, (tmp2494.y))), mix(mix((tmp2513.w), (tmp2496.y), step(tmp2515.v_o, (tmp2509.x))), mix((tmp2504.z), (tmp2502.x), step(c_glsl_const_00.v_o, tmp2501)), step(c_glsl_const_00.v_o, (tmp2494.y))));
	let tmp1170: f32 = (tmp1171.w);
	let tmp1292: f32 = (tmp1294 - tmp1293.v_o);
	let tmp2239: f32 = mix(tmp2236, tmp2234, tmp2238);
	let tmp2325: vec2<f32> = vec2<f32>(tmp2322, tmp2324);
	let tmp1277: f32 = (tmp1281.v_o * tmp1278);
	let tmp2511: vec4<f32> = tmp2496;
	let tmp1528: f32 = (tmp1530 * tmp1529);
	let tmp1180: f32 = max(tmp1177, tmp1179.v_o);
	let tmp1185: f32 = max(tmp1183, tmp1184.v_o);
	let tmp2253: t_glsl_const_00 = c_glsl_const_00;
	let tmp2510: f32 = (tmp2509.x);
	let tmp2524: vec2<f32> = (tmp2523 - tmp2495);
	let tmp2252: f32 = max(tmp2249, tmp2251);
	let tmp539: vec3<f32> = (u_neo_elem_08_transform.v_sym);
	let tmp1282: f32 = (tmp1286.v_o * tmp1283);
	let tmp1248: f32 = (tmp1250 - tmp1249.v_o);
	let tmp2518: vec2<f32> = tmp2494;
	let tmp1255: f32 = (tmp1259.v_o * tmp1256);
	let tmp1260: f32 = (tmp1264.v_o * tmp1261);
	let tmp2702: f32 = (tmp2701.y);
	let tmp2506: t_glsl_const_00 = c_glsl_const_00;
	let tmp2704: vec2<f32> = vec2<f32>(cos((u_neo_elem_09_prim.v_angle)), sin((u_neo_elem_09_prim.v_angle)));
	let tmp2455: f32 = min(tmp2453, tmp2454.v_o);
	let tmp1172: f32 = length(tmp1173);
	let tmp2326: vec2<f32> = tmp2325;
	let tmp2321: vec2<f32> = vec2<f32>(tmp2319.v_o, tmp2320.v_o);
	let tmp2458: f32 = (tmp2457 - tmp2444);
	let tmp2308: f32 = (tmp2383.y);
	let tmp1287: f32 = (tmp1291.v_o * tmp1288);
	let tmp2497: t_glsl_const_00 = c_glsl_const_00;
	let tmp1161: f32 = (tmp1162.z);
	let tmp2315: t_glsl_const_00 = c_glsl_const_00;
	let tmp1194: f32 = (tmp1329);
	let tmp2498: t_glsl_const_00 = c_glsl_const_00;
	let tmp1265: f32 = (tmp1269.v_o * tmp1266);
	let tmp2313: vec2<f32> = tmp2310;
	let tmp1101: vec3<f32> = (tmp1104 / tmp1102);
	let tmp2311: vec2<f32> = tmp2310;
	let tmp1164: f32 = (tmp1165.y);
	let tmp1136: f32 = ((tmp1170 / tmp1172) * (tmp1170 / tmp1172));
	let tmp2507: f32 = step(tmp2506.v_o, tmp2501);
	let tmp2329: f32 = (tmp2328.y);
	let tmp2505: f32 = (tmp2504.z);
	let tmp2312: f32 = (tmp2311.x);
	let tmp2529: vec2<f32> = (tmp2524 + tmp2525);
	let tmp2257: f32 = (tmp2256 - tmp2239);
	let tmp2527: vec2<f32> = (tmp2524 + tmp2525);
	let tmp1175: f32 = (tmp1194);
	let tmp1176: f32 = (tmp1191);
	let tmp2503: f32 = (tmp2502.x);
	let tmp2327: f32 = (tmp2326.x);
	let tmp1135: f32 = ((tmp1164 / tmp1172) * (tmp1164 / tmp1172));
	let tmp2520: t_glsl_const_00 = c_glsl_const_00;
	let tmp2519: f32 = (tmp2518.y);
	let tmp1157: f32 = ((tmp1167 / tmp1172) * (tmp1167 / tmp1172));
	let tmp1158: f32 = ((tmp1170 / tmp1172) * (tmp1170 / tmp1172));
	let tmp2703: f32 = opp(tmp2702);
	let tmp2705: f32 = (tmp2704.x);
	let tmp2516: f32 = step(tmp2515.v_o, tmp2510);
	let tmp2316: f32 = step(tmp2315.v_o, tmp2308);
	let tmp1042: f32 = ((((max(tmp1175, tmp1176) + ((tmp1185 * tmp1185) * (tmp1187.v_o / tmp1180))))) - (opp((((tmp1528))))));
	let tmp1186: f32 = (tmp1185 * tmp1185);
	let tmp2314: f32 = (tmp2313.y);
	let tmp2512: f32 = (tmp2511.y);
	let tmp2333: vec2<f32> = max(tmp2325, tmp2321);
	let tmp1247: mat3x3<f32> = mat3x3<f32>(tmp1292, tmp1287, tmp1282, tmp1277, tmp1270, tmp1265, tmp1260, tmp1255, tmp1248);
	let tmp1113: f32 = ((tmp1161 / tmp1172) * (tmp1161 / tmp1172));
	let tmp2526: vec2<f32> = (tmp2524 + tmp2525);
	let tmp010: t_neo_elem_03_transform = u_neo_elem_03_transform;
	let tmp2387: f32 = (u_neo_elem_06_mod.v_height);
	let tmp2499: vec2<f32> = vec2<f32>(tmp2497.v_o, tmp2498.v_o);
	let tmp1114: f32 = ((tmp1170 / tmp1172) * (tmp1170 / tmp1172));
	let tmp1372: f32 = (tmp1528);
	let tmp1160: f32 = (tmp1161 / tmp1172);
	let tmp2514: f32 = (tmp2513.w);
	let tmp1166: f32 = (tmp1167 / tmp1172);
	let tmp2459: f32 = (tmp2455 + tmp2458);
	let tmp2254: f32 = min(tmp2252, tmp2253.v_o);
	let tmp540: vec3<f32> = ((tmp231));
	let tmp1313: vec3<f32> = (tmp1101);
	let tmp1188: f32 = (tmp1187.v_o / tmp1180);
	let tmp1169: f32 = (tmp1170 / tmp1172);
	let tmp1163: f32 = (tmp1164 / tmp1172);
	let tmp1198: f32 = (tmp1372);
	let tmp2330: f32 = max(tmp2327, tmp2329);
	let tmp2331: t_glsl_const_00 = c_glsl_const_00;
	let tmp2508: f32 = mix(tmp2505, tmp2503, tmp2507);
	let tmp2334: f32 = length(tmp2333);
	let tmp166: vec3<f32> = ((((t_position(a_pos).v_pos))));
	let tmp2385: f32 = (tmp2459);
	let tmp2534: vec2<f32> = max(tmp2526, tmp2499);
	let tmp2530: f32 = (tmp2529.y);
	let tmp2528: f32 = (tmp2527.x);
	let tmp2521: f32 = step(tmp2520.v_o, tmp2519);
	let tmp2517: f32 = mix(tmp2514, tmp2512, tmp2516);
	let tmp2700: vec2<f32> = (vec2<f32>(abs(((vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp166)).x), abs((((tmp166)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).x))), mix((((tmp166)).y), abs((((tmp166)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).y))), mix((((tmp166)).z), abs((((tmp166)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp166)).x), abs((((tmp166)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).x))), mix((((tmp166)).y), abs((((tmp166)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).y))), mix((((tmp166)).z), abs((((tmp166)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).z)).x)), ((vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp166)).x), abs((((tmp166)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).x))), mix((((tmp166)).y), abs((((tmp166)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).y))), mix((((tmp166)).z), abs((((tmp166)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp166)).x), abs((((tmp166)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).x))), mix((((tmp166)).y), abs((((tmp166)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).y))), mix((((tmp166)).z), abs((((tmp166)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_09_transform.v_sym).z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).z)).y)) - vec2<f32>((u_neo_elem_09_prim.v_wi), (u_neo_elem_09_prim.v_r)));
	let tmp964: f32 = (u_neo_elem_07_transform.v_scale);
	let tmp2706: vec2<f32> = vec2<f32>(tmp2703, tmp2705);
	let tmp1043: f32 = abs(tmp1042);
	let tmp1053: f32 = (tmp010.v_blend);
	let tmp1112: f32 = (tmp1114 + tmp1113);
	let tmp1134: f32 = (tmp1136 + tmp1135);
	let tmp1115: t_glsl_const_03 = c_glsl_const_03;
	let tmp2396: f32 = (tmp2387 - mix(((u_neo_elem_06_mod.v_radius).y), ((u_neo_elem_06_mod.v_radius).x), step(c_glsl_const_00.v_o, ((tmp1247 * tmp1313).y))));
	let tmp1246: vec3<f32> = (tmp1247 * tmp1313);
	let tmp1145: f32 = (tmp1169 * tmp1163);
	let tmp1146: f32 = (tmp1166 * tmp1160);
	let tmp2317: f32 = mix(tmp2314, tmp2312, tmp2316);
	let tmp1150: f32 = (tmp1169 * tmp1160);
	let tmp2384: t_neo_elem_06_mod = u_neo_elem_06_mod;
	let tmp1151: f32 = (tmp1166 * tmp1163);
	let tmp1156: f32 = (tmp1158 + tmp1157);
	let tmp1159: t_glsl_const_03 = c_glsl_const_03;
	let tmp1118: f32 = (tmp1169 * tmp1166);
	let tmp1119: f32 = (tmp1163 * tmp1160);
	let tmp1123: f32 = (tmp1169 * tmp1163);
	let tmp1124: f32 = (tmp1166 * tmp1160);
	let tmp1178: f32 = max(tmp1175, tmp1176);
	let tmp1128: f32 = (tmp1169 * tmp1166);
	let tmp1129: f32 = (tmp1163 * tmp1160);
	let tmp1137: t_glsl_const_03 = c_glsl_const_03;
	let tmp1140: f32 = (tmp1169 * tmp1160);
	let tmp1141: f32 = (tmp1166 * tmp1163);
	let tmp1189: f32 = (tmp1186 * tmp1188);
	let tmp2258: f32 = (tmp2254 + tmp2257);
	let tmp2401: f32 = abs((tmp1246.y));
	let tmp1122: f32 = (tmp1124 - tmp1123);
	let tmp1190: f32 = (tmp1178 + tmp1189);
	let tmp1144: f32 = (tmp1146 + tmp1145);
	let tmp1111: f32 = (tmp1115.v_o * tmp1112);
	let tmp1130: t_glsl_const_03 = c_glsl_const_03;
	let tmp1110: t_glsl_const_04 = c_glsl_const_04;
	let tmp2616: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp540.x), abs((tmp540.x)), step(c_glsl_const_00.v_o, (tmp539.x))), mix((tmp540.y), abs((tmp540.y)), step(c_glsl_const_00.v_o, (tmp539.y))), mix((tmp540.z), abs((tmp540.z)), step(c_glsl_const_00.v_o, (tmp539.z))))) - (u_neo_elem_08_transform.v_trans))) / vec3<f32>((u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp540.x), abs((tmp540.x)), step(c_glsl_const_00.v_o, (tmp539.x))), mix((tmp540.y), abs((tmp540.y)), step(c_glsl_const_00.v_o, (tmp539.y))), mix((tmp540.z), abs((tmp540.z)), step(c_glsl_const_00.v_o, (tmp539.z))))) - (u_neo_elem_08_transform.v_trans))) / vec3<f32>((u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale))))).z);
	let tmp1536: f32 = (tmp2258);
	let tmp1054: f32 = (tmp1198);
	let tmp1045: t_glsl_const_00 = c_glsl_const_00;
	let tmp400: vec3<f32> = (u_neo_elem_09_transform.v_sym);
	let tmp1044: f32 = (max((tmp1053), c_glsl_const_01.v_o) - tmp1043);
	let tmp1120: t_glsl_const_03 = c_glsl_const_03;
	let tmp1040: t_glsl_const_01 = c_glsl_const_01;
	let tmp2397: t_glsl_const_00 = c_glsl_const_00;
	let tmp2398: t_glsl_const_00 = c_glsl_const_00;
	let tmp1038: f32 = (tmp1053);
	let tmp2400: f32 = (tmp2385 + mix(((tmp2384.v_radius).y), ((tmp2384.v_radius).x), step(c_glsl_const_00.v_o, (tmp1246.y))));
	let tmp1154: t_glsl_const_04 = c_glsl_const_04;
	let tmp2402: f32 = (tmp2401 - tmp2396);
	let tmp2707: f32 = dot(tmp2700, tmp2706);
	let tmp2522: f32 = mix(tmp2517, tmp2508, tmp2521);
	let tmp2531: f32 = max(tmp2528, tmp2530);
	let tmp2532: t_glsl_const_00 = c_glsl_const_00;
	let tmp2535: f32 = length(tmp2534);
	let tmp2388: vec2<f32> = (tmp2384.v_radius);
	let tmp1132: t_glsl_const_04 = c_glsl_const_04;
	let tmp2571: t_neo_elem_08_prim = u_neo_elem_08_prim;
	let tmp1139: f32 = (tmp1141 + tmp1140);
	let tmp2332: f32 = min(tmp2330, tmp2331.v_o);
	let tmp1127: f32 = (tmp1129 - tmp1128);
	let tmp1133: f32 = (tmp1137.v_o * tmp1134);
	let tmp1142: t_glsl_const_03 = c_glsl_const_03;
	let tmp2335: f32 = (tmp2334 - tmp2317);
	let tmp1117: f32 = (tmp1119 + tmp1118);
	let tmp2461: vec3<f32> = tmp1246;
	let tmp1155: f32 = (tmp1159.v_o * tmp1156);
	let tmp1152: t_glsl_const_03 = c_glsl_const_03;
	let tmp1149: f32 = (tmp1151 - tmp1150);
	let tmp1147: t_glsl_const_03 = c_glsl_const_03;
	let tmp1125: t_glsl_const_03 = c_glsl_const_03;
	let tmp401: vec3<f32> = ((tmp166));
	let tmp2533: f32 = min(tmp2531, tmp2532.v_o);
	let tmp1032: vec4<f32> = (u_neo_elem_08_transform.v_quat);
	let tmp2386: f32 = (tmp2461.y);
	let tmp1041: f32 = max(tmp1038, tmp1040.v_o);
	let tmp1046: f32 = max(tmp1044, tmp1045.v_o);
	let tmp2406: vec2<f32> = vec2<f32>(tmp2400, tmp2402);
	let tmp2404: vec2<f32> = vec2<f32>(tmp2400, tmp2402);
	let tmp2403: vec2<f32> = vec2<f32>(tmp2400, tmp2402);
	let tmp2399: vec2<f32> = vec2<f32>(tmp2397.v_o, tmp2398.v_o);
	let tmp2393: t_glsl_const_00 = c_glsl_const_00;
	let tmp2391: vec2<f32> = tmp2388;
	let tmp2389: vec2<f32> = tmp2388;
	let tmp1377: f32 = (u_neo_elem_04_transform.v_scale);
	let tmp1378: f32 = (tmp1536);
	let tmp2336: f32 = (tmp2332 + tmp2335);
	let tmp2686: vec2<f32> = (vec2<f32>(abs(((vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).z)).x)), ((vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).z)).y)) - vec2<f32>((u_neo_elem_09_prim.v_wi), (u_neo_elem_09_prim.v_r)));
	let tmp2572: vec2<f32> = (tmp2616);
	let tmp2574: vec4<f32> = (tmp2571.v_radius);
	let tmp1143: f32 = (tmp1147.v_o * tmp1144);
	let tmp1138: f32 = (tmp1142.v_o * tmp1139);
	let tmp1131: f32 = (tmp1133 - tmp1132.v_o);
	let tmp1126: f32 = (tmp1130.v_o * tmp1127);
	let tmp1121: f32 = (tmp1125.v_o * tmp1122);
	let tmp1116: f32 = (tmp1120.v_o * tmp1117);
	let tmp1109: f32 = (tmp1111 - tmp1110.v_o);
	let tmp1055: f32 = (tmp1190);
	let tmp1052: f32 = opp(tmp1054);
	let tmp1048: t_glsl_const_02 = c_glsl_const_02;
	let tmp2709: f32 = (tmp2707 + (u_neo_elem_09_prim.v_r));
	let tmp2711: t_glsl_const_03 = c_glsl_const_03;
	let tmp2601: vec2<f32> = abs(tmp2572);
	let tmp2730: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).z);
	let tmp1148: f32 = (tmp1152.v_o * tmp1149);
	let tmp1153: f32 = (tmp1155 - tmp1154.v_o);
	let tmp1034: vec4<f32> = (u_neo_elem_08_transform.v_quat);
	let tmp2587: vec2<f32> = tmp2572;
	let tmp2578: vec2<f32> = tmp2572;
	let tmp2573: vec2<f32> = (tmp2571.v_dims);
	let tmp2536: f32 = (tmp2535 - tmp2522);
	let tmp2394: f32 = step(tmp2393.v_o, tmp2386);
	let tmp1047: f32 = (tmp1046 * tmp1046);
	let tmp2687: f32 = length(tmp2686);
	let tmp1384: f32 = (tmp2336);
	let tmp1049: f32 = (tmp1048.v_o / tmp1041);
	let tmp2582: vec4<f32> = tmp2574;
	let tmp2657: vec2<f32> = (tmp2730);
	let tmp2842: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))) - ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) - ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) - ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((((t_position(a_pos).v_pos)))).x), abs((((((t_position(a_pos).v_pos)))).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_11_transform.v_sym).x))), mix((((((t_position(a_pos).v_pos)))).y), abs((((((t_position(a_pos).v_pos)))).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_11_transform.v_sym).y))), mix((((((t_position(a_pos).v_pos)))).z), abs((((((t_position(a_pos).v_pos)))).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_11_transform.v_sym).z))))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>((u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))) - ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) - ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) - ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).y) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).x) / length((u_neo_elem_11_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).w) / length((u_neo_elem_11_transform.v_quat)))) + ((((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat))) * (((u_neo_elem_11_transform.v_quat).z) / length((u_neo_elem_11_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((((t_position(a_pos).v_pos)))).x), abs((((((t_position(a_pos).v_pos)))).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_11_transform.v_sym).x))), mix((((((t_position(a_pos).v_pos)))).y), abs((((((t_position(a_pos).v_pos)))).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_11_transform.v_sym).y))), mix((((((t_position(a_pos).v_pos)))).z), abs((((((t_position(a_pos).v_pos)))).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_11_transform.v_sym).z))))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>((u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale))))).z));
	let tmp2580: vec4<f32> = tmp2574;
	let tmp2654: f32 = (u_neo_elem_09_prim.v_le);
	let tmp2390: f32 = (tmp2389.x);
	let tmp2584: t_glsl_const_00 = c_glsl_const_00;
	let tmp2710: f32 = abs(tmp2709);
	let tmp2712: f32 = ((u_neo_elem_09_prim.v_th) / tmp2711.v_o);
	let tmp2465: f32 = (u_neo_elem_07_mod.v_height);
	let tmp1108: mat3x3<f32> = mat3x3<f32>(tmp1153, tmp1148, tmp1143, tmp1138, tmp1131, tmp1126, tmp1121, tmp1116, tmp1109);
	let tmp1174: vec3<f32> = (((((vec3<f32>(mix((tmp679.x), abs((tmp679.x)), step(c_glsl_const_00.v_o, (tmp678.x))), mix((tmp679.y), abs((tmp679.y)), step(c_glsl_const_00.v_o, (tmp678.y))), mix((tmp679.z), abs((tmp679.z)), step(c_glsl_const_00.v_o, (tmp678.z))))) - (u_neo_elem_07_transform.v_trans))) / vec3<f32>(tmp964, tmp964, tmp964)));
	let tmp1376: f32 = (tmp1378 * tmp1377);
	let tmp2537: f32 = (tmp2533 + tmp2536);
	let tmp1036: f32 = (tmp1055);
	let tmp2603: vec2<f32> = vec2<f32>(mix(mix((tmp2574.w), (tmp2574.y), step(c_glsl_const_00.v_o, (tmp2587.x))), mix((tmp2582.z), (tmp2580.x), step(tmp2584.v_o, (tmp2578.x))), step(c_glsl_const_00.v_o, (tmp2572.y))), mix(mix((tmp2574.w), (tmp2574.y), step(c_glsl_const_00.v_o, (tmp2587.x))), mix((tmp2582.z), (tmp2580.x), step(tmp2584.v_o, (tmp2578.x))), step(c_glsl_const_00.v_o, (tmp2572.y))));
	let tmp2602: vec2<f32> = (tmp2601 - tmp2573);
	let tmp1031: f32 = (tmp1032.w);
	let tmp2650: vec2<f32> = (tmp2730);
	let tmp2575: t_glsl_const_00 = c_glsl_const_00;
	let tmp1033: f32 = length(tmp1034);
	let tmp2411: vec2<f32> = max(tmp2403, tmp2399);
	let tmp2576: t_glsl_const_00 = c_glsl_const_00;
	let tmp2405: f32 = (tmp2404.x);
	let tmp108: vec3<f32> = (((t_position(a_pos).v_pos)));
	let tmp009: t_neo_elem_04_transform = u_neo_elem_04_transform;
	let tmp1037: f32 = (tmp1052);
	let tmp2407: f32 = (tmp2406.y);
	let tmp2596: vec2<f32> = tmp2572;
	let tmp2593: t_glsl_const_00 = c_glsl_const_00;
	let tmp2591: vec4<f32> = tmp2574;
	let tmp2589: vec4<f32> = tmp2574;
	let tmp2588: f32 = (tmp2587.x);
	let tmp2392: f32 = (tmp2391.y);
	let tmp2579: f32 = (tmp2578.x);
	let tmp2658: f32 = (tmp2657.x);
	let tmp1107: vec3<f32> = (tmp1108 * tmp1174);
	let tmp2667: t_glsl_const_00 = c_glsl_const_00;
	let tmp2668: t_glsl_const_00 = c_glsl_const_00;
	let tmp2463: f32 = (tmp2537);
	let tmp2395: f32 = mix(tmp2392, tmp2390, tmp2394);
	let tmp2604: vec2<f32> = (tmp2602 + tmp2603);
	let tmp1027: f32 = ((tmp1034.x) / tmp1033);
	let tmp265: vec3<f32> = (u_neo_elem_10_transform.v_sym);
	let tmp2581: f32 = (tmp2580.x);
	let tmp2605: vec2<f32> = tmp2604;
	let tmp2676: vec2<f32> = vec2<f32>(abs(tmp2658), (tmp2650.y));
	let tmp1021: f32 = ((tmp1034.z) / tmp1033);
	let tmp2844: vec2<f32> = tmp2842;
	let tmp1239: f32 = (tmp1384);
	let tmp2412: f32 = length(tmp2411);
	let tmp1238: f32 = (u_neo_elem_05_transform.v_scale);
	let tmp1233: f32 = (tmp1376);
	let tmp2719: vec2<f32> = vec2<f32>((dot((vec2<f32>(abs(tmp2658), (tmp2650.y)) - vec2<f32>((u_neo_elem_09_prim.v_wi), (u_neo_elem_09_prim.v_r))), vec2<f32>(cos((u_neo_elem_09_prim.v_angle)), sin((u_neo_elem_09_prim.v_angle)))) - tmp2654), (tmp2710 - tmp2712));
	let tmp2708: f32 = (dot((vec2<f32>(abs(tmp2658), (tmp2650.y)) - vec2<f32>((u_neo_elem_09_prim.v_wi), (u_neo_elem_09_prim.v_r))), vec2<f32>(cos((u_neo_elem_09_prim.v_angle)), sin((u_neo_elem_09_prim.v_angle)))) - tmp2654);
	let tmp1030: f32 = (tmp1031 / tmp1033);
	let tmp2688: f32 = (tmp2687 - (u_neo_elem_09_prim.v_r));
	let tmp2690: t_glsl_const_03 = c_glsl_const_03;
	let tmp2585: f32 = step(tmp2584.v_o, tmp2579);
	let tmp2408: f32 = max(tmp2405, tmp2407);
	let tmp2598: t_glsl_const_00 = c_glsl_const_00;
	let tmp1039: f32 = max(tmp1036, tmp1037);
	let tmp2713: f32 = (tmp2710 - tmp2712);
	let tmp2607: vec2<f32> = tmp2604;
	let tmp2577: vec2<f32> = vec2<f32>(tmp2575.v_o, tmp2576.v_o);
	let tmp2597: f32 = (tmp2596.y);
	let tmp2462: t_neo_elem_07_mod = u_neo_elem_07_mod;
	let tmp1050: f32 = (tmp1047 * tmp1049);
	let tmp2409: t_glsl_const_00 = c_glsl_const_00;
	let tmp2594: f32 = step(tmp2593.v_o, tmp2588);
	let tmp2583: f32 = (tmp2582.z);
	let tmp2592: f32 = (tmp2591.w);
	let tmp1024: f32 = ((tmp1034.y) / tmp1033);
	let tmp2590: f32 = (tmp2589.y);
	let tmp2479: f32 = abs((tmp1107.y));
	let tmp2474: f32 = (tmp2465 - mix(((tmp2462.v_radius).y), ((tmp2462.v_radius).x), step(c_glsl_const_00.v_o, (tmp1107.y))));
	let tmp2717: vec2<f32> = vec2<f32>(tmp2708, tmp2713);
	let tmp2660: vec2<f32> = tmp2650;
	let tmp2847: vec2<f32> = tmp2842;
	let tmp2669: vec2<f32> = vec2<f32>(tmp2667.v_o, tmp2668.v_o);
	let tmp2670: vec2<f32> = vec2<f32>(abs(tmp2658), (tmp2660.y));
	let tmp2659: f32 = abs(tmp2658);
	let tmp2661: f32 = (tmp2660.y);
	let tmp1059: f32 = (tmp1233);
	let tmp2677: f32 = (tmp2676.y);
	let tmp2480: f32 = (tmp2479 - tmp2474);
	let tmp2679: t_glsl_const_03 = c_glsl_const_03;
	let tmp2718: f32 = (tmp2717.x);
	let tmp1051: f32 = (tmp1039 + tmp1050);
	let tmp2478: f32 = (tmp2463 + mix(((tmp2462.v_radius).y), ((tmp2462.v_radius).x), step(c_glsl_const_00.v_o, (tmp1107.y))));
	let tmp2689: f32 = abs(tmp2688);
	let tmp2691: f32 = ((u_neo_elem_09_prim.v_th) / tmp2690.v_o);
	let tmp2476: t_glsl_const_00 = c_glsl_const_00;
	let tmp2475: t_glsl_const_00 = c_glsl_const_00;
	let tmp2651: f32 = (u_neo_elem_09_prim.v_angle);
	let tmp906: f32 = max((max((tmp009.v_blend), c_glsl_const_01.v_o) - abs(((tmp1051) - (tmp1059)))), c_glsl_const_00.v_o);
	let tmp911: f32 = max((tmp009.v_blend), c_glsl_const_01.v_o);
	let tmp2410: f32 = min(tmp2408, tmp2409.v_o);
	let tmp051: vec3<f32> = ((t_position(a_pos).v_pos));
	let tmp2539: vec3<f32> = tmp1107;
	let tmp2848: f32 = (tmp2847.y);
	let tmp266: vec3<f32> = ((tmp108));
	let tmp2845: f32 = (tmp2844.x);
	let tmp1237: f32 = (tmp1239 * tmp1238);
	let tmp829: f32 = (u_neo_elem_08_transform.v_scale);
	let tmp2714: vec2<f32> = vec2<f32>(tmp2708, tmp2713);
	let tmp2413: f32 = (tmp2412 - tmp2395);
	let tmp2466: vec2<f32> = (tmp2462.v_radius);
	let tmp2586: f32 = mix(tmp2583, tmp2581, tmp2585);
	let tmp2595: f32 = mix(tmp2592, tmp2590, tmp2594);
	let tmp2652: f32 = (u_neo_elem_09_prim.v_r);
	let tmp2655: f32 = (u_neo_elem_09_prim.v_th);
	let tmp2599: f32 = step(tmp2598.v_o, tmp2597);
	let tmp899: vec4<f32> = (u_neo_elem_09_transform.v_quat);
	let tmp2606: f32 = (tmp2605.x);
	let tmp2608: f32 = (tmp2607.y);
	let tmp2612: vec2<f32> = max(tmp2604, tmp2577);
	let tmp2720: f32 = (tmp2719.y);
	let tmp2671: f32 = (tmp2670.x);
	let tmp2653: f32 = (u_neo_elem_09_prim.v_wi);
	let tmp2722: t_glsl_const_00 = c_glsl_const_00;
	let tmp2678: f32 = abs(tmp2677);
	let tmp2680: f32 = (tmp2655 / tmp2679.v_o);
	let tmp2471: t_glsl_const_00 = c_glsl_const_00;
	let tmp2682: t_glsl_const_00 = c_glsl_const_00;
	let tmp2600: f32 = mix(tmp2595, tmp2586, tmp2599);
	let tmp2664: f32 = cos(tmp2651);
	let tmp2464: f32 = (tmp2539.y);
	let tmp2849: f32 = opp(tmp2848);
	let tmp2715: vec2<f32> = max(tmp2714, tmp2669);
	let tmp916: f32 = (tmp1051);
	let tmp2694: t_glsl_const_00 = c_glsl_const_00;
	let tmp2692: f32 = (tmp2689 - tmp2691);
	let tmp2484: vec2<f32> = vec2<f32>(tmp2478, tmp2480);
	let tmp2685: f32 = opp(dot((vec2<f32>(tmp2659, tmp2661) - vec2<f32>(tmp2653, tmp2652)), vec2<f32>(tmp2664, sin(tmp2651))));
	let tmp2841: t_neo_elem_11_prim = u_neo_elem_11_prim;
	let tmp008: t_neo_elem_05_transform = u_neo_elem_05_transform;
	let tmp2846: f32 = abs(tmp2845);
	let tmp2663: vec2<f32> = vec2<f32>(tmp2653, tmp2652);
	let tmp2665: f32 = sin(tmp2651);
	let tmp2477: vec2<f32> = vec2<f32>(tmp2475.v_o, tmp2476.v_o);
	let tmp2609: f32 = max(tmp2606, tmp2608);
	let tmp2610: t_glsl_const_00 = c_glsl_const_00;
	let tmp2613: f32 = length(tmp2612);
	let tmp898: f32 = length(tmp899);
	let tmp2721: f32 = max(tmp2718, tmp2720);
	let tmp915: f32 = (tmp1059);
	let tmp2662: vec2<f32> = vec2<f32>(tmp2659, tmp2661);
	let tmp2482: vec2<f32> = vec2<f32>(tmp2478, tmp2480);
	let tmp2481: vec2<f32> = vec2<f32>(tmp2478, tmp2480);
	let tmp1094: f32 = (tmp1237);
	let tmp2467: vec2<f32> = tmp2466;
	let tmp2469: vec2<f32> = tmp2466;
	let tmp2414: f32 = (tmp2410 + tmp2413);
	let tmp200: vec3<f32> = (u_neo_elem_11_transform.v_sym);
	let tmp2673: vec2<f32> = (tmp2662 - tmp2663);
	let tmp2675: t_glsl_const_05 = c_glsl_const_05;
	let tmp2681: f32 = (tmp2678 - tmp2680);
	let tmp2672: f32 = (tmp2671 - tmp2653);
	let tmp2483: f32 = (tmp2482.x);
	let tmp889: f32 = ((tmp899.y) / tmp898);
	let tmp2468: f32 = (tmp2467.x);
	let tmp886: f32 = ((tmp899.z) / tmp898);
	let tmp1245: f32 = (tmp2414);
	let tmp2611: f32 = min(tmp2609, tmp2610.v_o);
	let tmp2763: t_neo_elem_10_prim = u_neo_elem_10_prim;
	let tmp201: vec3<f32> = ((tmp051));
	let tmp2470: f32 = (tmp2469.y);
	let tmp2666: vec2<f32> = vec2<f32>(tmp2664, tmp2665);
	let tmp2723: f32 = min(tmp2721, tmp2722.v_o);
	let tmp892: f32 = ((tmp899.x) / tmp898);
	let tmp2850: vec2<f32> = vec2<f32>(tmp2846, tmp2849);
	let tmp2472: f32 = step(tmp2471.v_o, tmp2464);
	let tmp2489: vec2<f32> = max(tmp2481, tmp2477);
	let tmp2866: vec2<f32> = (tmp2841.v_dims);
	let tmp2808: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))) - ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) - ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) - ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp266.x), abs((tmp266.x)), step(c_glsl_const_00.v_o, (tmp265.x))), mix((tmp266.y), abs((tmp266.y)), step(c_glsl_const_00.v_o, (tmp265.y))), mix((tmp266.z), abs((tmp266.z)), step(c_glsl_const_00.v_o, (tmp265.z))))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>((u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))) - ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) - ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) - ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).y) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).x) / length((u_neo_elem_10_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).w) / length((u_neo_elem_10_transform.v_quat)))) + ((((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat))) * (((u_neo_elem_10_transform.v_quat).z) / length((u_neo_elem_10_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp266.x), abs((tmp266.x)), step(c_glsl_const_00.v_o, (tmp265.x))), mix((tmp266.y), abs((tmp266.y)), step(c_glsl_const_00.v_o, (tmp265.y))), mix((tmp266.z), abs((tmp266.z)), step(c_glsl_const_00.v_o, (tmp265.z))))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>((u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale))))).z);
	let tmp895: f32 = ((tmp899.w) / tmp898);
	let tmp2697: t_glsl_const_00 = c_glsl_const_00;
	let tmp2716: f32 = length(tmp2715);
	let tmp2485: f32 = (tmp2484.y);
	let tmp2695: f32 = step(tmp2694.v_o, tmp2685);
	let tmp2861: vec2<f32> = tmp2850;
	let tmp2843: vec2<f32> = (tmp2841.v_dims);
	let tmp2693: f32 = min(mix(tmp2681, tmp2675.v_o, step(tmp2682.v_o, tmp2672)), tmp2692);
	let tmp2614: f32 = (tmp2613 - tmp2600);
	let tmp2683: f32 = step(tmp2682.v_o, tmp2672);
	let tmp2877: vec2<f32> = vec2<f32>(mix((length(tmp2850) - (tmp2866.x)), ((tmp2850 - tmp2843).x), step(c_glsl_const_00.v_o, (tmp2861.y))), ((tmp2850 - tmp2843).y));
	let tmp2852: vec2<f32> = (tmp2850 - tmp2843);
	let tmp2869: t_glsl_const_00 = c_glsl_const_00;
	let tmp2929: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))) - ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) - ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) - ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix(((((t_position(a_pos).v_pos))).x), abs(((((t_position(a_pos).v_pos))).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_12_transform.v_sym).x))), mix(((((t_position(a_pos).v_pos))).y), abs(((((t_position(a_pos).v_pos))).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_12_transform.v_sym).y))), mix(((((t_position(a_pos).v_pos))).z), abs(((((t_position(a_pos).v_pos))).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_12_transform.v_sym).z))))) - (u_neo_elem_12_transform.v_trans))) / vec3<f32>((u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))) - ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) - ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) - ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).y) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).x) / length((u_neo_elem_12_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).w) / length((u_neo_elem_12_transform.v_quat)))) + ((((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat))) * (((u_neo_elem_12_transform.v_quat).z) / length((u_neo_elem_12_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix(((((t_position(a_pos).v_pos))).x), abs(((((t_position(a_pos).v_pos))).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_12_transform.v_sym).x))), mix(((((t_position(a_pos).v_pos))).y), abs(((((t_position(a_pos).v_pos))).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_12_transform.v_sym).y))), mix(((((t_position(a_pos).v_pos))).z), abs(((((t_position(a_pos).v_pos))).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_12_transform.v_sym).z))))) - (u_neo_elem_12_transform.v_trans))) / vec3<f32>((u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale))))).z));
	let tmp2793: vec2<f32> = abs((tmp2808));
	let tmp2490: f32 = length(tmp2489);
	let tmp2764: vec2<f32> = (tmp2808);
	let tmp2766: vec4<f32> = (tmp2763.v_radius);
	let tmp2487: t_glsl_const_00 = c_glsl_const_00;
	let tmp2486: f32 = max(tmp2483, tmp2485);
	let tmp2698: f32 = step(tmp2697.v_o, tmp2672);
	let tmp760: vec4<f32> = (u_neo_elem_10_transform.v_quat);
	let tmp2779: vec2<f32> = tmp2764;
	let tmp2543: f32 = (u_neo_elem_08_mod.v_height);
	let tmp2770: vec2<f32> = tmp2764;
	let tmp2862: f32 = (tmp2861.y);
	let tmp2863: vec2<f32> = (tmp2850 - tmp2843);
	let tmp2851: vec2<f32> = (tmp2850 - tmp2843);
	let tmp2726: t_glsl_const_00 = c_glsl_const_00;
	let tmp2865: f32 = length(tmp2850);
	let tmp690: f32 = (u_neo_elem_09_transform.v_scale);
	let tmp2674: f32 = dot(tmp2673, tmp2666);
	let tmp2696: f32 = mix(mix(tmp2681, tmp2675.v_o, tmp2683), tmp2693, tmp2695);
	let tmp2684: f32 = mix(tmp2681, tmp2675.v_o, tmp2683);
	let tmp2765: vec2<f32> = (tmp2763.v_dims);
	let tmp2473: f32 = mix(tmp2470, tmp2468, tmp2472);
	let tmp1099: f32 = (u_neo_elem_06_transform.v_scale);
	let tmp2867: f32 = (tmp2866.x);
	let tmp2724: f32 = (tmp2716 + tmp2723);
	let tmp2615: f32 = (tmp2611 + tmp2614);
	let tmp1035: vec3<f32> = (((((vec3<f32>(mix((tmp540.x), abs((tmp540.x)), step(c_glsl_const_00.v_o, (tmp539.x))), mix((tmp540.y), abs((tmp540.y)), step(c_glsl_const_00.v_o, (tmp539.y))), mix((tmp540.z), abs((tmp540.z)), step(c_glsl_const_00.v_o, (tmp539.z))))) - (u_neo_elem_08_transform.v_trans))) / vec3<f32>(tmp829, tmp829, tmp829)));
	let tmp1100: f32 = (tmp1245);
	let tmp2541: f32 = (tmp2615);
	let tmp2552: f32 = (tmp2543 - mix(((u_neo_elem_08_mod.v_radius).y), ((u_neo_elem_08_mod.v_radius).x), step(c_glsl_const_00.v_o, ((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1027 * tmp1027))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp1027 * tmp1024) - (tmp1030 * tmp1021))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1021) + (tmp1030 * tmp1024))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1024) + (tmp1030 * tmp1021))), ((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1024 * tmp1024))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp1024 * tmp1021) - (tmp1030 * tmp1027))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1021) - (tmp1030 * tmp1024))), (c_glsl_const_03.v_o * ((tmp1024 * tmp1021) + (tmp1030 * tmp1027))), ((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1021 * tmp1021))) - c_glsl_const_04.v_o)) * tmp1035).y))));
	let tmp2557: f32 = abs(((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1027 * tmp1027))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp1027 * tmp1024) - (tmp1030 * tmp1021))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1021) + (tmp1030 * tmp1024))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1024) + (tmp1030 * tmp1021))), ((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1024 * tmp1024))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp1024 * tmp1021) - (tmp1030 * tmp1027))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1021) - (tmp1030 * tmp1024))), (c_glsl_const_03.v_o * ((tmp1024 * tmp1021) + (tmp1030 * tmp1027))), ((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1021 * tmp1021))) - c_glsl_const_04.v_o)) * tmp1035).y));
	let tmp2725: f32 = min(mix(tmp2684, tmp2696, tmp2698), tmp2724);
	let tmp2727: f32 = step(tmp2726.v_o, tmp2674);
	let tmp2767: t_glsl_const_00 = c_glsl_const_00;
	let tmp2768: t_glsl_const_00 = c_glsl_const_00;
	let tmp2771: f32 = (tmp2770.x);
	let tmp1098: f32 = (tmp1100 * tmp1099);
	let tmp2772: vec4<f32> = tmp2766;
	let tmp2774: vec4<f32> = tmp2766;
	let tmp2776: t_glsl_const_00 = c_glsl_const_00;
	let tmp2780: f32 = (tmp2779.x);
	let tmp2783: vec4<f32> = tmp2766;
	let tmp2785: t_glsl_const_00 = c_glsl_const_00;
	let tmp2788: vec2<f32> = tmp2764;
	let tmp2794: vec2<f32> = (tmp2793 - tmp2765);
	let tmp2795: vec2<f32> = vec2<f32>(mix(mix((tmp2783.w), (tmp2766.y), step(tmp2785.v_o, tmp2780)), mix((tmp2774.z), (tmp2772.x), step(tmp2776.v_o, tmp2771)), step(c_glsl_const_00.v_o, (tmp2788.y))), mix(mix((tmp2783.w), (tmp2766.y), step(tmp2785.v_o, tmp2780)), mix((tmp2774.z), (tmp2772.x), step(tmp2776.v_o, tmp2771)), step(c_glsl_const_00.v_o, (tmp2788.y))));
	let tmp2853: f32 = (tmp2852.x);
	let tmp2854: t_glsl_const_00 = c_glsl_const_00;
	let tmp2856: vec2<f32> = tmp2851;
	let tmp2864: f32 = (tmp2863.x);
	let tmp2868: f32 = (tmp2865 - tmp2867);
	let tmp2870: f32 = step(tmp2869.v_o, tmp2862);
	let tmp2872: vec2<f32> = tmp2851;
	let tmp2875: vec2<f32> = vec2<f32>(mix(tmp2868, tmp2864, tmp2870), (tmp2872.y));
	let tmp2878: f32 = (tmp2877.y);
	let tmp2879: t_glsl_const_00 = c_glsl_const_00;
	let tmp2699: f32 = mix(tmp2684, tmp2696, tmp2698);
	let tmp2540: t_neo_elem_08_mod = u_neo_elem_08_mod;
	let tmp767: f32 = max(((tmp008.v_blend)), c_glsl_const_01.v_o);
	let tmp772: f32 = max((tmp767 - abs(((((min(tmp916, tmp915) - ((tmp906 * tmp906) * (c_glsl_const_02.v_o / tmp911))))) - (opp(((tmp1094))))))), c_glsl_const_00.v_o);
	let tmp759: f32 = length(tmp760);
	let tmp2649: t_neo_elem_09_prim = u_neo_elem_09_prim;
	let tmp2781: vec4<f32> = tmp2766;
	let tmp2488: f32 = min(tmp2486, tmp2487.v_o);
	let tmp2491: f32 = (tmp2490 - tmp2473);
	let tmp2656: f32 = (tmp2649.v_ra);
	let tmp2873: f32 = (tmp2872.y);
	let tmp2617: vec3<f32> = (mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1027 * tmp1027))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp1027 * tmp1024) - (tmp1030 * tmp1021))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1021) + (tmp1030 * tmp1024))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1024) + (tmp1030 * tmp1021))), ((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1024 * tmp1024))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp1024 * tmp1021) - (tmp1030 * tmp1027))), (c_glsl_const_03.v_o * ((tmp1027 * tmp1021) - (tmp1030 * tmp1024))), (c_glsl_const_03.v_o * ((tmp1024 * tmp1021) + (tmp1030 * tmp1027))), ((c_glsl_const_03.v_o * ((tmp1030 * tmp1030) + (tmp1021 * tmp1021))) - c_glsl_const_04.v_o)) * tmp1035);
	let tmp2871: f32 = mix(tmp2868, tmp2864, tmp2870);
	let tmp2558: f32 = (tmp2557 - tmp2552);
	let tmp2784: f32 = (tmp2783.w);
	let tmp2796: vec2<f32> = (tmp2794 + tmp2795);
	let tmp2777: f32 = step(tmp2776.v_o, tmp2771);
	let tmp750: f32 = ((tmp760.y) / tmp759);
	let tmp2857: f32 = (tmp2856.y);
	let tmp2492: f32 = (tmp2488 + tmp2491);
	let tmp2799: vec2<f32> = tmp2796;
	let tmp2786: f32 = step(tmp2785.v_o, tmp2780);
	let tmp2855: f32 = max(tmp2853, tmp2854.v_o);
	let tmp2790: t_glsl_const_00 = c_glsl_const_00;
	let tmp2553: t_glsl_const_00 = c_glsl_const_00;
	let tmp033: vec3<f32> = (t_position(a_pos).v_pos);
	let tmp756: f32 = ((tmp760.w) / tmp759);
	let tmp621: vec4<f32> = (u_neo_elem_11_transform.v_quat);
	let tmp763: f32 = (opp(((tmp1094))));
	let tmp762: f32 = (((min(tmp916, tmp915) - ((tmp906 * tmp906) * (c_glsl_const_02.v_o / tmp911)))));
	let tmp2554: t_glsl_const_00 = c_glsl_const_00;
	let tmp007: t_neo_elem_06_transform = u_neo_elem_06_transform;
	let tmp2556: f32 = (tmp2541 + mix(((tmp2540.v_radius).y), ((tmp2540.v_radius).x), step(c_glsl_const_00.v_o, (tmp2617.y))));
	let tmp747: f32 = ((tmp760.z) / tmp759);
	let tmp753: f32 = ((tmp760.x) / tmp759);
	let tmp2728: f32 = mix(tmp2699, tmp2725, tmp2727);
	let tmp2797: vec2<f32> = tmp2796;
	let tmp2769: vec2<f32> = vec2<f32>(tmp2767.v_o, tmp2768.v_o);
	let tmp2773: f32 = (tmp2772.x);
	let tmp2775: f32 = (tmp2774.z);
	let tmp2789: f32 = (tmp2788.y);
	let tmp3067: vec2<f32> = vec2<f32>(cos((u_neo_elem_13_prim.v_angle)), sin((u_neo_elem_13_prim.v_angle)));
	let tmp2782: f32 = (tmp2781.y);
	let tmp2544: vec2<f32> = (tmp2540.v_radius);
	let tmp2880: f32 = max(tmp2878, tmp2879.v_o);
	let tmp2876: f32 = (tmp2875.x);
	let tmp2559: vec2<f32> = vec2<f32>(tmp2556, tmp2558);
	let tmp2798: f32 = (tmp2797.x);
	let tmp2560: vec2<f32> = tmp2559;
	let tmp2621: f32 = (u_neo_elem_09_mod.v_height);
	let tmp1106: f32 = (tmp2492);
	let tmp2562: vec2<f32> = tmp2559;
	let tmp620: f32 = length(tmp621);
	let tmp3070: vec2<f32> = vec2<f32>(cos((u_neo_elem_13_prim.v_angle)), sin((u_neo_elem_13_prim.v_angle)));
	let tmp3068: f32 = (tmp3067.y);
	let tmp2874: vec2<f32> = vec2<f32>(tmp2871, tmp2873);
	let tmp2804: vec2<f32> = max(tmp2796, tmp2769);
	let tmp142: vec3<f32> = (u_neo_elem_12_transform.v_sym);
	let tmp2729: f32 = (tmp2728 - tmp2656);
	let tmp2547: vec2<f32> = tmp2544;
	let tmp2787: f32 = mix(tmp2784, tmp2782, tmp2786);
	let tmp2549: t_glsl_const_00 = c_glsl_const_00;
	let tmp2542: f32 = (tmp2617.y);
	let tmp551: f32 = (u_neo_elem_10_transform.v_scale);
	let tmp2858: vec2<f32> = vec2<f32>(tmp2855, tmp2857);
	let tmp2545: vec2<f32> = tmp2544;
	let tmp2800: f32 = (tmp2799.y);
	let tmp2555: vec2<f32> = vec2<f32>(tmp2553.v_o, tmp2554.v_o);
	let tmp2778: f32 = mix(tmp2775, tmp2773, tmp2777);
	let tmp2791: f32 = step(tmp2790.v_o, tmp2789);
	let tmp2881: vec2<f32> = vec2<f32>(tmp2876, tmp2880);
	let tmp2805: f32 = length(tmp2804);
	let tmp2860: vec2<f32> = (tmp2858);
	let tmp2802: t_glsl_const_00 = c_glsl_const_00;
	let tmp2801: f32 = max(tmp2798, tmp2800);
	let tmp2561: f32 = (tmp2560.x);
	let tmp614: f32 = ((tmp621.x) / tmp620);
	let tmp611: f32 = ((tmp621.y) / tmp620);
	let tmp2883: vec2<f32> = (tmp2881);
	let tmp2888: vec2<f32> = tmp2874;
	let tmp608: f32 = ((tmp621.z) / tmp620);
	let tmp2886: vec2<f32> = tmp2874;
	let tmp143: vec3<f32> = ((tmp033));
	let tmp2619: f32 = (tmp2729);
	let tmp2630: f32 = (tmp2621 - mix(((u_neo_elem_09_mod.v_radius).y), ((u_neo_elem_09_mod.v_radius).x), step(c_glsl_const_00.v_o, ((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp892 * tmp892))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp892 * tmp889) - (tmp895 * tmp886))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) + (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp892 * tmp889) + (tmp895 * tmp886))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp889 * tmp889))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp889 * tmp886) - (tmp895 * tmp892))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) - (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp889 * tmp886) + (tmp895 * tmp892))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp886 * tmp886))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>(tmp690, tmp690, tmp690)))).y))));
	let tmp617: f32 = ((tmp621.w) / tmp620);
	let tmp2618: t_neo_elem_09_mod = u_neo_elem_09_mod;
	let tmp2546: f32 = (tmp2545.x);
	let tmp2548: f32 = (tmp2547.y);
	let tmp2550: f32 = step(tmp2549.v_o, tmp2542);
	let tmp2635: f32 = abs(((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp892 * tmp892))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp892 * tmp889) - (tmp895 * tmp886))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) + (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp892 * tmp889) + (tmp895 * tmp886))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp889 * tmp889))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp889 * tmp886) - (tmp895 * tmp892))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) - (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp889 * tmp886) + (tmp895 * tmp892))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp886 * tmp886))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>(tmp690, tmp690, tmp690)))).y));
	let tmp2792: f32 = mix(tmp2787, tmp2778, tmp2791);
	let tmp2930: vec2<f32> = (u_neo_elem_12_prim.v_dims);
	let tmp2937: vec2<f32> = vec2<f32>(abs((tmp2929.x)), opp((tmp2929.y)));
	let tmp3071: f32 = (tmp3070.x);
	let tmp2563: f32 = (tmp2562.y);
	let tmp3069: f32 = opp(tmp3068);
	let tmp2567: vec2<f32> = max(tmp2559, tmp2555);
	let tmp412: f32 = (u_neo_elem_11_transform.v_scale);
	let tmp2887: f32 = (tmp2886.x);
	let tmp2551: f32 = mix(tmp2548, tmp2546, tmp2550);
	let tmp628: f32 = max(((tmp007.v_blend)), c_glsl_const_01.v_o);
	let tmp2882: f32 = dot(tmp2883, tmp2883);
	let tmp2859: f32 = dot(tmp2860, tmp2860);
	let tmp3072: vec2<f32> = vec2<f32>(tmp3069, tmp3071);
	let tmp2631: t_glsl_const_00 = c_glsl_const_00;
	let tmp2803: f32 = min(tmp2801, tmp2802.v_o);
	let tmp2889: f32 = (tmp2888.y);
	let tmp014: t_position = t_position(a_pos);
	let tmp2564: f32 = max(tmp2561, tmp2563);
	let tmp2565: t_glsl_const_00 = c_glsl_const_00;
	let tmp2634: f32 = (tmp2619 + mix(((tmp2618.v_radius).y), ((tmp2618.v_radius).x), step(c_glsl_const_00.v_o, ((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp892 * tmp892))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp892 * tmp889) - (tmp895 * tmp886))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) + (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp892 * tmp889) + (tmp895 * tmp886))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp889 * tmp889))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp889 * tmp886) - (tmp895 * tmp892))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) - (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp889 * tmp886) + (tmp895 * tmp892))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp886 * tmp886))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>(tmp690, tmp690, tmp690)))).y))));
	let tmp2806: f32 = (tmp2805 - tmp2792);
	let tmp2731: vec3<f32> = (mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp892 * tmp892))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp892 * tmp889) - (tmp895 * tmp886))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) + (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp892 * tmp889) + (tmp895 * tmp886))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp889 * tmp889))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp889 * tmp886) - (tmp895 * tmp892))), (c_glsl_const_03.v_o * ((tmp892 * tmp886) - (tmp895 * tmp889))), (c_glsl_const_03.v_o * ((tmp889 * tmp886) + (tmp895 * tmp892))), ((c_glsl_const_03.v_o * ((tmp895 * tmp895) + (tmp886 * tmp886))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp401.x), abs((tmp401.x)), step(c_glsl_const_00.v_o, (tmp400.x))), mix((tmp401.y), abs((tmp401.y)), step(c_glsl_const_00.v_o, (tmp400.y))), mix((tmp401.z), abs((tmp401.z)), step(c_glsl_const_00.v_o, (tmp400.z))))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>(tmp690, tmp690, tmp690))));
	let tmp2568: f32 = length(tmp2567);
	let tmp2636: f32 = (tmp2635 - tmp2630);
	let tmp2622: vec2<f32> = (tmp2618.v_radius);
	let tmp3066: vec2<f32> = (vec2<f32>(abs(((vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp014.v_pos)).x), abs((((tmp014.v_pos)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).x))), mix((((tmp014.v_pos)).y), abs((((tmp014.v_pos)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).y))), mix((((tmp014.v_pos)).z), abs((((tmp014.v_pos)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).z))))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp014.v_pos)).x), abs((((tmp014.v_pos)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).x))), mix((((tmp014.v_pos)).y), abs((((tmp014.v_pos)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).y))), mix((((tmp014.v_pos)).z), abs((((tmp014.v_pos)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).z))))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).z)).x)), ((vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp014.v_pos)).x), abs((((tmp014.v_pos)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).x))), mix((((tmp014.v_pos)).y), abs((((tmp014.v_pos)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).y))), mix((((tmp014.v_pos)).z), abs((((tmp014.v_pos)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).z))))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp014.v_pos)).x), abs((((tmp014.v_pos)).x)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).x))), mix((((tmp014.v_pos)).y), abs((((tmp014.v_pos)).y)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).y))), mix((((tmp014.v_pos)).z), abs((((tmp014.v_pos)).z)), step(c_glsl_const_00.v_o, ((u_neo_elem_13_transform.v_sym).z))))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).z)).y)) - vec2<f32>((u_neo_elem_13_prim.v_wi), (u_neo_elem_13_prim.v_r)));
	let tmp2632: t_glsl_const_00 = c_glsl_const_00;
	let tmp2938: vec2<f32> = (tmp2937 - tmp2930);
	let tmp633: f32 = max((tmp628 - abs(((((max(tmp762, tmp763) + ((tmp772 * tmp772) * (c_glsl_const_02.v_o / tmp767))))) - (opp((((tmp1098)))))))), c_glsl_const_00.v_o);
	let tmp2884: f32 = min(tmp2859, tmp2882);
	let tmp085: vec3<f32> = (u_neo_elem_13_transform.v_sym);
	let tmp2637: vec2<f32> = vec2<f32>(tmp2634, tmp2636);
	let tmp2627: t_glsl_const_00 = c_glsl_const_00;
	let tmp2640: vec2<f32> = tmp2637;
	let tmp2625: vec2<f32> = tmp2622;
	let tmp2638: vec2<f32> = tmp2637;
	let tmp2633: vec2<f32> = vec2<f32>(tmp2631.v_o, tmp2632.v_o);
	let tmp2620: f32 = (tmp2731.y);
	let tmp2623: vec2<f32> = tmp2622;
	let tmp2890: f32 = max(tmp2887, tmp2889);
	let tmp624: f32 = (opp((((tmp1098)))));
	let tmp623: f32 = (((max(tmp762, tmp763) + ((tmp772 * tmp772) * (c_glsl_const_02.v_o / tmp767)))));
	let tmp006: t_neo_elem_07_transform = u_neo_elem_07_transform;
	let tmp2569: f32 = (tmp2568 - tmp2551);
	let tmp2807: f32 = (tmp2803 + tmp2806);
	let tmp2566: f32 = min(tmp2564, tmp2565.v_o);
	let tmp2735: f32 = (u_neo_elem_10_mod.v_height);
	let tmp3073: f32 = dot(tmp3066, tmp3072);
	let tmp2628: f32 = step(tmp2627.v_o, tmp2620);
	let tmp2626: f32 = (tmp2625.y);
	let tmp3096: vec2<f32> = vec2<f32>((mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp014.v_pos)).x), abs((((tmp014.v_pos)).x)), step(c_glsl_const_00.v_o, (tmp085.x))), mix((((tmp014.v_pos)).y), abs((((tmp014.v_pos)).y)), step(c_glsl_const_00.v_o, (tmp085.y))), mix((((tmp014.v_pos)).z), abs((((tmp014.v_pos)).z)), step(c_glsl_const_00.v_o, (tmp085.z))))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) - ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat)))))), (c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).y) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).x) / length((u_neo_elem_13_transform.v_quat)))))), ((c_glsl_const_03.v_o * (((((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).w) / length((u_neo_elem_13_transform.v_quat)))) + ((((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat))) * (((u_neo_elem_13_transform.v_quat).z) / length((u_neo_elem_13_transform.v_quat)))))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((((tmp014.v_pos)).x), abs((((tmp014.v_pos)).x)), step(c_glsl_const_00.v_o, (tmp085.x))), mix((((tmp014.v_pos)).y), abs((((tmp014.v_pos)).y)), step(c_glsl_const_00.v_o, (tmp085.y))), mix((((tmp014.v_pos)).z), abs((((tmp014.v_pos)).z)), step(c_glsl_const_00.v_o, (tmp085.z))))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).z);
	let tmp2624: f32 = (tmp2623.x);
	let tmp3052: vec2<f32> = (vec2<f32>(abs(((tmp3096).x)), ((tmp3096).y)) - vec2<f32>((u_neo_elem_13_prim.v_wi), (u_neo_elem_13_prim.v_r)));
	let tmp482: vec4<f32> = (u_neo_elem_12_transform.v_quat);
	let tmp2885: f32 = sqrt(tmp2884);
	let tmp2570: f32 = (tmp2566 + tmp2569);
	let tmp086: vec3<f32> = ((tmp014.v_pos));
	let tmp2645: vec2<f32> = max(tmp2637, tmp2633);
	let tmp2749: f32 = abs(((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp753 * tmp753))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp753 * tmp750) - (tmp756 * tmp747))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) + (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp753 * tmp750) + (tmp756 * tmp747))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp750 * tmp750))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp750 * tmp747) - (tmp756 * tmp753))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) - (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp750 * tmp747) + (tmp756 * tmp753))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp747 * tmp747))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp266.x), abs((tmp266.x)), step(c_glsl_const_00.v_o, (tmp265.x))), mix((tmp266.y), abs((tmp266.y)), step(c_glsl_const_00.v_o, (tmp265.y))), mix((tmp266.z), abs((tmp266.z)), step(c_glsl_const_00.v_o, (tmp265.z))))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>(tmp551, tmp551, tmp551)))).y));
	let tmp2641: f32 = (tmp2640.y);
	let tmp3077: t_glsl_const_03 = c_glsl_const_03;
	let tmp2639: f32 = (tmp2638.x);
	let tmp2732: t_neo_elem_10_mod = u_neo_elem_10_mod;
	let tmp2733: f32 = (tmp2807);
	let tmp2744: f32 = (tmp2735 - mix(((tmp2732.v_radius).y), ((tmp2732.v_radius).x), step(c_glsl_const_00.v_o, ((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp753 * tmp753))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp753 * tmp750) - (tmp756 * tmp747))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) + (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp753 * tmp750) + (tmp756 * tmp747))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp750 * tmp750))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp750 * tmp747) - (tmp756 * tmp753))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) - (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp750 * tmp747) + (tmp756 * tmp753))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp747 * tmp747))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp266.x), abs((tmp266.x)), step(c_glsl_const_00.v_o, (tmp265.x))), mix((tmp266.y), abs((tmp266.y)), step(c_glsl_const_00.v_o, (tmp265.y))), mix((tmp266.z), abs((tmp266.z)), step(c_glsl_const_00.v_o, (tmp265.z))))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>(tmp551, tmp551, tmp551)))).y))));
	let tmp2891: f32 = opp(tmp2885);
	let tmp3075: f32 = (tmp3073 + (u_neo_elem_13_prim.v_r));
	let tmp2748: f32 = (tmp2733 + mix(((tmp2732.v_radius).y), ((tmp2732.v_radius).x), step(c_glsl_const_00.v_o, ((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp753 * tmp753))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp753 * tmp750) - (tmp756 * tmp747))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) + (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp753 * tmp750) + (tmp756 * tmp747))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp750 * tmp750))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp750 * tmp747) - (tmp756 * tmp753))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) - (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp750 * tmp747) + (tmp756 * tmp753))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp747 * tmp747))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp266.x), abs((tmp266.x)), step(c_glsl_const_00.v_o, (tmp265.x))), mix((tmp266.y), abs((tmp266.y)), step(c_glsl_const_00.v_o, (tmp265.y))), mix((tmp266.z), abs((tmp266.z)), step(c_glsl_const_00.v_o, (tmp265.z))))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>(tmp551, tmp551, tmp551)))).y))));
	let tmp3016: vec2<f32> = (tmp3096);
	let tmp2643: t_glsl_const_00 = c_glsl_const_00;
	let tmp2813: f32 = (u_neo_elem_11_mod.v_height);
	let tmp2745: t_glsl_const_00 = c_glsl_const_00;
	let tmp2750: f32 = (tmp2749 - tmp2744);
	let tmp3076: f32 = abs(tmp3075);
	let tmp2746: t_glsl_const_00 = c_glsl_const_00;
	let tmp2642: f32 = max(tmp2639, tmp2641);
	let tmp2736: vec2<f32> = (tmp2732.v_radius);
	let tmp481: f32 = length(tmp482);
	let tmp3078: f32 = ((u_neo_elem_13_prim.v_th) / tmp3077.v_o);
	let tmp3053: f32 = length(tmp3052);
	let tmp2961: vec2<f32> = vec2<f32>(mix((length(tmp2937) - (tmp2930.x)), (tmp2938.x), step(c_glsl_const_00.v_o, (tmp2937.y))), (tmp2938.y));
	let tmp2629: f32 = mix(tmp2626, tmp2624, tmp2628);
	let tmp2646: f32 = length(tmp2645);
	let tmp2809: vec3<f32> = (mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp753 * tmp753))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp753 * tmp750) - (tmp756 * tmp747))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) + (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp753 * tmp750) + (tmp756 * tmp747))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp750 * tmp750))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp750 * tmp747) - (tmp756 * tmp753))), (c_glsl_const_03.v_o * ((tmp753 * tmp747) - (tmp756 * tmp750))), (c_glsl_const_03.v_o * ((tmp750 * tmp747) + (tmp756 * tmp753))), ((c_glsl_const_03.v_o * ((tmp756 * tmp756) + (tmp747 * tmp747))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp266.x), abs((tmp266.x)), step(c_glsl_const_00.v_o, (tmp265.x))), mix((tmp266.y), abs((tmp266.y)), step(c_glsl_const_00.v_o, (tmp265.y))), mix((tmp266.z), abs((tmp266.z)), step(c_glsl_const_00.v_o, (tmp265.z))))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>(tmp551, tmp551, tmp551))));
	let tmp3054: f32 = (tmp3053 - (u_neo_elem_13_prim.v_r));
	let tmp3079: f32 = (tmp3076 - tmp3078);
	let tmp2947: vec2<f32> = (vec2<f32>(max((tmp2938.x), c_glsl_const_00.v_o), (tmp2938.y)));
	let tmp3085: vec2<f32> = vec2<f32>((dot((vec2<f32>(abs((tmp3016.x)), (tmp3016.y)) - vec2<f32>((u_neo_elem_13_prim.v_wi), (u_neo_elem_13_prim.v_r))), vec2<f32>(cos((u_neo_elem_13_prim.v_angle)), sin((u_neo_elem_13_prim.v_angle)))) - (u_neo_elem_13_prim.v_le)), tmp3079);
	let tmp2751: vec2<f32> = vec2<f32>(tmp2748, tmp2750);
	let tmp3083: vec2<f32> = vec2<f32>((dot((vec2<f32>(abs((tmp3016.x)), (tmp3016.y)) - vec2<f32>((u_neo_elem_13_prim.v_wi), (u_neo_elem_13_prim.v_r))), vec2<f32>(cos((u_neo_elem_13_prim.v_angle)), sin((u_neo_elem_13_prim.v_angle)))) - (u_neo_elem_13_prim.v_le)), tmp3079);
	let tmp3074: f32 = (dot((vec2<f32>(abs((tmp3016.x)), (tmp3016.y)) - vec2<f32>((u_neo_elem_13_prim.v_wi), (u_neo_elem_13_prim.v_r))), vec2<f32>(cos((u_neo_elem_13_prim.v_angle)), sin((u_neo_elem_13_prim.v_angle)))) - (u_neo_elem_13_prim.v_le));
	let tmp2810: t_neo_elem_11_mod = u_neo_elem_11_mod;
	let tmp2970: vec2<f32> = (vec2<f32>((tmp2961.x), max((tmp2961.y), c_glsl_const_00.v_o)));
	let tmp2822: f32 = (tmp2813 - mix(((tmp2810.v_radius).y), ((tmp2810.v_radius).x), step(c_glsl_const_00.v_o, ((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp614 * tmp614))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp614 * tmp611) - (tmp617 * tmp608))), (c_glsl_const_03.v_o * ((tmp614 * tmp608) + (tmp617 * tmp611))), (c_glsl_const_03.v_o * ((tmp614 * tmp611) + (tmp617 * tmp608))), ((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp611 * tmp611))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp611 * tmp608) - (tmp617 * tmp614))), (c_glsl_const_03.v_o * ((tmp614 * tmp608) - (tmp617 * tmp611))), (c_glsl_const_03.v_o * ((tmp611 * tmp608) + (tmp617 * tmp614))), ((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp608 * tmp608))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp201.x), abs((tmp201.x)), step(c_glsl_const_00.v_o, (tmp200.x))), mix((tmp201.y), abs((tmp201.y)), step(c_glsl_const_00.v_o, (tmp200.y))), mix((tmp201.z), abs((tmp201.z)), step(c_glsl_const_00.v_o, (tmp200.z))))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>(tmp412, tmp412, tmp412)))).y))));
	let tmp2827: f32 = abs(((mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp614 * tmp614))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp614 * tmp611) - (tmp617 * tmp608))), (c_glsl_const_03.v_o * ((tmp614 * tmp608) + (tmp617 * tmp611))), (c_glsl_const_03.v_o * ((tmp614 * tmp611) + (tmp617 * tmp608))), ((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp611 * tmp611))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp611 * tmp608) - (tmp617 * tmp614))), (c_glsl_const_03.v_o * ((tmp614 * tmp608) - (tmp617 * tmp611))), (c_glsl_const_03.v_o * ((tmp611 * tmp608) + (tmp617 * tmp614))), ((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp608 * tmp608))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp201.x), abs((tmp201.x)), step(c_glsl_const_00.v_o, (tmp200.x))), mix((tmp201.y), abs((tmp201.y)), step(c_glsl_const_00.v_o, (tmp200.y))), mix((tmp201.z), abs((tmp201.z)), step(c_glsl_const_00.v_o, (tmp200.z))))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>(tmp412, tmp412, tmp412)))).y));
	let tmp2754: vec2<f32> = tmp2751;
	let tmp2752: vec2<f32> = tmp2751;
	let tmp2747: vec2<f32> = vec2<f32>(tmp2745.v_o, tmp2746.v_o);
	let tmp489: f32 = max(((tmp006.v_blend)), c_glsl_const_01.v_o);
	let tmp2734: f32 = (tmp2809.y);
	let tmp2741: t_glsl_const_00 = c_glsl_const_00;
	let tmp2739: vec2<f32> = tmp2736;
	let tmp2737: vec2<f32> = tmp2736;
	let tmp494: f32 = max((tmp489 - abs(((((max(tmp623, tmp624) + ((tmp633 * tmp633) * (c_glsl_const_02.v_o / tmp628))))) - (opp((((((tmp1106) * (tmp006.v_scale)))))))))), c_glsl_const_00.v_o);
	let tmp475: f32 = ((tmp482.x) / tmp481);
	let tmp472: f32 = ((tmp482.y) / tmp481);
	let tmp469: f32 = ((tmp482.z) / tmp481);
	let tmp2811: f32 = (mix(tmp2891, tmp2885, step(c_glsl_const_00.v_o, tmp2890)));
	let tmp478: f32 = ((tmp482.w) / tmp481);
	let tmp3056: t_glsl_const_03 = c_glsl_const_03;
	let tmp2644: f32 = min(tmp2642, tmp2643.v_o);
	let tmp2647: f32 = (tmp2646 - tmp2629);
	let tmp2824: t_glsl_const_00 = c_glsl_const_00;
	let tmp277: f32 = (u_neo_elem_12_transform.v_scale);
	let tmp3055: f32 = abs(tmp3054);
	let tmp3080: vec2<f32> = vec2<f32>(tmp3074, tmp3079);
	let tmp2828: f32 = (tmp2827 - tmp2822);
	let tmp2648: f32 = (tmp2644 + tmp2647);
	let tmp2753: f32 = (tmp2752.x);
	let tmp2759: vec2<f32> = max(tmp2751, tmp2747);
	let tmp2814: vec2<f32> = (tmp2810.v_radius);
	let tmp3021: f32 = (u_neo_elem_13_prim.v_th);
	let tmp3017: f32 = (u_neo_elem_13_prim.v_angle);
	let tmp2742: f32 = step(tmp2741.v_o, tmp2734);
	let tmp2823: t_glsl_const_00 = c_glsl_const_00;
	let tmp2738: f32 = (tmp2737.x);
	let tmp2740: f32 = (tmp2739.y);
	let tmp3057: f32 = (tmp3021 / tmp3056.v_o);
	let tmp347: vec4<f32> = (u_neo_elem_13_transform.v_quat);
	let tmp485: f32 = (opp((((((tmp1106) * (tmp006.v_scale)))))));
	let tmp484: f32 = (((max(tmp623, tmp624) + ((tmp633 * tmp633) * (c_glsl_const_02.v_o / tmp628)))));
	let tmp3084: f32 = (tmp3083.x);
	let tmp2896: vec3<f32> = (mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp614 * tmp614))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp614 * tmp611) - (tmp617 * tmp608))), (c_glsl_const_03.v_o * ((tmp614 * tmp608) + (tmp617 * tmp611))), (c_glsl_const_03.v_o * ((tmp614 * tmp611) + (tmp617 * tmp608))), ((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp611 * tmp611))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp611 * tmp608) - (tmp617 * tmp614))), (c_glsl_const_03.v_o * ((tmp614 * tmp608) - (tmp617 * tmp611))), (c_glsl_const_03.v_o * ((tmp611 * tmp608) + (tmp617 * tmp614))), ((c_glsl_const_03.v_o * ((tmp617 * tmp617) + (tmp608 * tmp608))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp201.x), abs((tmp201.x)), step(c_glsl_const_00.v_o, (tmp200.x))), mix((tmp201.y), abs((tmp201.y)), step(c_glsl_const_00.v_o, (tmp200.y))), mix((tmp201.z), abs((tmp201.z)), step(c_glsl_const_00.v_o, (tmp200.z))))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>(tmp412, tmp412, tmp412))));
	let tmp2755: f32 = (tmp2754.y);
	let tmp3086: f32 = (tmp3085.y);
	let tmp3018: f32 = (u_neo_elem_13_prim.v_r);
	let tmp2826: f32 = (tmp2811 + mix((tmp2814.y), (tmp2814.x), step(c_glsl_const_00.v_o, (tmp2896.y))));
	let tmp005: t_neo_elem_08_transform = u_neo_elem_08_transform;
	let tmp3019: f32 = (u_neo_elem_13_prim.v_wi);
	let tmp2825: vec2<f32> = vec2<f32>(tmp2823.v_o, tmp2824.v_o);
	let tmp2817: vec2<f32> = tmp2814;
	let tmp2815: vec2<f32> = tmp2814;
	let tmp2819: t_glsl_const_00 = c_glsl_const_00;
	let tmp2812: f32 = (tmp2896.y);
	let tmp3060: t_glsl_const_00 = c_glsl_const_00;
	let tmp3088: t_glsl_const_00 = c_glsl_const_00;
	let tmp2743: f32 = mix(tmp2740, tmp2738, tmp2742);
	let tmp3051: f32 = opp(dot((vec2<f32>(abs((tmp3016.x)), (tmp3016.y)) - vec2<f32>(tmp3019, tmp3018)), vec2<f32>(cos(tmp3017), sin(tmp3017))));
	let tmp3048: t_glsl_const_00 = c_glsl_const_00;
	let tmp3081: vec2<f32> = max(tmp3080, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o));
	let tmp3087: f32 = max(tmp3084, tmp3086);
	let tmp2830: vec2<f32> = vec2<f32>(tmp2826, tmp2828);
	let tmp2756: f32 = max(tmp2753, tmp2755);
	let tmp2757: t_glsl_const_00 = c_glsl_const_00;
	let tmp3058: f32 = (tmp3055 - tmp3057);
	let tmp3029: vec2<f32> = vec2<f32>(tmp3019, tmp3018);
	let tmp2829: vec2<f32> = vec2<f32>(tmp2826, tmp2828);
	let tmp2760: f32 = length(tmp2759);
	let tmp3028: vec2<f32> = vec2<f32>(abs((tmp3016.x)), (tmp3016.y));
	let tmp2832: vec2<f32> = tmp2829;
	let tmp346: f32 = length(tmp347);
	let tmp354: f32 = max((max((tmp005.v_blend), c_glsl_const_01.v_o) - abs((((max(tmp484, tmp485) + ((tmp494 * tmp494) * (c_glsl_const_02.v_o / tmp489)))) - ((((((tmp2570)) * (tmp005.v_scale)))))))), c_glsl_const_00.v_o);
	let tmp334: f32 = ((tmp347.z) / tmp346);
	let tmp2820: f32 = step(tmp2819.v_o, tmp2812);
	let tmp3038: f32 = ((tmp3028.x) - tmp3019);
	let tmp340: f32 = ((tmp347.x) / tmp346);
	let tmp3032: vec2<f32> = vec2<f32>(cos(tmp3017), sin(tmp3017));
	let tmp2761: f32 = (tmp2760 - tmp2743);
	let tmp337: f32 = ((tmp347.y) / tmp346);
	let tmp2972: f32 = sqrt(min(dot(tmp2947, tmp2947), dot(tmp2970, tmp2970)));
	let tmp2816: f32 = (tmp2815.x);
	let tmp3059: f32 = min(mix((abs((tmp3028.y)) - (tmp3021 / c_glsl_const_03.v_o)), c_glsl_const_05.v_o, step(tmp3048.v_o, tmp3038)), tmp3058);
	let tmp2833: f32 = (tmp2832.y);
	let tmp2758: f32 = min(tmp2756, tmp2757.v_o);
	let tmp3063: t_glsl_const_00 = c_glsl_const_00;
	let tmp3061: f32 = step(tmp3060.v_o, tmp3051);
	let tmp2818: f32 = (tmp2817.y);
	let tmp359: f32 = max((tmp005.v_blend), c_glsl_const_01.v_o);
	let tmp3089: f32 = min(tmp3087, tmp3088.v_o);
	let tmp3082: f32 = length(tmp3081);
	let tmp2831: f32 = (tmp2830.x);
	let tmp2837: vec2<f32> = max(tmp2829, tmp2825);
	let tmp3049: f32 = step(tmp3048.v_o, tmp3038);
	let tmp343: f32 = ((tmp347.w) / tmp346);
	let tmp3047: f32 = (abs((tmp3028.y)) - (tmp3021 / c_glsl_const_03.v_o));
	let tmp2762: f32 = (tmp2758 + tmp2761);
	let tmp3040: f32 = dot((tmp3028 - tmp3029), tmp3032);
	let tmp363: f32 = ((((((tmp2570)) * (tmp005.v_scale)))));
	let tmp3092: t_glsl_const_00 = c_glsl_const_00;
	let tmp2834: f32 = max(tmp2831, tmp2833);
	let tmp3050: f32 = mix(tmp3047, c_glsl_const_05.v_o, tmp3049);
	let tmp3090: f32 = (tmp3082 + tmp3089);
	let tmp364: f32 = ((max(tmp484, tmp485) + ((tmp494 * tmp494) * (c_glsl_const_02.v_o / tmp489))));
	let tmp212: f32 = (u_neo_elem_13_transform.v_scale);
	let tmp2835: t_glsl_const_00 = c_glsl_const_00;
	let tmp3064: f32 = step(tmp3063.v_o, tmp3038);
	let tmp3062: f32 = mix(tmp3050, tmp3059, tmp3061);
	let tmp004: t_neo_elem_09_transform = u_neo_elem_09_transform;
	let tmp2821: f32 = mix(tmp2818, tmp2816, tmp2820);
	let tmp2838: f32 = length(tmp2837);
	let tmp3065: f32 = mix(tmp3050, tmp3062, tmp3064);
	let tmp3091: f32 = min(tmp3065, tmp3090);
	let tmp3015: t_neo_elem_13_prim = u_neo_elem_13_prim;
	let tmp2836: f32 = min(tmp2834, tmp2835.v_o);
	let tmp3093: f32 = step(tmp3092.v_o, tmp3040);
	let tmp2897: t_neo_elem_12_mod = u_neo_elem_12_mod;
	let tmp2839: f32 = (tmp2838 - tmp2821);
	let tmp224: f32 = max((tmp004.v_blend), c_glsl_const_01.v_o);
	let tmp2901: vec2<f32> = (tmp2897.v_radius);
	let tmp2840: f32 = (tmp2836 + tmp2839);
	let tmp2983: vec3<f32> = (mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp478 * tmp478) + (tmp475 * tmp475))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp475 * tmp472) - (tmp478 * tmp469))), (c_glsl_const_03.v_o * ((tmp475 * tmp469) + (tmp478 * tmp472))), (c_glsl_const_03.v_o * ((tmp475 * tmp472) + (tmp478 * tmp469))), ((c_glsl_const_03.v_o * ((tmp478 * tmp478) + (tmp472 * tmp472))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp472 * tmp469) - (tmp478 * tmp475))), (c_glsl_const_03.v_o * ((tmp475 * tmp469) - (tmp478 * tmp472))), (c_glsl_const_03.v_o * ((tmp472 * tmp469) + (tmp478 * tmp475))), ((c_glsl_const_03.v_o * ((tmp478 * tmp478) + (tmp469 * tmp469))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp143.x), abs((tmp143.x)), step(c_glsl_const_00.v_o, (tmp142.x))), mix((tmp143.y), abs((tmp143.y)), step(c_glsl_const_00.v_o, (tmp142.y))), mix((tmp143.z), abs((tmp143.z)), step(c_glsl_const_00.v_o, (tmp142.z))))) - (u_neo_elem_12_transform.v_trans))) / vec3<f32>(tmp277, tmp277, tmp277))));
	let tmp3094: f32 = mix(tmp3065, tmp3091, tmp3093);
	let tmp219: f32 = max((tmp224 - abs((((min(tmp364, tmp363) - ((tmp354 * tmp354) * (c_glsl_const_02.v_o / tmp359)))) - ((((((tmp2648)) * (tmp004.v_scale)))))))), c_glsl_const_00.v_o);
	let tmp2916: vec2<f32> = vec2<f32>(((mix(opp(tmp2972), tmp2972, step(c_glsl_const_00.v_o, max((tmp2961.x), (tmp2961.y))))) + mix((tmp2901.y), (tmp2901.x), step(c_glsl_const_00.v_o, (tmp2983.y)))), (abs((tmp2983.y)) - ((tmp2897.v_height) - mix((tmp2901.y), (tmp2901.x), step(c_glsl_const_00.v_o, (tmp2983.y))))));
	let tmp228: f32 = ((((((tmp2648)) * (tmp004.v_scale)))));
	let tmp229: f32 = ((min(tmp364, tmp363) - ((tmp354 * tmp354) * (c_glsl_const_02.v_o / tmp359))));
	let tmp2899: f32 = (tmp2983.y);
	let tmp003: t_neo_elem_10_transform = u_neo_elem_10_transform;
	let tmp3095: f32 = (tmp3094 - (tmp3015.v_ra));
	let tmp2984: t_neo_elem_13_mod = u_neo_elem_13_mod;
	let tmp2908: f32 = mix((tmp2901.y), (tmp2901.x), step(c_glsl_const_00.v_o, tmp2899));
	let tmp159: f32 = max((tmp003.v_blend), c_glsl_const_01.v_o);
	let tmp2988: vec2<f32> = (tmp2984.v_radius);
	let tmp154: f32 = max((tmp159 - abs((((min(tmp229, tmp228) - ((tmp219 * tmp219) * (c_glsl_const_02.v_o / tmp224)))) - ((((((tmp2762)) * (tmp003.v_scale)))))))), c_glsl_const_00.v_o);
	let tmp3097: vec3<f32> = (mat3x3<f32>(((c_glsl_const_03.v_o * ((tmp343 * tmp343) + (tmp340 * tmp340))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp340 * tmp337) - (tmp343 * tmp334))), (c_glsl_const_03.v_o * ((tmp340 * tmp334) + (tmp343 * tmp337))), (c_glsl_const_03.v_o * ((tmp340 * tmp337) + (tmp343 * tmp334))), ((c_glsl_const_03.v_o * ((tmp343 * tmp343) + (tmp337 * tmp337))) - c_glsl_const_04.v_o), (c_glsl_const_03.v_o * ((tmp337 * tmp334) - (tmp343 * tmp340))), (c_glsl_const_03.v_o * ((tmp340 * tmp334) - (tmp343 * tmp337))), (c_glsl_const_03.v_o * ((tmp337 * tmp334) + (tmp343 * tmp340))), ((c_glsl_const_03.v_o * ((tmp343 * tmp343) + (tmp334 * tmp334))) - c_glsl_const_04.v_o)) * (((((vec3<f32>(mix((tmp086.x), abs((tmp086.x)), step(c_glsl_const_00.v_o, (tmp085.x))), mix((tmp086.y), abs((tmp086.y)), step(c_glsl_const_00.v_o, (tmp085.y))), mix((tmp086.z), abs((tmp086.z)), step(c_glsl_const_00.v_o, (tmp085.z))))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>(tmp212, tmp212, tmp212))));
	let tmp3003: vec2<f32> = vec2<f32>(((tmp3095) + mix((tmp2988.y), (tmp2988.x), step(c_glsl_const_00.v_o, (tmp3097.y)))), (abs((tmp3097.y)) - ((tmp2984.v_height) - mix((tmp2988.y), (tmp2988.x), step(c_glsl_const_00.v_o, (tmp3097.y))))));
	let tmp163: f32 = ((((((tmp2762)) * (tmp003.v_scale)))));
	let tmp2986: f32 = (tmp3097.y);
	let tmp002: t_neo_elem_11_transform = u_neo_elem_11_transform;
	let tmp164: f32 = ((min(tmp229, tmp228) - ((tmp219 * tmp219) * (c_glsl_const_02.v_o / tmp224))));
	let tmp2995: f32 = mix((tmp2988.y), (tmp2988.x), step(c_glsl_const_00.v_o, tmp2986));
	let tmp097: f32 = max((max(((tmp002.v_blend)), c_glsl_const_01.v_o) - abs(((((min(tmp164, tmp163) - ((tmp154 * tmp154) * (c_glsl_const_02.v_o / tmp159))))) - (opp(((((((tmp2840)) * (tmp002.v_scale)))))))))), c_glsl_const_00.v_o);
	let tmp092: f32 = max(((tmp002.v_blend)), c_glsl_const_01.v_o);
	let tmp001: t_neo_elem_12_transform = u_neo_elem_12_transform;
	let tmp087: f32 = (((min(tmp164, tmp163) - ((tmp154 * tmp154) * (c_glsl_const_02.v_o / tmp159)))));
	let tmp088: f32 = (opp(((((((tmp2840)) * (tmp002.v_scale)))))));
	let tmp039: f32 = max((max((tmp001.v_blend), c_glsl_const_01.v_o) - abs((((max(tmp087, tmp088) + ((tmp097 * tmp097) * (c_glsl_const_02.v_o / tmp092)))) - (((((((min(max((tmp2916.x), (tmp2916.y)), c_glsl_const_00.v_o) + (length(max(tmp2916, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2908)))) * (tmp001.v_scale)))))))), c_glsl_const_00.v_o);
	let tmp044: f32 = max((tmp001.v_blend), c_glsl_const_01.v_o);
	let tmp000: t_neo_elem_13_transform = u_neo_elem_13_transform;
	let tmp048: f32 = (((((((min(max((tmp2916.x), (tmp2916.y)), c_glsl_const_00.v_o) + (length(max(tmp2916, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2908)))) * (tmp001.v_scale)))));
	let tmp049: f32 = ((max(tmp087, tmp088) + ((tmp097 * tmp097) * (c_glsl_const_02.v_o / tmp092))));
	let tmp026: f32 = max((tmp000.v_blend), c_glsl_const_01.v_o);
	let tmp021: f32 = max((tmp026 - abs((((min(tmp049, tmp048) - ((tmp039 * tmp039) * (c_glsl_const_02.v_o / tmp044)))) - (((((((min(max((tmp3003.x), (tmp3003.y)), c_glsl_const_00.v_o) + (length(max(tmp3003, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2995)))) * (tmp000.v_scale)))))))), c_glsl_const_00.v_o);
	let tmp031: f32 = ((min(tmp049, tmp048) - ((tmp039 * tmp039) * (c_glsl_const_02.v_o / tmp044))));
	let tmp030: f32 = (((((((min(max((tmp3003.x), (tmp3003.y)), c_glsl_const_00.v_o) + (length(max(tmp3003, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2995)))) * (tmp000.v_scale)))));
	return t_outlet((min(tmp031, tmp030) - ((tmp021 * tmp021) * (c_glsl_const_02.v_o / tmp026))));
}

