//// PREAMBLE

fn signed_distance_function(pos_: vec3<f32>) -> f32 {
	var pos = pos_;
	pos += vec3(0.0, 0.6, 0.0);
	pos /= 3.0;
    return compute_main_digraph(pos).v_dist * 3.0;
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

struct t_neo_elem_00_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_25_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_09_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_27_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_01_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_06_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_16_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_09_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_05_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_20_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_14_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_21_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_02_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_11_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_31_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_08_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_28_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_00_mod {
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
}

struct t_neo_elem_25_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_10_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_29_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_39_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
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

struct t_neo_elem_07_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_16_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_15_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_05_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_01_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_11_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_21_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_02_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_12_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_31_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_50_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_27_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_07_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_23_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_04_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_32_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_13_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_03_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_12_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_33_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_03_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_03_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_13_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_08_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_06_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_35_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_15_mod {
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
}

struct t_neo_elem_14_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_45_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_24_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_05_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_26_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_07_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_17_prim {
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

struct t_neo_elem_17_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_33_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_18_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_18_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_09_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_11_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_12_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_13_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_14_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_15_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_16_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_17_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_18_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_19_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_19_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_19_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_20_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_20_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_21_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_22_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_22_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_22_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_23_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_23_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_40_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_24_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_24_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_25_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_26_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_39_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_26_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_27_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_28_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_28_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_29_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_29_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_30_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_30_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_34_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_30_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_31_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_32_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_32_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_33_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_34_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_34_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_42_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_35_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_35_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_36_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_36_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_36_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_37_prim {
	v_angle: f32,
	v_r: f32,
	v_wi: f32,
	v_le: f32,
	v_th: f32,
	v_ra: f32,
}

struct t_neo_elem_37_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_37_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_38_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_38_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_38_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_39_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_40_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_40_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_41_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_41_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_41_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_42_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_42_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_43_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_43_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_43_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_44_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_44_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_44_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_45_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_45_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_46_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_46_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_46_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_47_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_47_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_47_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_48_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_48_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_48_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_49_prim {
	v_dims: vec2<f32>,
	v_radius: vec4<f32>,
}

struct t_neo_elem_49_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_49_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_neo_elem_50_mod {
	v_height: f32,
	v_radius: vec2<f32>,
}

struct t_neo_elem_50_transform {
	v_trans: vec3<f32>,
	v_scale: f32,
	v_quat: vec4<f32>,
}

struct t_glsl_const_01 {
	v_o: f32,
}

struct t_glsl_const_00 {
	v_o: f32,
}

struct t_glsl_const_02 {
	v_o: f32,
}

struct t_glsl_const_03 {
	v_o: f32,
}

struct t_position {
	v_pos: vec3<f32>,
}
struct t_outlet {
	v_dist: f32,
}

//// INSTANCES

const u_neo_elem_00_prim: t_neo_elem_00_prim = t_neo_elem_00_prim(vec2(0.225901, 0.053881), vec4(0.007, 0.007, 0.007, 0.007));
const u_neo_elem_25_transform: t_neo_elem_25_transform = t_neo_elem_25_transform(vec3(0.134662, 0.187391, 0.000483), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_09_mod: t_neo_elem_09_mod = t_neo_elem_09_mod(f32(0.012578), vec2(0, 0));
const u_neo_elem_27_prim: t_neo_elem_27_prim = t_neo_elem_27_prim(vec2(0.009, 0.009), vec4(0.009, 0.009, 0.009, 0.009));
const u_neo_elem_01_mod: t_neo_elem_01_mod = t_neo_elem_01_mod(f32(0.195611), vec2(0, 0));
const u_neo_elem_06_transform: t_neo_elem_06_transform = t_neo_elem_06_transform(vec3(0.145374, 0.191263, -0.00911), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_16_prim: t_neo_elem_16_prim = t_neo_elem_16_prim(vec2(0.0015, 0.001379), vec4(0, 0, 0, 0));
const u_neo_elem_09_prim: t_neo_elem_09_prim = t_neo_elem_09_prim(vec2(0.040055, 0.020341), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_05_prim: t_neo_elem_05_prim = t_neo_elem_05_prim(vec2(0.060483, 0.014237), vec4(0.005, 0.005, 0.005, 0.005));
const u_neo_elem_20_transform: t_neo_elem_20_transform = t_neo_elem_20_transform(vec3(0.132572, 0.162803, -0.01478), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_14_mod: t_neo_elem_14_mod = t_neo_elem_14_mod(f32(0.005), vec2(0, 0));
const u_neo_elem_21_prim: t_neo_elem_21_prim = t_neo_elem_21_prim(vec2(0.005582, 0.006806), vec4(0, 0, 0, 0));
const u_neo_elem_02_prim: t_neo_elem_02_prim = t_neo_elem_02_prim(vec2(0.029147, 0.05396), vec4(0, 0, 0.007, 0.007));
const u_neo_elem_11_mod: t_neo_elem_11_mod = t_neo_elem_11_mod(f32(0.006289), vec2(0, 0));
const u_neo_elem_31_transform: t_neo_elem_31_transform = t_neo_elem_31_transform(vec3(-0.044504, 0.456387, 0.029843), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_08_mod: t_neo_elem_08_mod = t_neo_elem_08_mod(f32(0.003943), vec2(0, 0));
const u_neo_elem_28_prim: t_neo_elem_28_prim = t_neo_elem_28_prim(vec2(0.006, 0.006), vec4(0.006, 0.006, 0.006, 0.006));
const u_neo_elem_00_mod: t_neo_elem_00_mod = t_neo_elem_00_mod(f32(0.023198), vec2(0, 0));
const u_neo_elem_10_prim: t_neo_elem_10_prim = t_neo_elem_10_prim(vec2(0.011216, 0.018468), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_00_transform: t_neo_elem_00_transform = t_neo_elem_00_transform(vec3(0.115299, 0.22511, 0.015166), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_25_mod: t_neo_elem_25_mod = t_neo_elem_25_mod(f32(0.00189), vec2(0, 0));
const u_neo_elem_10_transform: t_neo_elem_10_transform = t_neo_elem_10_transform(vec3(0.128985, 0.396931, -0.014993), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_29_transform: t_neo_elem_29_transform = t_neo_elem_29_transform(vec3(-0.04622, 0.463375, 0.02415), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_39_prim: t_neo_elem_39_prim = t_neo_elem_39_prim(vec2(0.057666, 0.1), vec4(0, 0, 0, 0));
const u_neo_elem_02_mod: t_neo_elem_02_mod = t_neo_elem_02_mod(f32(0.096426), vec2(0, 0));
const u_neo_elem_01_prim: t_neo_elem_01_prim = t_neo_elem_01_prim(vec2(0.097367, 0.05405), vec4(0, 0, 0.002951, 0));
const u_neo_elem_10_mod: t_neo_elem_10_mod = t_neo_elem_10_mod(f32(0.006289), vec2(0, 0));
const u_neo_elem_07_prim: t_neo_elem_07_prim = t_neo_elem_07_prim(vec2(0.053668, 0.010711), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_16_mod: t_neo_elem_16_mod = t_neo_elem_16_mod(f32(0.005), vec2(0, 0));
const u_neo_elem_15_prim: t_neo_elem_15_prim = t_neo_elem_15_prim(vec2(0.0015, 0.001379), vec4(0, 0, 0, 0));
const u_neo_elem_05_transform: t_neo_elem_05_transform = t_neo_elem_05_transform(vec3(0.178868, 0.345525, 0.040074), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_01_transform: t_neo_elem_01_transform = t_neo_elem_01_transform(vec3(-0.005495, 0.195671, 0.014997), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_11_prim: t_neo_elem_11_prim = t_neo_elem_11_prim(vec2(0.011216, 0.018468), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_21_transform: t_neo_elem_21_transform = t_neo_elem_21_transform(vec3(0.134662, 0.1428, -0.015043), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_02_transform: t_neo_elem_02_transform = t_neo_elem_02_transform(vec3(-0.005294, 0.42196, 0.015087), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_12_prim: t_neo_elem_12_prim = t_neo_elem_12_prim(vec2(0.015512, 0.016), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_31_prim: t_neo_elem_31_prim = t_neo_elem_31_prim(vec2(0.030238, 0.014662), vec4(0.006, 0.006, 0.006, 0.006));
const u_neo_elem_50_prim: t_neo_elem_50_prim = t_neo_elem_50_prim(vec2(0.050813, 0.036893), vec4(0, 0, 0.036893, 0.036893));
const u_neo_elem_27_transform: t_neo_elem_27_transform = t_neo_elem_27_transform(vec3(0.14235, 0.041908, -0.006082), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_07_mod: t_neo_elem_07_mod = t_neo_elem_07_mod(f32(0.012578), vec2(0, 0));
const u_neo_elem_23_prim: t_neo_elem_23_prim = t_neo_elem_23_prim(vec2(0.005092, 0.006806), vec4(0, 0, 0, 0));
const u_neo_elem_04_prim: t_neo_elem_04_prim = t_neo_elem_04_prim(vec2(0.01055, 0.037954), vec4(0, 0, 0, 0));
const u_neo_elem_32_mod: t_neo_elem_32_mod = t_neo_elem_32_mod(f32(0.025005), vec2(0, 0));
const u_neo_elem_13_mod: t_neo_elem_13_mod = t_neo_elem_13_mod(f32(0.009012), vec2(0, 0));
const u_neo_elem_03_prim: t_neo_elem_03_prim = t_neo_elem_03_prim(vec2(0.084666, 0.037954), vec4(0, 0, 0, 0));
const u_neo_elem_12_mod: t_neo_elem_12_mod = t_neo_elem_12_mod(f32(0.004825), vec2(0, 0));
const u_neo_elem_33_prim: t_neo_elem_33_prim = t_neo_elem_33_prim(vec2(0.01, 0.01), vec4(0.01, 0.01, 0.01, 0.01));
const u_neo_elem_03_mod: t_neo_elem_03_mod = t_neo_elem_03_mod(f32(0.100629), vec2(0, 0));
const u_neo_elem_03_transform: t_neo_elem_03_transform = t_neo_elem_03_transform(vec3(0.210858, 0.361569, -0.028456), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_13_prim: t_neo_elem_13_prim = t_neo_elem_13_prim(vec2(0.002, 0.002), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_08_transform: t_neo_elem_08_transform = t_neo_elem_08_transform(vec3(0.128113, 0.412257, -0.014923), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_06_prim: t_neo_elem_06_prim = t_neo_elem_06_prim(vec2(0.055925, 0.01736), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_35_transform: t_neo_elem_35_transform = t_neo_elem_35_transform(vec3(0.069096, 0.452439, 0.034269), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_15_mod: t_neo_elem_15_mod = t_neo_elem_15_mod(f32(0.005), vec2(0, 0));
const u_neo_elem_04_mod: t_neo_elem_04_mod = t_neo_elem_04_mod(f32(0.246547), vec2(0, 0));
const u_neo_elem_04_transform: t_neo_elem_04_transform = t_neo_elem_04_transform(vec3(0.14437, 0.215652, 0.062046), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_14_prim: t_neo_elem_14_prim = t_neo_elem_14_prim(vec2(0.0015, 0.001379), vec4(0, 0, 0, 0));
const u_neo_elem_45_transform: t_neo_elem_45_transform = t_neo_elem_45_transform(vec3(-0.020941, 0.124248, 0.018937), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_24_mod: t_neo_elem_24_mod = t_neo_elem_24_mod(f32(0.023444), vec2(0, 0));
const u_neo_elem_05_mod: t_neo_elem_05_mod = t_neo_elem_05_mod(f32(0.052857), vec2(0, 0));
const u_neo_elem_26_mod: t_neo_elem_26_mod = t_neo_elem_26_mod(f32(0.004168), vec2(0, 0));
const u_neo_elem_07_transform: t_neo_elem_07_transform = t_neo_elem_07_transform(vec3(0.131834, 0.349069, 0.040993), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_17_prim: t_neo_elem_17_prim = t_neo_elem_17_prim(vec2(0.005582, 0.006742), vec4(0, 0, 0, 0));
const u_neo_elem_06_mod: t_neo_elem_06_mod = t_neo_elem_06_mod(f32(0.012578), vec2(0, 0));
const u_neo_elem_08_prim: t_neo_elem_08_prim = t_neo_elem_08_prim(vec2(0.030339, 0.020341), vec4(0.002, 0.002, 0.002, 0.002));
const u_neo_elem_17_mod: t_neo_elem_17_mod = t_neo_elem_17_mod(f32(0.00189), vec2(0, 0));
const u_neo_elem_33_transform: t_neo_elem_33_transform = t_neo_elem_33_transform(vec3(0.068959, 0.445208, 0.034506), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_18_prim: t_neo_elem_18_prim = t_neo_elem_18_prim(vec2(0.005092, 0.006806), vec4(0, 0, 0, 0));
const u_neo_elem_18_mod: t_neo_elem_18_mod = t_neo_elem_18_mod(f32(0.000576), vec2(0, 0));
const u_neo_elem_09_transform: t_neo_elem_09_transform = t_neo_elem_09_transform(vec3(0.131834, 0.307935, -0.014923), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_11_transform: t_neo_elem_11_transform = t_neo_elem_11_transform(vec3(0.128985, 0.429334, -0.014993), f32(1), vec4(0, 0, -0.707107, 0.707107));
const u_neo_elem_12_transform: t_neo_elem_12_transform = t_neo_elem_12_transform(vec3(0.130447, 0.430137, 0.046826), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_13_transform: t_neo_elem_13_transform = t_neo_elem_13_transform(vec3(0.136433, 0.430394, 0.046996), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_14_transform: t_neo_elem_14_transform = t_neo_elem_14_transform(vec3(0.139091, 0.426909, -0.015178), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_15_transform: t_neo_elem_15_transform = t_neo_elem_15_transform(vec3(0.148066, 0.303693, -0.015978), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_16_transform: t_neo_elem_16_transform = t_neo_elem_16_transform(vec3(0.139091, 0.396063, -0.015178), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_17_transform: t_neo_elem_17_transform = t_neo_elem_17_transform(vec3(0.134662, 0.187391, -0.014958), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_18_transform: t_neo_elem_18_transform = t_neo_elem_18_transform(vec3(0.134172, 0.165752, -0.014678), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_19_prim: t_neo_elem_19_prim = t_neo_elem_19_prim(vec2(0.003953, 0.006659), vec4(0, 0, 0, 0));
const u_neo_elem_19_mod: t_neo_elem_19_mod = t_neo_elem_19_mod(f32(0.004168), vec2(0, 0));
const u_neo_elem_19_transform: t_neo_elem_19_transform = t_neo_elem_19_transform(vec3(0.133401, 0.191242, -0.01491), f32(1), vec4(0, 0, 0.138355, 0.990383));
const u_neo_elem_20_prim: t_neo_elem_20_prim = t_neo_elem_20_prim(vec2(0.005868, 0.006806), vec4(0, 0, 0, 0));
const u_neo_elem_20_mod: t_neo_elem_20_mod = t_neo_elem_20_mod(f32(0.023444), vec2(0, 0));
const u_neo_elem_21_mod: t_neo_elem_21_mod = t_neo_elem_21_mod(f32(0.003441), vec2(0, 0));
const u_neo_elem_22_prim: t_neo_elem_22_prim = t_neo_elem_22_prim(vec2(0.005582, 0.006806), vec4(0, 0, 0, 0));
const u_neo_elem_22_mod: t_neo_elem_22_mod = t_neo_elem_22_mod(f32(0.003441), vec2(0, 0));
const u_neo_elem_22_transform: t_neo_elem_22_transform = t_neo_elem_22_transform(vec3(0.134662, 0.1428, 0.00053), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_23_mod: t_neo_elem_23_mod = t_neo_elem_23_mod(f32(0.000576), vec2(0, 0));
const u_neo_elem_23_transform: t_neo_elem_23_transform = t_neo_elem_23_transform(vec3(0.134172, 0.165752, 0.00053), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_40_mod: t_neo_elem_40_mod = t_neo_elem_40_mod(f32(0.027875), vec2(0, 0));
const u_neo_elem_24_prim: t_neo_elem_24_prim = t_neo_elem_24_prim(vec2(0.005868, 0.006806), vec4(0, 0, 0, 0));
const u_neo_elem_24_transform: t_neo_elem_24_transform = t_neo_elem_24_transform(vec3(0.132572, 0.162803, 0.00053), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_25_prim: t_neo_elem_25_prim = t_neo_elem_25_prim(vec2(0.005582, 0.006742), vec4(0, 0, 0, 0));
const u_neo_elem_26_prim: t_neo_elem_26_prim = t_neo_elem_26_prim(vec2(0.003953, 0.006659), vec4(0, 0, 0, 0));
const u_neo_elem_39_mod: t_neo_elem_39_mod = t_neo_elem_39_mod(f32(0.038795), vec2(0, 0));
const u_neo_elem_26_transform: t_neo_elem_26_transform = t_neo_elem_26_transform(vec3(0.133401, 0.191242, 0.000549), f32(1), vec4(0, 0, 0.138355, 0.990383));
const u_neo_elem_27_mod: t_neo_elem_27_mod = t_neo_elem_27_mod(f32(0.010516), vec2(0, 0));
const u_neo_elem_28_mod: t_neo_elem_28_mod = t_neo_elem_28_mod(f32(0.005258), vec2(0, 0));
const u_neo_elem_28_transform: t_neo_elem_28_transform = t_neo_elem_28_transform(vec3(0.131714, 0.042185, -0.005774), f32(1), vec4(0, 0, 0.707107, 0.707107));
const u_neo_elem_29_prim: t_neo_elem_29_prim = t_neo_elem_29_prim(vec2(0.036017, 0.022341), vec4(0.006, 0.005898, 0.006, 0.006));
const u_neo_elem_29_mod: t_neo_elem_29_mod = t_neo_elem_29_mod(f32(0.024845), vec2(0, 0));
const u_neo_elem_30_prim: t_neo_elem_30_prim = t_neo_elem_30_prim(vec2(0.01, 0.01), vec4(0.01, 0.01, 0.01, 0.01));
const u_neo_elem_30_mod: t_neo_elem_30_mod = t_neo_elem_30_mod(f32(0.007244), vec2(0, 0));
const u_neo_elem_34_mod: t_neo_elem_34_mod = t_neo_elem_34_mod(f32(0.019871), vec2(0, 0));
const u_neo_elem_30_transform: t_neo_elem_30_transform = t_neo_elem_30_transform(vec3(0.039921, 0.445096, 0.034506), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_31_mod: t_neo_elem_31_mod = t_neo_elem_31_mod(f32(0.014486), vec2(0, 0));
const u_neo_elem_32_prim: t_neo_elem_32_prim = t_neo_elem_32_prim(vec2(0.005, 0.005), vec4(0.005, 0.005, 0.005, 0.005));
const u_neo_elem_32_transform: t_neo_elem_32_transform = t_neo_elem_32_transform(vec3(0.065096, 0.477378, 0.034473), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_33_mod: t_neo_elem_33_mod = t_neo_elem_33_mod(f32(0.007244), vec2(0, 0));
const u_neo_elem_34_prim: t_neo_elem_34_prim = t_neo_elem_34_prim(vec2(0.005, 0.005), vec4(0.005, 0.005, 0.005, 0.005));
const u_neo_elem_34_transform: t_neo_elem_34_transform = t_neo_elem_34_transform(vec3(0.0398, 0.465017, 0.03446), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_42_transform: t_neo_elem_42_transform = t_neo_elem_42_transform(vec3(-0.021067, 0.245674, 0.022761), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_35_prim: t_neo_elem_35_prim = t_neo_elem_35_prim(vec2(0.005, 0.005), vec4(0.005, 0.005, 0.005, 0.005));
const u_neo_elem_35_mod: t_neo_elem_35_mod = t_neo_elem_35_mod(f32(0.007244), vec2(0, 0));
const u_neo_elem_36_prim: t_neo_elem_36_prim = t_neo_elem_36_prim(vec2(0.045169, 0.120091), vec4(0.007, 0.007, 0.007, 0.007));
const u_neo_elem_36_mod: t_neo_elem_36_mod = t_neo_elem_36_mod(f32(0.1), vec2(0, 0));
const u_neo_elem_36_transform: t_neo_elem_36_transform = t_neo_elem_36_transform(vec3(-0.018869, 0.196035, 0.120649), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_37_prim: t_neo_elem_37_prim = t_neo_elem_37_prim(f32(1.661), f32(0.151), f32(0), f32(0.204), f32(0), f32(0.002));
const u_neo_elem_37_mod: t_neo_elem_37_mod = t_neo_elem_37_mod(f32(0.01), vec2(0, 0));
const u_neo_elem_37_transform: t_neo_elem_37_transform = t_neo_elem_37_transform(vec3(-0.19624, 0.482427, -0.087609), f32(1), vec4(0.554221, 0.439135, -0.439135, 0.554221));
const u_neo_elem_38_prim: t_neo_elem_38_prim = t_neo_elem_38_prim(vec2(0.050813, 0.036893), vec4(0, 0, 0.036893, 0.036893));
const u_neo_elem_38_mod: t_neo_elem_38_mod = t_neo_elem_38_mod(f32(0.014154), vec2(0, 0));
const u_neo_elem_38_transform: t_neo_elem_38_transform = t_neo_elem_38_transform(vec3(-0.248233, 0.106823, 0.043405), f32(1), vec4(0.5, 0.5, 0.5, 0.5));
const u_neo_elem_39_transform: t_neo_elem_39_transform = t_neo_elem_39_transform(vec3(-0.313197, 0.122007, 0), f32(1), vec4(0, 0, 0.382683, 0.92388));
const u_neo_elem_40_prim: t_neo_elem_40_prim = t_neo_elem_40_prim(vec2(0.041043, 0.029836), vec4(0, 0, 0, 0));
const u_neo_elem_40_transform: t_neo_elem_40_transform = t_neo_elem_40_transform(vec3(-0.286186, 0.163433, 0.045437), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_41_prim: t_neo_elem_41_prim = t_neo_elem_41_prim(vec2(0.064376, 0.064376), vec4(0.064376, 0.064376, 0.064376, 0.064376));
const u_neo_elem_41_mod: t_neo_elem_41_mod = t_neo_elem_41_mod(f32(0.023381), vec2(0.011, 0.006));
const u_neo_elem_41_transform: t_neo_elem_41_transform = t_neo_elem_41_transform(vec3(-0.189083, 0.090754, -0.185421), f32(1), vec4(0.700772, -0.09444, 0.09444, 0.700772));
const u_neo_elem_42_prim: t_neo_elem_42_prim = t_neo_elem_42_prim(vec2(0.011097, 0.011097), vec4(0.011097, 0.011097, 0.011097, 0.011097));
const u_neo_elem_42_mod: t_neo_elem_42_mod = t_neo_elem_42_mod(f32(0.007642), vec2(0, 0));
const u_neo_elem_43_prim: t_neo_elem_43_prim = t_neo_elem_43_prim(vec2(0.020947, 0.020947), vec4(0.020947, 0.020947, 0.020947, 0.020947));
const u_neo_elem_43_mod: t_neo_elem_43_mod = t_neo_elem_43_mod(f32(0.010375), vec2(0, 0));
const u_neo_elem_43_transform: t_neo_elem_43_transform = t_neo_elem_43_transform(vec3(-0.246298, 0.092291, 0.063316), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_44_prim: t_neo_elem_44_prim = t_neo_elem_44_prim(vec2(0.013248, 0.013248), vec4(0.013248, 0.013248, 0.013248, 0.013248));
const u_neo_elem_44_mod: t_neo_elem_44_mod = t_neo_elem_44_mod(f32(0.007642), vec2(0, 0));
const u_neo_elem_44_transform: t_neo_elem_44_transform = t_neo_elem_44_transform(vec3(-0.020941, 0.245991, 0.018937), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_45_prim: t_neo_elem_45_prim = t_neo_elem_45_prim(vec2(0.013248, 0.013248), vec4(0.013248, 0.013248, 0.013248, 0.013248));
const u_neo_elem_45_mod: t_neo_elem_45_mod = t_neo_elem_45_mod(f32(0.007642), vec2(0, 0));
const u_neo_elem_46_prim: t_neo_elem_46_prim = t_neo_elem_46_prim(vec2(0.011097, 0.011097), vec4(0.011097, 0.011097, 0.011097, 0.011097));
const u_neo_elem_46_mod: t_neo_elem_46_mod = t_neo_elem_46_mod(f32(0.007642), vec2(0, 0));
const u_neo_elem_46_transform: t_neo_elem_46_transform = t_neo_elem_46_transform(vec3(-0.021067, 0.123851, 0.022761), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_47_prim: t_neo_elem_47_prim = t_neo_elem_47_prim(vec2(0.027889, 0.037782), vec4(0, 0, 0.009, 0.009));
const u_neo_elem_47_mod: t_neo_elem_47_mod = t_neo_elem_47_mod(f32(0.010033), vec2(0, 0));
const u_neo_elem_47_transform: t_neo_elem_47_transform = t_neo_elem_47_transform(vec3(-0.021018, 0.185732, 0.012405), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_48_prim: t_neo_elem_48_prim = t_neo_elem_48_prim(vec2(0.096925, 0.055305), vec4(0, 0, 0, 0));
const u_neo_elem_48_mod: t_neo_elem_48_mod = t_neo_elem_48_mod(f32(0.000416), vec2(0, 0));
const u_neo_elem_48_transform: t_neo_elem_48_transform = t_neo_elem_48_transform(vec3(-0.005067, 0.391951, 0.014533), f32(1), vec4(0, 0, 0, 1));
const u_neo_elem_49_prim: t_neo_elem_49_prim = t_neo_elem_49_prim(vec2(0.064376, 0.064376), vec4(0.064376, 0.064376, 0.064376, 0.064376));
const u_neo_elem_49_mod: t_neo_elem_49_mod = t_neo_elem_49_mod(f32(0.023381), vec2(0.011, 0.006));
const u_neo_elem_49_transform: t_neo_elem_49_transform = t_neo_elem_49_transform(vec3(-0.248355, 0.086614, 0.00513), f32(1), vec4(0.707107, 0, 0, 0.707107));
const u_neo_elem_50_mod: t_neo_elem_50_mod = t_neo_elem_50_mod(f32(0.014154), vec2(0, 0));
const u_neo_elem_50_transform: t_neo_elem_50_transform = t_neo_elem_50_transform(vec3(-0.179559, 0.0979, -0.222403), f32(1), vec4(0.421041, 0.421041, 0.568088, 0.568088));

const c_glsl_const_01: t_glsl_const_01 = t_glsl_const_01(f32(2));
const c_glsl_const_00: t_glsl_const_00 = t_glsl_const_00(f32(0));
const c_glsl_const_02: t_glsl_const_02 = t_glsl_const_02(f32(1));
const c_glsl_const_03: t_glsl_const_03 = t_glsl_const_03(f32(1000));

//// IMPLEMENTATIONS

// FID[0381] ComposeFuncType::Terminal main:(v3 pos)->(sc dist)
// FID[0380] ComposeFuncType::Inlet position:()->(v3 pos)
// FID[0378] ComposeFuncType::Outlet outlet:(sc dist)->()
fn compute_main_digraph(a_pos: vec3<f32>) -> t_outlet {
	let tmp3932: t_neo_elem_01_prim = u_neo_elem_01_prim;
	let tmp3855: t_neo_elem_00_prim = u_neo_elem_00_prim;
	let tmp4533: vec3<f32> = (((((((((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))))))))))))))))));
	let tmp4034: vec4<f32> = (u_neo_elem_00_transform.v_quat);
	let tmp3964: vec4<f32> = (u_neo_elem_01_transform.v_quat);
	let tmp3852: vec4<f32> = (tmp3855.v_radius);
	let tmp3931: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp3964.w) / length(tmp3964)) * ((tmp3964.w) / length(tmp3964))) + (((tmp3964.x) / length(tmp3964)) * ((tmp3964.x) / length(tmp3964))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))) - (((tmp3964.w) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) + (((tmp3964.w) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))) + (((tmp3964.w) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))))), ((c_glsl_const_01.v_o * ((((tmp3964.w) / length(tmp3964)) * ((tmp3964.w) / length(tmp3964))) + (((tmp3964.y) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp3964.y) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) - (((tmp3964.w) / length(tmp3964)) * ((tmp3964.x) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) - (((tmp3964.w) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.y) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) + (((tmp3964.w) / length(tmp3964)) * ((tmp3964.x) / length(tmp3964))))), ((c_glsl_const_01.v_o * ((((tmp3964.w) / length(tmp3964)) * ((tmp3964.w) / length(tmp3964))) + (((tmp3964.z) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))))) - c_glsl_const_02.v_o)) * (((((((tmp4533))) - (u_neo_elem_01_transform.v_trans))) / vec3<f32>((u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp3964.w) / length(tmp3964)) * ((tmp3964.w) / length(tmp3964))) + (((tmp3964.x) / length(tmp3964)) * ((tmp3964.x) / length(tmp3964))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))) - (((tmp3964.w) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) + (((tmp3964.w) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))) + (((tmp3964.w) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))))), ((c_glsl_const_01.v_o * ((((tmp3964.w) / length(tmp3964)) * ((tmp3964.w) / length(tmp3964))) + (((tmp3964.y) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp3964.y) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) - (((tmp3964.w) / length(tmp3964)) * ((tmp3964.x) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.x) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) - (((tmp3964.w) / length(tmp3964)) * ((tmp3964.y) / length(tmp3964))))), (c_glsl_const_01.v_o * ((((tmp3964.y) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))) + (((tmp3964.w) / length(tmp3964)) * ((tmp3964.x) / length(tmp3964))))), ((c_glsl_const_01.v_o * ((((tmp3964.w) / length(tmp3964)) * ((tmp3964.w) / length(tmp3964))) + (((tmp3964.z) / length(tmp3964)) * ((tmp3964.z) / length(tmp3964))))) - c_glsl_const_02.v_o)) * (((((((tmp4533))) - (u_neo_elem_01_transform.v_trans))) / vec3<f32>((u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale), (u_neo_elem_01_transform.v_scale))))).z));
	let tmp3854: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4034.w) / length(tmp4034)) * ((tmp4034.w) / length(tmp4034))) + (((tmp4034.x) / length(tmp4034)) * ((tmp4034.x) / length(tmp4034))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))) - (((tmp4034.w) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) + (((tmp4034.w) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))) + (((tmp4034.w) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))))), ((c_glsl_const_01.v_o * ((((tmp4034.w) / length(tmp4034)) * ((tmp4034.w) / length(tmp4034))) + (((tmp4034.y) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4034.y) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) - (((tmp4034.w) / length(tmp4034)) * ((tmp4034.x) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) - (((tmp4034.w) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.y) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) + (((tmp4034.w) / length(tmp4034)) * ((tmp4034.x) / length(tmp4034))))), ((c_glsl_const_01.v_o * ((((tmp4034.w) / length(tmp4034)) * ((tmp4034.w) / length(tmp4034))) + (((tmp4034.z) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))))) - c_glsl_const_02.v_o)) * (((((((tmp4533))) - (u_neo_elem_00_transform.v_trans))) / vec3<f32>((u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4034.w) / length(tmp4034)) * ((tmp4034.w) / length(tmp4034))) + (((tmp4034.x) / length(tmp4034)) * ((tmp4034.x) / length(tmp4034))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))) - (((tmp4034.w) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) + (((tmp4034.w) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))) + (((tmp4034.w) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))))), ((c_glsl_const_01.v_o * ((((tmp4034.w) / length(tmp4034)) * ((tmp4034.w) / length(tmp4034))) + (((tmp4034.y) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4034.y) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) - (((tmp4034.w) / length(tmp4034)) * ((tmp4034.x) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.x) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) - (((tmp4034.w) / length(tmp4034)) * ((tmp4034.y) / length(tmp4034))))), (c_glsl_const_01.v_o * ((((tmp4034.y) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))) + (((tmp4034.w) / length(tmp4034)) * ((tmp4034.x) / length(tmp4034))))), ((c_glsl_const_01.v_o * ((((tmp4034.w) / length(tmp4034)) * ((tmp4034.w) / length(tmp4034))) + (((tmp4034.z) / length(tmp4034)) * ((tmp4034.z) / length(tmp4034))))) - c_glsl_const_02.v_o)) * (((((((tmp4533))) - (u_neo_elem_00_transform.v_trans))) / vec3<f32>((u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale), (u_neo_elem_00_transform.v_scale))))).z));
	let tmp3929: vec4<f32> = (tmp3932.v_radius);
	let tmp4035: f32 = length(tmp4034);
	let tmp3778: t_neo_elem_02_prim = u_neo_elem_02_prim;
	let tmp4622: vec3<f32> = ((((((((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))))))))))))))))));
	let tmp3965: f32 = length(tmp3964);
	let tmp4104: vec4<f32> = (u_neo_elem_02_transform.v_quat);
	let tmp4712: vec3<f32> = (((((((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))))))))))))))));
	let tmp3968: f32 = ((tmp3964.w) / tmp3965);
	let tmp3977: f32 = ((tmp3964.z) / tmp3965);
	let tmp3974: f32 = ((tmp3964.y) / tmp3965);
	let tmp3701: t_neo_elem_03_prim = u_neo_elem_03_prim;
	let tmp3777: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4104.w) / length(tmp4104)) * ((tmp4104.w) / length(tmp4104))) + (((tmp4104.x) / length(tmp4104)) * ((tmp4104.x) / length(tmp4104))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))) - (((tmp4104.w) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) + (((tmp4104.w) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))) + (((tmp4104.w) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))))), ((c_glsl_const_01.v_o * ((((tmp4104.w) / length(tmp4104)) * ((tmp4104.w) / length(tmp4104))) + (((tmp4104.y) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4104.y) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) - (((tmp4104.w) / length(tmp4104)) * ((tmp4104.x) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) - (((tmp4104.w) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.y) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) + (((tmp4104.w) / length(tmp4104)) * ((tmp4104.x) / length(tmp4104))))), ((c_glsl_const_01.v_o * ((((tmp4104.w) / length(tmp4104)) * ((tmp4104.w) / length(tmp4104))) + (((tmp4104.z) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))))) - c_glsl_const_02.v_o)) * (((((((tmp4622))) - (u_neo_elem_02_transform.v_trans))) / vec3<f32>((u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4104.w) / length(tmp4104)) * ((tmp4104.w) / length(tmp4104))) + (((tmp4104.x) / length(tmp4104)) * ((tmp4104.x) / length(tmp4104))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))) - (((tmp4104.w) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) + (((tmp4104.w) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))) + (((tmp4104.w) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))))), ((c_glsl_const_01.v_o * ((((tmp4104.w) / length(tmp4104)) * ((tmp4104.w) / length(tmp4104))) + (((tmp4104.y) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4104.y) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) - (((tmp4104.w) / length(tmp4104)) * ((tmp4104.x) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.x) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) - (((tmp4104.w) / length(tmp4104)) * ((tmp4104.y) / length(tmp4104))))), (c_glsl_const_01.v_o * ((((tmp4104.y) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))) + (((tmp4104.w) / length(tmp4104)) * ((tmp4104.x) / length(tmp4104))))), ((c_glsl_const_01.v_o * ((((tmp4104.w) / length(tmp4104)) * ((tmp4104.w) / length(tmp4104))) + (((tmp4104.z) / length(tmp4104)) * ((tmp4104.z) / length(tmp4104))))) - c_glsl_const_02.v_o)) * (((((((tmp4622))) - (u_neo_elem_02_transform.v_trans))) / vec3<f32>((u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale), (u_neo_elem_02_transform.v_scale))))).z));
	let tmp3822: vec2<f32> = ((abs(tmp3854) - (tmp3855.v_dims)) + vec2<f32>(mix(mix((tmp3852.w), (tmp3852.y), step(c_glsl_const_00.v_o, (tmp3854.x))), mix((tmp3852.z), (tmp3852.x), step(c_glsl_const_00.v_o, (tmp3854.x))), step(c_glsl_const_00.v_o, (tmp3854.y))), mix(mix((tmp3852.w), (tmp3852.y), step(c_glsl_const_00.v_o, (tmp3854.x))), mix((tmp3852.z), (tmp3852.x), step(c_glsl_const_00.v_o, (tmp3854.x))), step(c_glsl_const_00.v_o, (tmp3854.y)))));
	let tmp3971: f32 = ((tmp3964.x) / tmp3965);
	let tmp4047: f32 = ((tmp4034.z) / tmp4035);
	let tmp3899: vec2<f32> = ((abs(tmp3931) - (tmp3932.v_dims)) + vec2<f32>(mix(mix((tmp3929.w), (tmp3929.y), step(c_glsl_const_00.v_o, (tmp3931.x))), mix((tmp3929.z), (tmp3929.x), step(c_glsl_const_00.v_o, (tmp3931.x))), step(c_glsl_const_00.v_o, (tmp3931.y))), mix(mix((tmp3929.w), (tmp3929.y), step(c_glsl_const_00.v_o, (tmp3931.x))), mix((tmp3929.z), (tmp3929.x), step(c_glsl_const_00.v_o, (tmp3931.x))), step(c_glsl_const_00.v_o, (tmp3931.y)))));
	let tmp4041: f32 = ((tmp4034.x) / tmp4035);
	let tmp4038: f32 = ((tmp4034.w) / tmp4035);
	let tmp4044: f32 = ((tmp4034.y) / tmp4035);
	let tmp3775: vec4<f32> = (tmp3778.v_radius);
	let tmp4181: f32 = (u_neo_elem_00_transform.v_scale);
	let tmp3698: vec4<f32> = (tmp3701.v_radius);
	let tmp4105: f32 = length(tmp4104);
	let tmp4188: vec4<f32> = (u_neo_elem_03_transform.v_quat);
	let tmp3700: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4188.w) / length(tmp4188)) * ((tmp4188.w) / length(tmp4188))) + (((tmp4188.x) / length(tmp4188)) * ((tmp4188.x) / length(tmp4188))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))) - (((tmp4188.w) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) + (((tmp4188.w) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))) + (((tmp4188.w) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))))), ((c_glsl_const_01.v_o * ((((tmp4188.w) / length(tmp4188)) * ((tmp4188.w) / length(tmp4188))) + (((tmp4188.y) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4188.y) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) - (((tmp4188.w) / length(tmp4188)) * ((tmp4188.x) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) - (((tmp4188.w) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.y) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) + (((tmp4188.w) / length(tmp4188)) * ((tmp4188.x) / length(tmp4188))))), ((c_glsl_const_01.v_o * ((((tmp4188.w) / length(tmp4188)) * ((tmp4188.w) / length(tmp4188))) + (((tmp4188.z) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))))) - c_glsl_const_02.v_o)) * (((((((tmp4712))) - (u_neo_elem_03_transform.v_trans))) / vec3<f32>((u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4188.w) / length(tmp4188)) * ((tmp4188.w) / length(tmp4188))) + (((tmp4188.x) / length(tmp4188)) * ((tmp4188.x) / length(tmp4188))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))) - (((tmp4188.w) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) + (((tmp4188.w) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))) + (((tmp4188.w) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))))), ((c_glsl_const_01.v_o * ((((tmp4188.w) / length(tmp4188)) * ((tmp4188.w) / length(tmp4188))) + (((tmp4188.y) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4188.y) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) - (((tmp4188.w) / length(tmp4188)) * ((tmp4188.x) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.x) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) - (((tmp4188.w) / length(tmp4188)) * ((tmp4188.y) / length(tmp4188))))), (c_glsl_const_01.v_o * ((((tmp4188.y) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))) + (((tmp4188.w) / length(tmp4188)) * ((tmp4188.x) / length(tmp4188))))), ((c_glsl_const_01.v_o * ((((tmp4188.w) / length(tmp4188)) * ((tmp4188.w) / length(tmp4188))) + (((tmp4188.z) / length(tmp4188)) * ((tmp4188.z) / length(tmp4188))))) - c_glsl_const_02.v_o)) * (((((((tmp4712))) - (u_neo_elem_03_transform.v_trans))) / vec3<f32>((u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale), (u_neo_elem_03_transform.v_scale))))).z));
	let tmp4174: f32 = (u_neo_elem_01_transform.v_scale);
	let tmp3745: vec2<f32> = ((abs(tmp3777) - (tmp3778.v_dims)) + vec2<f32>(mix(mix((tmp3775.w), (tmp3775.y), step(c_glsl_const_00.v_o, (tmp3777.x))), mix((tmp3775.z), (tmp3775.x), step(c_glsl_const_00.v_o, (tmp3777.x))), step(c_glsl_const_00.v_o, (tmp3777.y))), mix(mix((tmp3775.w), (tmp3775.y), step(c_glsl_const_00.v_o, (tmp3777.x))), mix((tmp3775.z), (tmp3775.x), step(c_glsl_const_00.v_o, (tmp3777.x))), step(c_glsl_const_00.v_o, (tmp3777.y)))));
	let tmp4108: f32 = ((tmp4104.w) / tmp4105);
	let tmp3624: t_neo_elem_04_prim = u_neo_elem_04_prim;
	let tmp4111: f32 = ((tmp4104.x) / tmp4105);
	let tmp4189: f32 = length(tmp4188);
	let tmp4114: f32 = ((tmp4104.y) / tmp4105);
	let tmp4117: f32 = ((tmp4104.z) / tmp4105);
	let tmp3903: f32 = mix(mix((tmp3929.w), (tmp3929.y), step(c_glsl_const_00.v_o, (tmp3931.x))), mix((tmp3929.z), (tmp3929.x), step(c_glsl_const_00.v_o, (tmp3931.x))), step(c_glsl_const_00.v_o, (tmp3931.y)));
	let tmp4802: vec3<f32> = ((((((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))))))))))))))));
	let tmp3826: f32 = mix(mix((tmp3852.w), (tmp3852.y), step(c_glsl_const_00.v_o, (tmp3854.x))), mix((tmp3852.z), (tmp3852.x), step(c_glsl_const_00.v_o, (tmp3854.x))), step(c_glsl_const_00.v_o, (tmp3854.y)));
	let tmp4275: vec4<f32> = (u_neo_elem_04_transform.v_quat);
	let tmp3623: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4275.w) / length(tmp4275)) * ((tmp4275.w) / length(tmp4275))) + (((tmp4275.x) / length(tmp4275)) * ((tmp4275.x) / length(tmp4275))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))) - (((tmp4275.w) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) + (((tmp4275.w) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))) + (((tmp4275.w) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))))), ((c_glsl_const_01.v_o * ((((tmp4275.w) / length(tmp4275)) * ((tmp4275.w) / length(tmp4275))) + (((tmp4275.y) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4275.y) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) - (((tmp4275.w) / length(tmp4275)) * ((tmp4275.x) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) - (((tmp4275.w) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.y) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) + (((tmp4275.w) / length(tmp4275)) * ((tmp4275.x) / length(tmp4275))))), ((c_glsl_const_01.v_o * ((((tmp4275.w) / length(tmp4275)) * ((tmp4275.w) / length(tmp4275))) + (((tmp4275.z) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))))) - c_glsl_const_02.v_o)) * (((((((tmp4802))) - (u_neo_elem_04_transform.v_trans))) / vec3<f32>((u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4275.w) / length(tmp4275)) * ((tmp4275.w) / length(tmp4275))) + (((tmp4275.x) / length(tmp4275)) * ((tmp4275.x) / length(tmp4275))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))) - (((tmp4275.w) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) + (((tmp4275.w) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))) + (((tmp4275.w) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))))), ((c_glsl_const_01.v_o * ((((tmp4275.w) / length(tmp4275)) * ((tmp4275.w) / length(tmp4275))) + (((tmp4275.y) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4275.y) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) - (((tmp4275.w) / length(tmp4275)) * ((tmp4275.x) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.x) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) - (((tmp4275.w) / length(tmp4275)) * ((tmp4275.y) / length(tmp4275))))), (c_glsl_const_01.v_o * ((((tmp4275.y) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))) + (((tmp4275.w) / length(tmp4275)) * ((tmp4275.x) / length(tmp4275))))), ((c_glsl_const_01.v_o * ((((tmp4275.w) / length(tmp4275)) * ((tmp4275.w) / length(tmp4275))) + (((tmp4275.z) / length(tmp4275)) * ((tmp4275.z) / length(tmp4275))))) - c_glsl_const_02.v_o)) * (((((((tmp4802))) - (u_neo_elem_04_transform.v_trans))) / vec3<f32>((u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale), (u_neo_elem_04_transform.v_scale))))).z));
	let tmp3621: vec4<f32> = (tmp3624.v_radius);
	let tmp4201: f32 = ((tmp4188.z) / tmp4189);
	let tmp4195: f32 = ((tmp4188.x) / tmp4189);
	let tmp4258: f32 = (u_neo_elem_02_transform.v_scale);
	let tmp4192: f32 = ((tmp4188.w) / tmp4189);
	let tmp3668: vec2<f32> = ((abs(tmp3700) - (tmp3701.v_dims)) + vec2<f32>(mix(mix((tmp3698.w), (tmp3698.y), step(c_glsl_const_00.v_o, (tmp3700.x))), mix((tmp3698.z), (tmp3698.x), step(c_glsl_const_00.v_o, (tmp3700.x))), step(c_glsl_const_00.v_o, (tmp3700.y))), mix(mix((tmp3698.w), (tmp3698.y), step(c_glsl_const_00.v_o, (tmp3700.x))), mix((tmp3698.z), (tmp3698.x), step(c_glsl_const_00.v_o, (tmp3700.x))), step(c_glsl_const_00.v_o, (tmp3700.y)))));
	let tmp4198: f32 = ((tmp4188.y) / tmp4189);
	let tmp4345: f32 = (u_neo_elem_03_transform.v_scale);
	let tmp4276: f32 = length(tmp4275);
	let tmp4892: vec3<f32> = (((((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))))))))))))));
	let tmp3547: t_neo_elem_05_prim = u_neo_elem_05_prim;
	let tmp3749: f32 = mix(mix((tmp3775.w), (tmp3775.y), step(c_glsl_const_00.v_o, (tmp3777.x))), mix((tmp3775.z), (tmp3775.x), step(c_glsl_const_00.v_o, (tmp3777.x))), step(c_glsl_const_00.v_o, (tmp3777.y)));
	let tmp3546: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp4892))) - (u_neo_elem_05_transform.v_trans))) / vec3<f32>((u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) - ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).y) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).x) / length((u_neo_elem_05_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).w) / length((u_neo_elem_05_transform.v_quat)))) + ((((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat))) * (((u_neo_elem_05_transform.v_quat).z) / length((u_neo_elem_05_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp4892))) - (u_neo_elem_05_transform.v_trans))) / vec3<f32>((u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale), (u_neo_elem_05_transform.v_scale))))).z));
	let tmp3885: t_neo_elem_00_mod = u_neo_elem_00_mod;
	let tmp4282: f32 = ((tmp4275.x) / tmp4276);
	let tmp4279: f32 = ((tmp4275.w) / tmp4276);
	let tmp3962: t_neo_elem_01_mod = u_neo_elem_01_mod;
	let tmp4288: f32 = ((tmp4275.z) / tmp4276);
	let tmp4361: vec4<f32> = (u_neo_elem_05_transform.v_quat);
	let tmp3672: f32 = mix(mix((tmp3698.w), (tmp3698.y), step(c_glsl_const_00.v_o, (tmp3700.x))), mix((tmp3698.z), (tmp3698.x), step(c_glsl_const_00.v_o, (tmp3700.x))), step(c_glsl_const_00.v_o, (tmp3700.y)));
	let tmp4285: f32 = ((tmp4275.y) / tmp4276);
	let tmp3591: vec2<f32> = ((abs(tmp3623) - (tmp3624.v_dims)) + vec2<f32>(mix(mix((tmp3621.w), (tmp3621.y), step(c_glsl_const_00.v_o, (tmp3623.x))), mix((tmp3621.z), (tmp3621.x), step(c_glsl_const_00.v_o, (tmp3623.x))), step(c_glsl_const_00.v_o, (tmp3623.y))), mix(mix((tmp3621.w), (tmp3621.y), step(c_glsl_const_00.v_o, (tmp3623.x))), mix((tmp3621.z), (tmp3621.x), step(c_glsl_const_00.v_o, (tmp3623.x))), step(c_glsl_const_00.v_o, (tmp3623.y)))));
	let tmp3544: vec4<f32> = (tmp3547.v_radius);
	let tmp3881: vec2<f32> = (tmp3885.v_radius);
	let tmp3886: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp3968 * tmp3968) + (tmp3971 * tmp3971))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp3971 * tmp3974) - (tmp3968 * tmp3977))), (c_glsl_const_01.v_o * ((tmp3971 * tmp3977) + (tmp3968 * tmp3974))), (c_glsl_const_01.v_o * ((tmp3971 * tmp3974) + (tmp3968 * tmp3977))), ((c_glsl_const_01.v_o * ((tmp3968 * tmp3968) + (tmp3974 * tmp3974))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp3974 * tmp3977) - (tmp3968 * tmp3971))), (c_glsl_const_01.v_o * ((tmp3971 * tmp3977) - (tmp3968 * tmp3974))), (c_glsl_const_01.v_o * ((tmp3974 * tmp3977) + (tmp3968 * tmp3971))), ((c_glsl_const_01.v_o * ((tmp3968 * tmp3968) + (tmp3977 * tmp3977))) - c_glsl_const_02.v_o)) * (((((((tmp4533))) - (u_neo_elem_01_transform.v_trans))) / vec3<f32>(tmp4174, tmp4174, tmp4174))));
	let tmp4362: f32 = length(tmp4361);
	let tmp3809: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4038 * tmp4038) + (tmp4041 * tmp4041))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4041 * tmp4044) - (tmp4038 * tmp4047))), (c_glsl_const_01.v_o * ((tmp4041 * tmp4047) + (tmp4038 * tmp4044))), (c_glsl_const_01.v_o * ((tmp4041 * tmp4044) + (tmp4038 * tmp4047))), ((c_glsl_const_01.v_o * ((tmp4038 * tmp4038) + (tmp4044 * tmp4044))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4044 * tmp4047) - (tmp4038 * tmp4041))), (c_glsl_const_01.v_o * ((tmp4041 * tmp4047) - (tmp4038 * tmp4044))), (c_glsl_const_01.v_o * ((tmp4044 * tmp4047) + (tmp4038 * tmp4041))), ((c_glsl_const_01.v_o * ((tmp4038 * tmp4038) + (tmp4047 * tmp4047))) - c_glsl_const_02.v_o)) * (((((((tmp4533))) - (u_neo_elem_00_transform.v_trans))) / vec3<f32>(tmp4181, tmp4181, tmp4181))));
	let tmp4431: f32 = (u_neo_elem_04_transform.v_scale);
	let tmp4982: vec3<f32> = ((((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))))))))))))));
	let tmp3958: vec2<f32> = (tmp3962.v_radius);
	let tmp3470: t_neo_elem_06_prim = u_neo_elem_06_prim;
	let tmp4371: f32 = ((tmp4361.y) / tmp4362);
	let tmp4374: f32 = ((tmp4361.z) / tmp4362);
	let tmp3883: f32 = (tmp3809.y);
	let tmp4450: vec4<f32> = (u_neo_elem_06_transform.v_quat);
	let tmp3467: vec4<f32> = (tmp3470.v_radius);
	let tmp3469: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4450.w) / length(tmp4450)) * ((tmp4450.w) / length(tmp4450))) + (((tmp4450.x) / length(tmp4450)) * ((tmp4450.x) / length(tmp4450))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))) - (((tmp4450.w) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) + (((tmp4450.w) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))) + (((tmp4450.w) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))))), ((c_glsl_const_01.v_o * ((((tmp4450.w) / length(tmp4450)) * ((tmp4450.w) / length(tmp4450))) + (((tmp4450.y) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4450.y) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) - (((tmp4450.w) / length(tmp4450)) * ((tmp4450.x) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) - (((tmp4450.w) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.y) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) + (((tmp4450.w) / length(tmp4450)) * ((tmp4450.x) / length(tmp4450))))), ((c_glsl_const_01.v_o * ((((tmp4450.w) / length(tmp4450)) * ((tmp4450.w) / length(tmp4450))) + (((tmp4450.z) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))))) - c_glsl_const_02.v_o)) * (((((((tmp4982))) - (u_neo_elem_06_transform.v_trans))) / vec3<f32>((u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4450.w) / length(tmp4450)) * ((tmp4450.w) / length(tmp4450))) + (((tmp4450.x) / length(tmp4450)) * ((tmp4450.x) / length(tmp4450))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))) - (((tmp4450.w) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) + (((tmp4450.w) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))) + (((tmp4450.w) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))))), ((c_glsl_const_01.v_o * ((((tmp4450.w) / length(tmp4450)) * ((tmp4450.w) / length(tmp4450))) + (((tmp4450.y) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4450.y) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) - (((tmp4450.w) / length(tmp4450)) * ((tmp4450.x) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.x) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) - (((tmp4450.w) / length(tmp4450)) * ((tmp4450.y) / length(tmp4450))))), (c_glsl_const_01.v_o * ((((tmp4450.y) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))) + (((tmp4450.w) / length(tmp4450)) * ((tmp4450.x) / length(tmp4450))))), ((c_glsl_const_01.v_o * ((((tmp4450.w) / length(tmp4450)) * ((tmp4450.w) / length(tmp4450))) + (((tmp4450.z) / length(tmp4450)) * ((tmp4450.z) / length(tmp4450))))) - c_glsl_const_02.v_o)) * (((((((tmp4982))) - (u_neo_elem_06_transform.v_trans))) / vec3<f32>((u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale), (u_neo_elem_06_transform.v_scale))))).z));
	let tmp3960: f32 = (tmp3886.y);
	let tmp3595: f32 = mix(mix((tmp3621.w), (tmp3621.y), step(c_glsl_const_00.v_o, (tmp3623.x))), mix((tmp3621.z), (tmp3621.x), step(c_glsl_const_00.v_o, (tmp3623.x))), step(c_glsl_const_00.v_o, (tmp3623.y)));
	let tmp3867: vec2<f32> = vec2<f32>((((min(max((tmp3822.x), (tmp3822.y)), c_glsl_const_00.v_o) + (length(max(tmp3822, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3826))) + mix((tmp3881.y), (tmp3881.x), step(c_glsl_const_00.v_o, tmp3883))), (abs(tmp3883) - (tmp3885.v_height)));
	let tmp3514: vec2<f32> = ((abs(tmp3546) - (tmp3547.v_dims)) + vec2<f32>(mix(mix((tmp3544.w), (tmp3544.y), step(c_glsl_const_00.v_o, (tmp3546.x))), mix((tmp3544.z), (tmp3544.x), step(c_glsl_const_00.v_o, (tmp3546.x))), step(c_glsl_const_00.v_o, (tmp3546.y))), mix(mix((tmp3544.w), (tmp3544.y), step(c_glsl_const_00.v_o, (tmp3546.x))), mix((tmp3544.z), (tmp3544.x), step(c_glsl_const_00.v_o, (tmp3546.x))), step(c_glsl_const_00.v_o, (tmp3546.y)))));
	let tmp3944: vec2<f32> = vec2<f32>((((min(max((tmp3899.x), (tmp3899.y)), c_glsl_const_00.v_o) + (length(max(tmp3899, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3903))) + mix((tmp3958.y), (tmp3958.x), step(c_glsl_const_00.v_o, tmp3960))), (abs(tmp3960) - (tmp3962.v_height)));
	let tmp4368: f32 = ((tmp4361.x) / tmp4362);
	let tmp3808: t_neo_elem_02_mod = u_neo_elem_02_mod;
	let tmp4365: f32 = ((tmp4361.w) / tmp4362);
	let tmp4451: f32 = length(tmp4450);
	let tmp3732: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4108 * tmp4108) + (tmp4111 * tmp4111))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4111 * tmp4114) - (tmp4108 * tmp4117))), (c_glsl_const_01.v_o * ((tmp4111 * tmp4117) + (tmp4108 * tmp4114))), (c_glsl_const_01.v_o * ((tmp4111 * tmp4114) + (tmp4108 * tmp4117))), ((c_glsl_const_01.v_o * ((tmp4108 * tmp4108) + (tmp4114 * tmp4114))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4114 * tmp4117) - (tmp4108 * tmp4111))), (c_glsl_const_01.v_o * ((tmp4111 * tmp4117) - (tmp4108 * tmp4114))), (c_glsl_const_01.v_o * ((tmp4114 * tmp4117) + (tmp4108 * tmp4111))), ((c_glsl_const_01.v_o * ((tmp4108 * tmp4108) + (tmp4117 * tmp4117))) - c_glsl_const_02.v_o)) * (((((((tmp4622))) - (u_neo_elem_02_transform.v_trans))) / vec3<f32>(tmp4258, tmp4258, tmp4258))));
	let tmp3804: vec2<f32> = (tmp3808.v_radius);
	let tmp4520: f32 = (u_neo_elem_05_transform.v_scale);
	let tmp3731: t_neo_elem_03_mod = u_neo_elem_03_mod;
	let tmp3806: f32 = (tmp3732.y);
	let tmp4460: f32 = ((tmp4450.y) / tmp4451);
	let tmp4454: f32 = ((tmp4450.w) / tmp4451);
	let tmp3655: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4192 * tmp4192) + (tmp4195 * tmp4195))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4195 * tmp4198) - (tmp4192 * tmp4201))), (c_glsl_const_01.v_o * ((tmp4195 * tmp4201) + (tmp4192 * tmp4198))), (c_glsl_const_01.v_o * ((tmp4195 * tmp4198) + (tmp4192 * tmp4201))), ((c_glsl_const_01.v_o * ((tmp4192 * tmp4192) + (tmp4198 * tmp4198))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4198 * tmp4201) - (tmp4192 * tmp4195))), (c_glsl_const_01.v_o * ((tmp4195 * tmp4201) - (tmp4192 * tmp4198))), (c_glsl_const_01.v_o * ((tmp4198 * tmp4201) + (tmp4192 * tmp4195))), ((c_glsl_const_01.v_o * ((tmp4192 * tmp4192) + (tmp4201 * tmp4201))) - c_glsl_const_02.v_o)) * (((((((tmp4712))) - (u_neo_elem_03_transform.v_trans))) / vec3<f32>(tmp4345, tmp4345, tmp4345))));
	let tmp5071: vec3<f32> = (((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))))))))))));
	let tmp4463: f32 = ((tmp4450.z) / tmp4451);
	let tmp3518: f32 = mix(mix((tmp3544.w), (tmp3544.y), step(c_glsl_const_00.v_o, (tmp3546.x))), mix((tmp3544.z), (tmp3544.x), step(c_glsl_const_00.v_o, (tmp3546.x))), step(c_glsl_const_00.v_o, (tmp3546.y)));
	let tmp3874: f32 = mix((tmp3881.y), (tmp3881.x), step(c_glsl_const_00.v_o, tmp3883));
	let tmp3790: vec2<f32> = vec2<f32>((((min(max((tmp3745.x), (tmp3745.y)), c_glsl_const_00.v_o) + (length(max(tmp3745, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3749))) + mix((tmp3804.y), (tmp3804.x), step(c_glsl_const_00.v_o, tmp3806))), (abs(tmp3806) - (tmp3808.v_height)));
	let tmp4457: f32 = ((tmp4450.x) / tmp4451);
	let tmp3393: t_neo_elem_07_prim = u_neo_elem_07_prim;
	let tmp3951: f32 = mix((tmp3958.y), (tmp3958.x), step(c_glsl_const_00.v_o, tmp3960));
	let tmp3727: vec2<f32> = (tmp3731.v_radius);
	let tmp3437: vec2<f32> = ((abs(tmp3469) - (tmp3470.v_dims)) + vec2<f32>(mix(mix((tmp3467.w), (tmp3467.y), step(c_glsl_const_00.v_o, (tmp3469.x))), mix((tmp3467.z), (tmp3467.x), step(c_glsl_const_00.v_o, (tmp3469.x))), step(c_glsl_const_00.v_o, (tmp3469.y))), mix(mix((tmp3467.w), (tmp3467.y), step(c_glsl_const_00.v_o, (tmp3469.x))), mix((tmp3467.z), (tmp3467.x), step(c_glsl_const_00.v_o, (tmp3469.x))), step(c_glsl_const_00.v_o, (tmp3469.y)))));
	let tmp3713: vec2<f32> = vec2<f32>((((min(max((tmp3668.x), (tmp3668.y)), c_glsl_const_00.v_o) + (length(max(tmp3668, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3672))) + mix((tmp3727.y), (tmp3727.x), step(c_glsl_const_00.v_o, (tmp3655.y)))), (abs((tmp3655.y)) - (tmp3731.v_height)));
	let tmp4609: f32 = (u_neo_elem_06_transform.v_scale);
	let tmp4539: vec4<f32> = (u_neo_elem_07_transform.v_quat);
	let tmp3392: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4539.w) / length(tmp4539)) * ((tmp4539.w) / length(tmp4539))) + (((tmp4539.x) / length(tmp4539)) * ((tmp4539.x) / length(tmp4539))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))) - (((tmp4539.w) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) + (((tmp4539.w) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))) + (((tmp4539.w) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))))), ((c_glsl_const_01.v_o * ((((tmp4539.w) / length(tmp4539)) * ((tmp4539.w) / length(tmp4539))) + (((tmp4539.y) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4539.y) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) - (((tmp4539.w) / length(tmp4539)) * ((tmp4539.x) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) - (((tmp4539.w) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.y) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) + (((tmp4539.w) / length(tmp4539)) * ((tmp4539.x) / length(tmp4539))))), ((c_glsl_const_01.v_o * ((((tmp4539.w) / length(tmp4539)) * ((tmp4539.w) / length(tmp4539))) + (((tmp4539.z) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))))) - c_glsl_const_02.v_o)) * (((((((tmp5071))) - (u_neo_elem_07_transform.v_trans))) / vec3<f32>((u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4539.w) / length(tmp4539)) * ((tmp4539.w) / length(tmp4539))) + (((tmp4539.x) / length(tmp4539)) * ((tmp4539.x) / length(tmp4539))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))) - (((tmp4539.w) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) + (((tmp4539.w) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))) + (((tmp4539.w) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))))), ((c_glsl_const_01.v_o * ((((tmp4539.w) / length(tmp4539)) * ((tmp4539.w) / length(tmp4539))) + (((tmp4539.y) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4539.y) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) - (((tmp4539.w) / length(tmp4539)) * ((tmp4539.x) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.x) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) - (((tmp4539.w) / length(tmp4539)) * ((tmp4539.y) / length(tmp4539))))), (c_glsl_const_01.v_o * ((((tmp4539.y) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))) + (((tmp4539.w) / length(tmp4539)) * ((tmp4539.x) / length(tmp4539))))), ((c_glsl_const_01.v_o * ((((tmp4539.w) / length(tmp4539)) * ((tmp4539.w) / length(tmp4539))) + (((tmp4539.z) / length(tmp4539)) * ((tmp4539.z) / length(tmp4539))))) - c_glsl_const_02.v_o)) * (((((((tmp5071))) - (u_neo_elem_07_transform.v_trans))) / vec3<f32>((u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale), (u_neo_elem_07_transform.v_scale))))).z));
	let tmp3316: t_neo_elem_08_prim = u_neo_elem_08_prim;
	let tmp5161: vec3<f32> = ((((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))))))))))));
	let tmp3390: vec4<f32> = (tmp3393.v_radius);
	let tmp3654: t_neo_elem_04_mod = u_neo_elem_04_mod;
	let tmp3729: f32 = (tmp3655.y);
	let tmp3797: f32 = mix((tmp3804.y), (tmp3804.x), step(c_glsl_const_00.v_o, tmp3806));
	let tmp3315: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp5161))) - (u_neo_elem_08_transform.v_trans))) / vec3<f32>((u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) - ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).y) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).x) / length((u_neo_elem_08_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).w) / length((u_neo_elem_08_transform.v_quat)))) + ((((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat))) * (((u_neo_elem_08_transform.v_quat).z) / length((u_neo_elem_08_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp5161))) - (u_neo_elem_08_transform.v_trans))) / vec3<f32>((u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale), (u_neo_elem_08_transform.v_scale))))).z));
	let tmp3313: vec4<f32> = (tmp3316.v_radius);
	let tmp4629: vec4<f32> = (u_neo_elem_08_transform.v_quat);
	let tmp3578: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4279 * tmp4279) + (tmp4282 * tmp4282))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4282 * tmp4285) - (tmp4279 * tmp4288))), (c_glsl_const_01.v_o * ((tmp4282 * tmp4288) + (tmp4279 * tmp4285))), (c_glsl_const_01.v_o * ((tmp4282 * tmp4285) + (tmp4279 * tmp4288))), ((c_glsl_const_01.v_o * ((tmp4279 * tmp4279) + (tmp4285 * tmp4285))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4285 * tmp4288) - (tmp4279 * tmp4282))), (c_glsl_const_01.v_o * ((tmp4282 * tmp4288) - (tmp4279 * tmp4285))), (c_glsl_const_01.v_o * ((tmp4285 * tmp4288) + (tmp4279 * tmp4282))), ((c_glsl_const_01.v_o * ((tmp4279 * tmp4279) + (tmp4288 * tmp4288))) - c_glsl_const_02.v_o)) * (((((((tmp4802))) - (u_neo_elem_04_transform.v_trans))) / vec3<f32>(tmp4431, tmp4431, tmp4431))));
	let tmp3650: vec2<f32> = (tmp3654.v_radius);
	let tmp4540: f32 = length(tmp4539);
	let tmp3441: f32 = mix(mix((tmp3467.w), (tmp3467.y), step(c_glsl_const_00.v_o, (tmp3469.x))), mix((tmp3467.z), (tmp3467.x), step(c_glsl_const_00.v_o, (tmp3469.x))), step(c_glsl_const_00.v_o, (tmp3469.y)));
	let tmp3577: t_neo_elem_05_mod = u_neo_elem_05_mod;
	let tmp3652: f32 = (tmp3578.y);
	let tmp4543: f32 = ((tmp4539.w) / tmp4540);
	let tmp3360: vec2<f32> = ((abs(tmp3392) - (tmp3393.v_dims)) + vec2<f32>(mix(mix((tmp3390.w), (tmp3390.y), step(c_glsl_const_00.v_o, (tmp3392.x))), mix((tmp3390.z), (tmp3390.x), step(c_glsl_const_00.v_o, (tmp3392.x))), step(c_glsl_const_00.v_o, (tmp3392.y))), mix(mix((tmp3390.w), (tmp3390.y), step(c_glsl_const_00.v_o, (tmp3392.x))), mix((tmp3390.z), (tmp3390.x), step(c_glsl_const_00.v_o, (tmp3392.x))), step(c_glsl_const_00.v_o, (tmp3392.y)))));
	let tmp4630: f32 = length(tmp4629);
	let tmp8516: t_neo_elem_00_transform = u_neo_elem_00_transform;
	let tmp4549: f32 = ((tmp4539.y) / tmp4540);
	let tmp8517: t_neo_elem_01_transform = u_neo_elem_01_transform;
	let tmp3720: f32 = mix((tmp3727.y), (tmp3727.x), step(c_glsl_const_00.v_o, tmp3729));
	let tmp3636: vec2<f32> = vec2<f32>((((min(max((tmp3591.x), (tmp3591.y)), c_glsl_const_00.v_o) + (length(max(tmp3591, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3595))) + mix((tmp3650.y), (tmp3650.x), step(c_glsl_const_00.v_o, tmp3652))), (abs(tmp3652) - (tmp3654.v_height)));
	let tmp4546: f32 = ((tmp4539.x) / tmp4540);
	let tmp4552: f32 = ((tmp4539.z) / tmp4540);
	let tmp3239: t_neo_elem_09_prim = u_neo_elem_09_prim;
	let tmp4699: f32 = (u_neo_elem_07_transform.v_scale);
	let tmp3501: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4365 * tmp4365) + (tmp4368 * tmp4368))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4368 * tmp4371) - (tmp4365 * tmp4374))), (c_glsl_const_01.v_o * ((tmp4368 * tmp4374) + (tmp4365 * tmp4371))), (c_glsl_const_01.v_o * ((tmp4368 * tmp4371) + (tmp4365 * tmp4374))), ((c_glsl_const_01.v_o * ((tmp4365 * tmp4365) + (tmp4371 * tmp4371))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4371 * tmp4374) - (tmp4365 * tmp4368))), (c_glsl_const_01.v_o * ((tmp4368 * tmp4374) - (tmp4365 * tmp4371))), (c_glsl_const_01.v_o * ((tmp4371 * tmp4374) + (tmp4365 * tmp4368))), ((c_glsl_const_01.v_o * ((tmp4365 * tmp4365) + (tmp4374 * tmp4374))) - c_glsl_const_02.v_o)) * (((((((tmp4892))) - (u_neo_elem_05_transform.v_trans))) / vec3<f32>(tmp4520, tmp4520, tmp4520))));
	let tmp5250: vec3<f32> = (((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))))))))));
	let tmp3573: vec2<f32> = (tmp3577.v_radius);
	let tmp4633: f32 = ((tmp4629.w) / tmp4630);
	let tmp3283: vec2<f32> = ((abs(tmp3315) - (tmp3316.v_dims)) + vec2<f32>(mix(mix((tmp3313.w), (tmp3313.y), step(c_glsl_const_00.v_o, (tmp3315.x))), mix((tmp3313.z), (tmp3313.x), step(c_glsl_const_00.v_o, (tmp3315.x))), step(c_glsl_const_00.v_o, (tmp3315.y))), mix(mix((tmp3313.w), (tmp3313.y), step(c_glsl_const_00.v_o, (tmp3315.x))), mix((tmp3313.z), (tmp3313.x), step(c_glsl_const_00.v_o, (tmp3315.x))), step(c_glsl_const_00.v_o, (tmp3315.y)))));
	let tmp4636: f32 = ((tmp4629.x) / tmp4630);
	let tmp4639: f32 = ((tmp4629.y) / tmp4630);
	let tmp4642: f32 = ((tmp4629.z) / tmp4630);
	let tmp3643: f32 = mix((tmp3650.y), (tmp3650.x), step(c_glsl_const_00.v_o, tmp3652));
	let tmp3236: vec4<f32> = (tmp3239.v_radius);
	let tmp3575: f32 = (tmp3501.y);
	let tmp3238: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp5250))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) - ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).y) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).x) / length((u_neo_elem_09_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).w) / length((u_neo_elem_09_transform.v_quat)))) + ((((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat))) * (((u_neo_elem_09_transform.v_quat).z) / length((u_neo_elem_09_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp5250))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>((u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale), (u_neo_elem_09_transform.v_scale))))).z));
	let tmp3364: f32 = mix(mix((tmp3390.w), (tmp3390.y), step(c_glsl_const_00.v_o, (tmp3392.x))), mix((tmp3390.z), (tmp3390.x), step(c_glsl_const_00.v_o, (tmp3392.x))), step(c_glsl_const_00.v_o, (tmp3392.y)));
	let tmp8518: t_neo_elem_02_transform = u_neo_elem_02_transform;
	let tmp4719: vec4<f32> = (u_neo_elem_09_transform.v_quat);
	let tmp3500: t_neo_elem_06_mod = u_neo_elem_06_mod;
	let tmp3559: vec2<f32> = vec2<f32>((((min(max((tmp3514.x), (tmp3514.y)), c_glsl_const_00.v_o) + (length(max(tmp3514, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3518))) + mix((tmp3573.y), (tmp3573.x), step(c_glsl_const_00.v_o, tmp3575))), (abs(tmp3575) - (tmp3577.v_height)));
	let tmp4789: f32 = (u_neo_elem_08_transform.v_scale);
	let tmp4720: f32 = length(tmp4719);
	let tmp3424: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4454 * tmp4454) + (tmp4457 * tmp4457))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4457 * tmp4460) - (tmp4454 * tmp4463))), (c_glsl_const_01.v_o * ((tmp4457 * tmp4463) + (tmp4454 * tmp4460))), (c_glsl_const_01.v_o * ((tmp4457 * tmp4460) + (tmp4454 * tmp4463))), ((c_glsl_const_01.v_o * ((tmp4454 * tmp4454) + (tmp4460 * tmp4460))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4460 * tmp4463) - (tmp4454 * tmp4457))), (c_glsl_const_01.v_o * ((tmp4457 * tmp4463) - (tmp4454 * tmp4460))), (c_glsl_const_01.v_o * ((tmp4460 * tmp4463) + (tmp4454 * tmp4457))), ((c_glsl_const_01.v_o * ((tmp4454 * tmp4454) + (tmp4463 * tmp4463))) - c_glsl_const_02.v_o)) * (((((((tmp4982))) - (u_neo_elem_06_transform.v_trans))) / vec3<f32>(tmp4609, tmp4609, tmp4609))));
	let tmp3287: f32 = mix(mix((tmp3313.w), (tmp3313.y), step(c_glsl_const_00.v_o, (tmp3315.x))), mix((tmp3313.z), (tmp3313.x), step(c_glsl_const_00.v_o, (tmp3315.x))), step(c_glsl_const_00.v_o, (tmp3315.y)));
	let tmp5339: vec3<f32> = ((((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))))))))));
	let tmp3496: vec2<f32> = (tmp3500.v_radius);
	let tmp3162: t_neo_elem_10_prim = u_neo_elem_10_prim;
	let tmp8519: t_neo_elem_03_transform = u_neo_elem_03_transform;
	let tmp4809: vec4<f32> = (u_neo_elem_10_transform.v_quat);
	let tmp3206: vec2<f32> = ((abs(tmp3238) - (tmp3239.v_dims)) + vec2<f32>(mix(mix((tmp3236.w), (tmp3236.y), step(c_glsl_const_00.v_o, (tmp3238.x))), mix((tmp3236.z), (tmp3236.x), step(c_glsl_const_00.v_o, (tmp3238.x))), step(c_glsl_const_00.v_o, (tmp3238.y))), mix(mix((tmp3236.w), (tmp3236.y), step(c_glsl_const_00.v_o, (tmp3238.x))), mix((tmp3236.z), (tmp3236.x), step(c_glsl_const_00.v_o, (tmp3238.x))), step(c_glsl_const_00.v_o, (tmp3238.y)))));
	let tmp3566: f32 = mix((tmp3573.y), (tmp3573.x), step(c_glsl_const_00.v_o, tmp3575));
	let tmp3482: vec2<f32> = vec2<f32>((((min(max((tmp3437.x), (tmp3437.y)), c_glsl_const_00.v_o) + (length(max(tmp3437, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3441))) + mix((tmp3496.y), (tmp3496.x), step(c_glsl_const_00.v_o, (tmp3424.y)))), (abs((tmp3424.y)) - (tmp3500.v_height)));
	let tmp4726: f32 = ((tmp4719.x) / tmp4720);
	let tmp3161: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4809.w) / length(tmp4809)) * ((tmp4809.w) / length(tmp4809))) + (((tmp4809.x) / length(tmp4809)) * ((tmp4809.x) / length(tmp4809))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))) - (((tmp4809.w) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) + (((tmp4809.w) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))) + (((tmp4809.w) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))))), ((c_glsl_const_01.v_o * ((((tmp4809.w) / length(tmp4809)) * ((tmp4809.w) / length(tmp4809))) + (((tmp4809.y) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4809.y) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) - (((tmp4809.w) / length(tmp4809)) * ((tmp4809.x) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) - (((tmp4809.w) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.y) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) + (((tmp4809.w) / length(tmp4809)) * ((tmp4809.x) / length(tmp4809))))), ((c_glsl_const_01.v_o * ((((tmp4809.w) / length(tmp4809)) * ((tmp4809.w) / length(tmp4809))) + (((tmp4809.z) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))))) - c_glsl_const_02.v_o)) * (((((((tmp5339))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>((u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4809.w) / length(tmp4809)) * ((tmp4809.w) / length(tmp4809))) + (((tmp4809.x) / length(tmp4809)) * ((tmp4809.x) / length(tmp4809))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))) - (((tmp4809.w) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) + (((tmp4809.w) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))) + (((tmp4809.w) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))))), ((c_glsl_const_01.v_o * ((((tmp4809.w) / length(tmp4809)) * ((tmp4809.w) / length(tmp4809))) + (((tmp4809.y) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4809.y) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) - (((tmp4809.w) / length(tmp4809)) * ((tmp4809.x) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.x) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) - (((tmp4809.w) / length(tmp4809)) * ((tmp4809.y) / length(tmp4809))))), (c_glsl_const_01.v_o * ((((tmp4809.y) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))) + (((tmp4809.w) / length(tmp4809)) * ((tmp4809.x) / length(tmp4809))))), ((c_glsl_const_01.v_o * ((((tmp4809.w) / length(tmp4809)) * ((tmp4809.w) / length(tmp4809))) + (((tmp4809.z) / length(tmp4809)) * ((tmp4809.z) / length(tmp4809))))) - c_glsl_const_02.v_o)) * (((((((tmp5339))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>((u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale), (u_neo_elem_10_transform.v_scale))))).z));
	let tmp4729: f32 = ((tmp4719.y) / tmp4720);
	let tmp3498: f32 = (tmp3424.y);
	let tmp4732: f32 = ((tmp4719.z) / tmp4720);
	let tmp3159: vec4<f32> = (tmp3162.v_radius);
	let tmp4723: f32 = ((tmp4719.w) / tmp4720);
	let tmp8520: t_neo_elem_04_transform = u_neo_elem_04_transform;
	let tmp3085: t_neo_elem_11_prim = u_neo_elem_11_prim;
	let tmp3423: t_neo_elem_07_mod = u_neo_elem_07_mod;
	let tmp4810: f32 = length(tmp4809);
	let tmp4879: f32 = (u_neo_elem_09_transform.v_scale);
	let tmp5428: vec3<f32> = (((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))))))));
	let tmp3129: vec2<f32> = ((abs(tmp3161) - (tmp3162.v_dims)) + vec2<f32>(mix(mix((tmp3159.w), (tmp3159.y), step(c_glsl_const_00.v_o, (tmp3161.x))), mix((tmp3159.z), (tmp3159.x), step(c_glsl_const_00.v_o, (tmp3161.x))), step(c_glsl_const_00.v_o, (tmp3161.y))), mix(mix((tmp3159.w), (tmp3159.y), step(c_glsl_const_00.v_o, (tmp3161.x))), mix((tmp3159.z), (tmp3159.x), step(c_glsl_const_00.v_o, (tmp3161.x))), step(c_glsl_const_00.v_o, (tmp3161.y)))));
	let tmp4899: vec4<f32> = (u_neo_elem_11_transform.v_quat);
	let tmp3084: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4899.w) / length(tmp4899)) * ((tmp4899.w) / length(tmp4899))) + (((tmp4899.x) / length(tmp4899)) * ((tmp4899.x) / length(tmp4899))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))) - (((tmp4899.w) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) + (((tmp4899.w) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))) + (((tmp4899.w) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))))), ((c_glsl_const_01.v_o * ((((tmp4899.w) / length(tmp4899)) * ((tmp4899.w) / length(tmp4899))) + (((tmp4899.y) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4899.y) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) - (((tmp4899.w) / length(tmp4899)) * ((tmp4899.x) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) - (((tmp4899.w) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.y) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) + (((tmp4899.w) / length(tmp4899)) * ((tmp4899.x) / length(tmp4899))))), ((c_glsl_const_01.v_o * ((((tmp4899.w) / length(tmp4899)) * ((tmp4899.w) / length(tmp4899))) + (((tmp4899.z) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))))) - c_glsl_const_02.v_o)) * (((((((tmp5428))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>((u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4899.w) / length(tmp4899)) * ((tmp4899.w) / length(tmp4899))) + (((tmp4899.x) / length(tmp4899)) * ((tmp4899.x) / length(tmp4899))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))) - (((tmp4899.w) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) + (((tmp4899.w) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))) + (((tmp4899.w) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))))), ((c_glsl_const_01.v_o * ((((tmp4899.w) / length(tmp4899)) * ((tmp4899.w) / length(tmp4899))) + (((tmp4899.y) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4899.y) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) - (((tmp4899.w) / length(tmp4899)) * ((tmp4899.x) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.x) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) - (((tmp4899.w) / length(tmp4899)) * ((tmp4899.y) / length(tmp4899))))), (c_glsl_const_01.v_o * ((((tmp4899.y) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))) + (((tmp4899.w) / length(tmp4899)) * ((tmp4899.x) / length(tmp4899))))), ((c_glsl_const_01.v_o * ((((tmp4899.w) / length(tmp4899)) * ((tmp4899.w) / length(tmp4899))) + (((tmp4899.z) / length(tmp4899)) * ((tmp4899.z) / length(tmp4899))))) - c_glsl_const_02.v_o)) * (((((((tmp5428))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>((u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale), (u_neo_elem_11_transform.v_scale))))).z));
	let tmp3419: vec2<f32> = (tmp3423.v_radius);
	let tmp3346: t_neo_elem_08_mod = u_neo_elem_08_mod;
	let tmp3210: f32 = mix(mix((tmp3236.w), (tmp3236.y), step(c_glsl_const_00.v_o, (tmp3238.x))), mix((tmp3236.z), (tmp3236.x), step(c_glsl_const_00.v_o, (tmp3238.x))), step(c_glsl_const_00.v_o, (tmp3238.y)));
	let tmp3347: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4543 * tmp4543) + (tmp4546 * tmp4546))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4546 * tmp4549) - (tmp4543 * tmp4552))), (c_glsl_const_01.v_o * ((tmp4546 * tmp4552) + (tmp4543 * tmp4549))), (c_glsl_const_01.v_o * ((tmp4546 * tmp4549) + (tmp4543 * tmp4552))), ((c_glsl_const_01.v_o * ((tmp4543 * tmp4543) + (tmp4549 * tmp4549))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4549 * tmp4552) - (tmp4543 * tmp4546))), (c_glsl_const_01.v_o * ((tmp4546 * tmp4552) - (tmp4543 * tmp4549))), (c_glsl_const_01.v_o * ((tmp4549 * tmp4552) + (tmp4543 * tmp4546))), ((c_glsl_const_01.v_o * ((tmp4543 * tmp4543) + (tmp4552 * tmp4552))) - c_glsl_const_02.v_o)) * (((((((tmp5071))) - (u_neo_elem_07_transform.v_trans))) / vec3<f32>(tmp4699, tmp4699, tmp4699))));
	let tmp4813: f32 = ((tmp4809.w) / tmp4810);
	let tmp4822: f32 = ((tmp4809.z) / tmp4810);
	let tmp4819: f32 = ((tmp4809.y) / tmp4810);
	let tmp4816: f32 = ((tmp4809.x) / tmp4810);
	let tmp3082: vec4<f32> = (tmp3085.v_radius);
	let tmp3489: f32 = mix((tmp3496.y), (tmp3496.x), step(c_glsl_const_00.v_o, tmp3498));
	let tmp3008: t_neo_elem_12_prim = u_neo_elem_12_prim;
	let tmp5517: vec3<f32> = ((((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))))))));
	let tmp3405: vec2<f32> = vec2<f32>((((min(max((tmp3360.x), (tmp3360.y)), c_glsl_const_00.v_o) + (length(max(tmp3360, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3364))) + mix((tmp3419.y), (tmp3419.x), step(c_glsl_const_00.v_o, (tmp3347.y)))), (abs((tmp3347.y)) - (tmp3423.v_height)));
	let tmp8521: t_neo_elem_05_transform = u_neo_elem_05_transform;
	let tmp3421: f32 = (tmp3347.y);
	let tmp4969: f32 = (u_neo_elem_10_transform.v_scale);
	let tmp3342: vec2<f32> = (tmp3346.v_radius);
	let tmp3270: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4633 * tmp4633) + (tmp4636 * tmp4636))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4636 * tmp4639) - (tmp4633 * tmp4642))), (c_glsl_const_01.v_o * ((tmp4636 * tmp4642) + (tmp4633 * tmp4639))), (c_glsl_const_01.v_o * ((tmp4636 * tmp4639) + (tmp4633 * tmp4642))), ((c_glsl_const_01.v_o * ((tmp4633 * tmp4633) + (tmp4639 * tmp4639))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4639 * tmp4642) - (tmp4633 * tmp4636))), (c_glsl_const_01.v_o * ((tmp4636 * tmp4642) - (tmp4633 * tmp4639))), (c_glsl_const_01.v_o * ((tmp4639 * tmp4642) + (tmp4633 * tmp4636))), ((c_glsl_const_01.v_o * ((tmp4633 * tmp4633) + (tmp4642 * tmp4642))) - c_glsl_const_02.v_o)) * (((((((tmp5161))) - (u_neo_elem_08_transform.v_trans))) / vec3<f32>(tmp4789, tmp4789, tmp4789))));
	let tmp4900: f32 = length(tmp4899);
	let tmp4988: vec4<f32> = (u_neo_elem_12_transform.v_quat);
	let tmp4903: f32 = ((tmp4899.w) / tmp4900);
	let tmp4912: f32 = ((tmp4899.z) / tmp4900);
	let tmp2931: t_neo_elem_13_prim = u_neo_elem_13_prim;
	let tmp4909: f32 = ((tmp4899.y) / tmp4900);
	let tmp4906: f32 = ((tmp4899.x) / tmp4900);
	let tmp3328: vec2<f32> = vec2<f32>((((min(max((tmp3283.x), (tmp3283.y)), c_glsl_const_00.v_o) + (length(max(tmp3283, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3287))) + mix((tmp3342.y), (tmp3342.x), step(c_glsl_const_00.v_o, (tmp3270.y)))), (abs((tmp3270.y)) - (tmp3346.v_height)));
	let tmp3344: f32 = (tmp3270.y);
	let tmp3052: vec2<f32> = ((abs(tmp3084) - (tmp3085.v_dims)) + vec2<f32>(mix(mix((tmp3082.w), (tmp3082.y), step(c_glsl_const_00.v_o, (tmp3084.x))), mix((tmp3082.z), (tmp3082.x), step(c_glsl_const_00.v_o, (tmp3084.x))), step(c_glsl_const_00.v_o, (tmp3084.y))), mix(mix((tmp3082.w), (tmp3082.y), step(c_glsl_const_00.v_o, (tmp3084.x))), mix((tmp3082.z), (tmp3082.x), step(c_glsl_const_00.v_o, (tmp3084.x))), step(c_glsl_const_00.v_o, (tmp3084.y)))));
	let tmp3133: f32 = mix(mix((tmp3159.w), (tmp3159.y), step(c_glsl_const_00.v_o, (tmp3161.x))), mix((tmp3159.z), (tmp3159.x), step(c_glsl_const_00.v_o, (tmp3161.x))), step(c_glsl_const_00.v_o, (tmp3161.y)));
	let tmp5607: vec3<f32> = (((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))))));
	let tmp3005: vec4<f32> = (tmp3008.v_radius);
	let tmp3007: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4988.w) / length(tmp4988)) * ((tmp4988.w) / length(tmp4988))) + (((tmp4988.x) / length(tmp4988)) * ((tmp4988.x) / length(tmp4988))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))) - (((tmp4988.w) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) + (((tmp4988.w) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))) + (((tmp4988.w) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))))), ((c_glsl_const_01.v_o * ((((tmp4988.w) / length(tmp4988)) * ((tmp4988.w) / length(tmp4988))) + (((tmp4988.y) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4988.y) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) - (((tmp4988.w) / length(tmp4988)) * ((tmp4988.x) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) - (((tmp4988.w) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.y) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) + (((tmp4988.w) / length(tmp4988)) * ((tmp4988.x) / length(tmp4988))))), ((c_glsl_const_01.v_o * ((((tmp4988.w) / length(tmp4988)) * ((tmp4988.w) / length(tmp4988))) + (((tmp4988.z) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))))) - c_glsl_const_02.v_o)) * (((((((tmp5517))) - (u_neo_elem_12_transform.v_trans))) / vec3<f32>((u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp4988.w) / length(tmp4988)) * ((tmp4988.w) / length(tmp4988))) + (((tmp4988.x) / length(tmp4988)) * ((tmp4988.x) / length(tmp4988))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))) - (((tmp4988.w) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) + (((tmp4988.w) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))) + (((tmp4988.w) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))))), ((c_glsl_const_01.v_o * ((((tmp4988.w) / length(tmp4988)) * ((tmp4988.w) / length(tmp4988))) + (((tmp4988.y) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp4988.y) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) - (((tmp4988.w) / length(tmp4988)) * ((tmp4988.x) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.x) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) - (((tmp4988.w) / length(tmp4988)) * ((tmp4988.y) / length(tmp4988))))), (c_glsl_const_01.v_o * ((((tmp4988.y) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))) + (((tmp4988.w) / length(tmp4988)) * ((tmp4988.x) / length(tmp4988))))), ((c_glsl_const_01.v_o * ((((tmp4988.w) / length(tmp4988)) * ((tmp4988.w) / length(tmp4988))) + (((tmp4988.z) / length(tmp4988)) * ((tmp4988.z) / length(tmp4988))))) - c_glsl_const_02.v_o)) * (((((((tmp5517))) - (u_neo_elem_12_transform.v_trans))) / vec3<f32>((u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale), (u_neo_elem_12_transform.v_scale))))).z));
	let tmp3412: f32 = mix((tmp3419.y), (tmp3419.x), step(c_glsl_const_00.v_o, tmp3421));
	let tmp3269: t_neo_elem_09_mod = u_neo_elem_09_mod;
	let tmp4989: f32 = length(tmp4988);
	let tmp8522: t_neo_elem_06_transform = u_neo_elem_06_transform;
	let tmp5078: vec4<f32> = (u_neo_elem_13_transform.v_quat);
	let tmp2928: vec4<f32> = (tmp2931.v_radius);
	let tmp2930: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5078.w) / length(tmp5078)) * ((tmp5078.w) / length(tmp5078))) + (((tmp5078.x) / length(tmp5078)) * ((tmp5078.x) / length(tmp5078))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))) - (((tmp5078.w) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) + (((tmp5078.w) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))) + (((tmp5078.w) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))))), ((c_glsl_const_01.v_o * ((((tmp5078.w) / length(tmp5078)) * ((tmp5078.w) / length(tmp5078))) + (((tmp5078.y) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5078.y) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) - (((tmp5078.w) / length(tmp5078)) * ((tmp5078.x) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) - (((tmp5078.w) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.y) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) + (((tmp5078.w) / length(tmp5078)) * ((tmp5078.x) / length(tmp5078))))), ((c_glsl_const_01.v_o * ((((tmp5078.w) / length(tmp5078)) * ((tmp5078.w) / length(tmp5078))) + (((tmp5078.z) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))))) - c_glsl_const_02.v_o)) * (((((((tmp5607))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5078.w) / length(tmp5078)) * ((tmp5078.w) / length(tmp5078))) + (((tmp5078.x) / length(tmp5078)) * ((tmp5078.x) / length(tmp5078))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))) - (((tmp5078.w) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) + (((tmp5078.w) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))) + (((tmp5078.w) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))))), ((c_glsl_const_01.v_o * ((((tmp5078.w) / length(tmp5078)) * ((tmp5078.w) / length(tmp5078))) + (((tmp5078.y) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5078.y) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) - (((tmp5078.w) / length(tmp5078)) * ((tmp5078.x) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.x) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) - (((tmp5078.w) / length(tmp5078)) * ((tmp5078.y) / length(tmp5078))))), (c_glsl_const_01.v_o * ((((tmp5078.y) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))) + (((tmp5078.w) / length(tmp5078)) * ((tmp5078.x) / length(tmp5078))))), ((c_glsl_const_01.v_o * ((((tmp5078.w) / length(tmp5078)) * ((tmp5078.w) / length(tmp5078))) + (((tmp5078.z) / length(tmp5078)) * ((tmp5078.z) / length(tmp5078))))) - c_glsl_const_02.v_o)) * (((((((tmp5607))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>((u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale), (u_neo_elem_13_transform.v_scale))))).z));
	let tmp5058: f32 = (u_neo_elem_11_transform.v_scale);
	let tmp3335: f32 = mix((tmp3342.y), (tmp3342.x), step(c_glsl_const_00.v_o, tmp3344));
	let tmp5697: vec3<f32> = ((((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))))));
	let tmp3056: f32 = mix(mix((tmp3082.w), (tmp3082.y), step(c_glsl_const_00.v_o, (tmp3084.x))), mix((tmp3082.z), (tmp3082.x), step(c_glsl_const_00.v_o, (tmp3084.x))), step(c_glsl_const_00.v_o, (tmp3084.y)));
	let tmp2975: vec2<f32> = ((abs(tmp3007) - (tmp3008.v_dims)) + vec2<f32>(mix(mix((tmp3005.w), (tmp3005.y), step(c_glsl_const_00.v_o, (tmp3007.x))), mix((tmp3005.z), (tmp3005.x), step(c_glsl_const_00.v_o, (tmp3007.x))), step(c_glsl_const_00.v_o, (tmp3007.y))), mix(mix((tmp3005.w), (tmp3005.y), step(c_glsl_const_00.v_o, (tmp3007.x))), mix((tmp3005.z), (tmp3005.x), step(c_glsl_const_00.v_o, (tmp3007.x))), step(c_glsl_const_00.v_o, (tmp3007.y)))));
	let tmp5079: f32 = length(tmp5078);
	let tmp3193: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4723 * tmp4723) + (tmp4726 * tmp4726))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4726 * tmp4729) - (tmp4723 * tmp4732))), (c_glsl_const_01.v_o * ((tmp4726 * tmp4732) + (tmp4723 * tmp4729))), (c_glsl_const_01.v_o * ((tmp4726 * tmp4729) + (tmp4723 * tmp4732))), ((c_glsl_const_01.v_o * ((tmp4723 * tmp4723) + (tmp4729 * tmp4729))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4729 * tmp4732) - (tmp4723 * tmp4726))), (c_glsl_const_01.v_o * ((tmp4726 * tmp4732) - (tmp4723 * tmp4729))), (c_glsl_const_01.v_o * ((tmp4729 * tmp4732) + (tmp4723 * tmp4726))), ((c_glsl_const_01.v_o * ((tmp4723 * tmp4723) + (tmp4732 * tmp4732))) - c_glsl_const_02.v_o)) * (((((((tmp5250))) - (u_neo_elem_09_transform.v_trans))) / vec3<f32>(tmp4879, tmp4879, tmp4879))));
	let tmp4992: f32 = ((tmp4988.w) / tmp4989);
	let tmp2854: t_neo_elem_14_prim = u_neo_elem_14_prim;
	let tmp5001: f32 = ((tmp4988.z) / tmp4989);
	let tmp4998: f32 = ((tmp4988.y) / tmp4989);
	let tmp4995: f32 = ((tmp4988.x) / tmp4989);
	let tmp3265: vec2<f32> = (tmp3269.v_radius);
	let tmp3267: f32 = (tmp3193.y);
	let tmp5085: f32 = ((tmp5078.x) / tmp5079);
	let tmp3192: t_neo_elem_10_mod = u_neo_elem_10_mod;
	let tmp5167: vec4<f32> = (u_neo_elem_14_transform.v_quat);
	let tmp5088: f32 = ((tmp5078.y) / tmp5079);
	let tmp5082: f32 = ((tmp5078.w) / tmp5079);
	let tmp3251: vec2<f32> = vec2<f32>((((min(max((tmp3206.x), (tmp3206.y)), c_glsl_const_00.v_o) + (length(max(tmp3206, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3210))) + mix((tmp3265.y), (tmp3265.x), step(c_glsl_const_00.v_o, tmp3267))), (abs(tmp3267) - (tmp3269.v_height)));
	let tmp5091: f32 = ((tmp5078.z) / tmp5079);
	let tmp2898: vec2<f32> = ((abs(tmp2930) - (tmp2931.v_dims)) + vec2<f32>(mix(mix((tmp2928.w), (tmp2928.y), step(c_glsl_const_00.v_o, (tmp2930.x))), mix((tmp2928.z), (tmp2928.x), step(c_glsl_const_00.v_o, (tmp2930.x))), step(c_glsl_const_00.v_o, (tmp2930.y))), mix(mix((tmp2928.w), (tmp2928.y), step(c_glsl_const_00.v_o, (tmp2930.x))), mix((tmp2928.z), (tmp2928.x), step(c_glsl_const_00.v_o, (tmp2930.x))), step(c_glsl_const_00.v_o, (tmp2930.y)))));
	let tmp5148: f32 = (u_neo_elem_12_transform.v_scale);
	let tmp2853: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5167.w) / length(tmp5167)) * ((tmp5167.w) / length(tmp5167))) + (((tmp5167.x) / length(tmp5167)) * ((tmp5167.x) / length(tmp5167))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))) - (((tmp5167.w) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) + (((tmp5167.w) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))) + (((tmp5167.w) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))))), ((c_glsl_const_01.v_o * ((((tmp5167.w) / length(tmp5167)) * ((tmp5167.w) / length(tmp5167))) + (((tmp5167.y) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5167.y) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) - (((tmp5167.w) / length(tmp5167)) * ((tmp5167.x) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) - (((tmp5167.w) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.y) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) + (((tmp5167.w) / length(tmp5167)) * ((tmp5167.x) / length(tmp5167))))), ((c_glsl_const_01.v_o * ((((tmp5167.w) / length(tmp5167)) * ((tmp5167.w) / length(tmp5167))) + (((tmp5167.z) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))))) - c_glsl_const_02.v_o)) * (((((((tmp5697))) - (u_neo_elem_14_transform.v_trans))) / vec3<f32>((u_neo_elem_14_transform.v_scale), (u_neo_elem_14_transform.v_scale), (u_neo_elem_14_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5167.w) / length(tmp5167)) * ((tmp5167.w) / length(tmp5167))) + (((tmp5167.x) / length(tmp5167)) * ((tmp5167.x) / length(tmp5167))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))) - (((tmp5167.w) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) + (((tmp5167.w) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))) + (((tmp5167.w) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))))), ((c_glsl_const_01.v_o * ((((tmp5167.w) / length(tmp5167)) * ((tmp5167.w) / length(tmp5167))) + (((tmp5167.y) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5167.y) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) - (((tmp5167.w) / length(tmp5167)) * ((tmp5167.x) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.x) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) - (((tmp5167.w) / length(tmp5167)) * ((tmp5167.y) / length(tmp5167))))), (c_glsl_const_01.v_o * ((((tmp5167.y) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))) + (((tmp5167.w) / length(tmp5167)) * ((tmp5167.x) / length(tmp5167))))), ((c_glsl_const_01.v_o * ((((tmp5167.w) / length(tmp5167)) * ((tmp5167.w) / length(tmp5167))) + (((tmp5167.z) / length(tmp5167)) * ((tmp5167.z) / length(tmp5167))))) - c_glsl_const_02.v_o)) * (((((((tmp5697))) - (u_neo_elem_14_transform.v_trans))) / vec3<f32>((u_neo_elem_14_transform.v_scale), (u_neo_elem_14_transform.v_scale), (u_neo_elem_14_transform.v_scale))))).z));
	let tmp2851: vec4<f32> = (tmp2854.v_radius);
	let tmp3116: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4813 * tmp4813) + (tmp4816 * tmp4816))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4816 * tmp4819) - (tmp4813 * tmp4822))), (c_glsl_const_01.v_o * ((tmp4816 * tmp4822) + (tmp4813 * tmp4819))), (c_glsl_const_01.v_o * ((tmp4816 * tmp4819) + (tmp4813 * tmp4822))), ((c_glsl_const_01.v_o * ((tmp4813 * tmp4813) + (tmp4819 * tmp4819))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4819 * tmp4822) - (tmp4813 * tmp4816))), (c_glsl_const_01.v_o * ((tmp4816 * tmp4822) - (tmp4813 * tmp4819))), (c_glsl_const_01.v_o * ((tmp4819 * tmp4822) + (tmp4813 * tmp4816))), ((c_glsl_const_01.v_o * ((tmp4813 * tmp4813) + (tmp4822 * tmp4822))) - c_glsl_const_02.v_o)) * (((((((tmp5339))) - (u_neo_elem_10_transform.v_trans))) / vec3<f32>(tmp4969, tmp4969, tmp4969))));
	let tmp5237: f32 = (u_neo_elem_13_transform.v_scale);
	let tmp8523: t_neo_elem_07_transform = u_neo_elem_07_transform;
	let tmp3188: vec2<f32> = (tmp3192.v_radius);
	let tmp5168: f32 = length(tmp5167);
	let tmp2777: t_neo_elem_15_prim = u_neo_elem_15_prim;
	let tmp2979: f32 = mix(mix((tmp3005.w), (tmp3005.y), step(c_glsl_const_00.v_o, (tmp3007.x))), mix((tmp3005.z), (tmp3005.x), step(c_glsl_const_00.v_o, (tmp3007.x))), step(c_glsl_const_00.v_o, (tmp3007.y)));
	let tmp5787: vec3<f32> = (((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))))));
	let tmp5171: f32 = ((tmp5167.w) / tmp5168);
	let tmp3174: vec2<f32> = vec2<f32>((((min(max((tmp3129.x), (tmp3129.y)), c_glsl_const_00.v_o) + (length(max(tmp3129, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3133))) + mix((tmp3188.y), (tmp3188.x), step(c_glsl_const_00.v_o, (tmp3116.y)))), (abs((tmp3116.y)) - (tmp3192.v_height)));
	let tmp3115: t_neo_elem_11_mod = u_neo_elem_11_mod;
	let tmp5180: f32 = ((tmp5167.z) / tmp5168);
	let tmp2902: f32 = mix(mix((tmp2928.w), (tmp2928.y), step(c_glsl_const_00.v_o, (tmp2930.x))), mix((tmp2928.z), (tmp2928.x), step(c_glsl_const_00.v_o, (tmp2930.x))), step(c_glsl_const_00.v_o, (tmp2930.y)));
	let tmp5174: f32 = ((tmp5167.x) / tmp5168);
	let tmp5177: f32 = ((tmp5167.y) / tmp5168);
	let tmp5256: vec4<f32> = (u_neo_elem_15_transform.v_quat);
	let tmp2821: vec2<f32> = ((abs(tmp2853) - (tmp2854.v_dims)) + vec2<f32>(mix(mix((tmp2851.w), (tmp2851.y), step(c_glsl_const_00.v_o, (tmp2853.x))), mix((tmp2851.z), (tmp2851.x), step(c_glsl_const_00.v_o, (tmp2853.x))), step(c_glsl_const_00.v_o, (tmp2853.y))), mix(mix((tmp2851.w), (tmp2851.y), step(c_glsl_const_00.v_o, (tmp2853.x))), mix((tmp2851.z), (tmp2851.x), step(c_glsl_const_00.v_o, (tmp2853.x))), step(c_glsl_const_00.v_o, (tmp2853.y)))));
	let tmp2774: vec4<f32> = (tmp2777.v_radius);
	let tmp2776: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5256.w) / length(tmp5256)) * ((tmp5256.w) / length(tmp5256))) + (((tmp5256.x) / length(tmp5256)) * ((tmp5256.x) / length(tmp5256))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))) - (((tmp5256.w) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) + (((tmp5256.w) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))) + (((tmp5256.w) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))))), ((c_glsl_const_01.v_o * ((((tmp5256.w) / length(tmp5256)) * ((tmp5256.w) / length(tmp5256))) + (((tmp5256.y) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5256.y) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) - (((tmp5256.w) / length(tmp5256)) * ((tmp5256.x) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) - (((tmp5256.w) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.y) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) + (((tmp5256.w) / length(tmp5256)) * ((tmp5256.x) / length(tmp5256))))), ((c_glsl_const_01.v_o * ((((tmp5256.w) / length(tmp5256)) * ((tmp5256.w) / length(tmp5256))) + (((tmp5256.z) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))))) - c_glsl_const_02.v_o)) * (((((((tmp5787))) - (u_neo_elem_15_transform.v_trans))) / vec3<f32>((u_neo_elem_15_transform.v_scale), (u_neo_elem_15_transform.v_scale), (u_neo_elem_15_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5256.w) / length(tmp5256)) * ((tmp5256.w) / length(tmp5256))) + (((tmp5256.x) / length(tmp5256)) * ((tmp5256.x) / length(tmp5256))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))) - (((tmp5256.w) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) + (((tmp5256.w) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))) + (((tmp5256.w) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))))), ((c_glsl_const_01.v_o * ((((tmp5256.w) / length(tmp5256)) * ((tmp5256.w) / length(tmp5256))) + (((tmp5256.y) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5256.y) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) - (((tmp5256.w) / length(tmp5256)) * ((tmp5256.x) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.x) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) - (((tmp5256.w) / length(tmp5256)) * ((tmp5256.y) / length(tmp5256))))), (c_glsl_const_01.v_o * ((((tmp5256.y) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))) + (((tmp5256.w) / length(tmp5256)) * ((tmp5256.x) / length(tmp5256))))), ((c_glsl_const_01.v_o * ((((tmp5256.w) / length(tmp5256)) * ((tmp5256.w) / length(tmp5256))) + (((tmp5256.z) / length(tmp5256)) * ((tmp5256.z) / length(tmp5256))))) - c_glsl_const_02.v_o)) * (((((((tmp5787))) - (u_neo_elem_15_transform.v_trans))) / vec3<f32>((u_neo_elem_15_transform.v_scale), (u_neo_elem_15_transform.v_scale), (u_neo_elem_15_transform.v_scale))))).z));
	let tmp8524: t_neo_elem_08_transform = u_neo_elem_08_transform;
	let tmp3258: f32 = mix((tmp3265.y), (tmp3265.x), step(c_glsl_const_00.v_o, tmp3267));
	let tmp3190: f32 = (tmp3116.y);
	let tmp5257: f32 = length(tmp5256);
	let tmp2700: t_neo_elem_16_prim = u_neo_elem_16_prim;
	let tmp3039: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4903 * tmp4903) + (tmp4906 * tmp4906))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4906 * tmp4909) - (tmp4903 * tmp4912))), (c_glsl_const_01.v_o * ((tmp4906 * tmp4912) + (tmp4903 * tmp4909))), (c_glsl_const_01.v_o * ((tmp4906 * tmp4909) + (tmp4903 * tmp4912))), ((c_glsl_const_01.v_o * ((tmp4903 * tmp4903) + (tmp4909 * tmp4909))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4909 * tmp4912) - (tmp4903 * tmp4906))), (c_glsl_const_01.v_o * ((tmp4906 * tmp4912) - (tmp4903 * tmp4909))), (c_glsl_const_01.v_o * ((tmp4909 * tmp4912) + (tmp4903 * tmp4906))), ((c_glsl_const_01.v_o * ((tmp4903 * tmp4903) + (tmp4912 * tmp4912))) - c_glsl_const_02.v_o)) * (((((((tmp5428))) - (u_neo_elem_11_transform.v_trans))) / vec3<f32>(tmp5058, tmp5058, tmp5058))));
	let tmp5326: f32 = (u_neo_elem_14_transform.v_scale);
	let tmp5877: vec3<f32> = ((((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))))));
	let tmp3111: vec2<f32> = (tmp3115.v_radius);
	let tmp2697: vec4<f32> = (tmp2700.v_radius);
	let tmp2744: vec2<f32> = ((abs(tmp2776) - (tmp2777.v_dims)) + vec2<f32>(mix(mix((tmp2774.w), (tmp2774.y), step(c_glsl_const_00.v_o, (tmp2776.x))), mix((tmp2774.z), (tmp2774.x), step(c_glsl_const_00.v_o, (tmp2776.x))), step(c_glsl_const_00.v_o, (tmp2776.y))), mix(mix((tmp2774.w), (tmp2774.y), step(c_glsl_const_00.v_o, (tmp2776.x))), mix((tmp2774.z), (tmp2774.x), step(c_glsl_const_00.v_o, (tmp2776.x))), step(c_glsl_const_00.v_o, (tmp2776.y)))));
	let tmp5260: f32 = ((tmp5256.w) / tmp5257);
	let tmp5263: f32 = ((tmp5256.x) / tmp5257);
	let tmp5266: f32 = ((tmp5256.y) / tmp5257);
	let tmp5269: f32 = ((tmp5256.z) / tmp5257);
	let tmp3038: t_neo_elem_12_mod = u_neo_elem_12_mod;
	let tmp3113: f32 = (tmp3039.y);
	let tmp3181: f32 = mix((tmp3188.y), (tmp3188.x), step(c_glsl_const_00.v_o, tmp3190));
	let tmp5345: vec4<f32> = (u_neo_elem_16_transform.v_quat);
	let tmp2699: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5345.w) / length(tmp5345)) * ((tmp5345.w) / length(tmp5345))) + (((tmp5345.x) / length(tmp5345)) * ((tmp5345.x) / length(tmp5345))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))) - (((tmp5345.w) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) + (((tmp5345.w) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))) + (((tmp5345.w) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))))), ((c_glsl_const_01.v_o * ((((tmp5345.w) / length(tmp5345)) * ((tmp5345.w) / length(tmp5345))) + (((tmp5345.y) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5345.y) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) - (((tmp5345.w) / length(tmp5345)) * ((tmp5345.x) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) - (((tmp5345.w) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.y) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) + (((tmp5345.w) / length(tmp5345)) * ((tmp5345.x) / length(tmp5345))))), ((c_glsl_const_01.v_o * ((((tmp5345.w) / length(tmp5345)) * ((tmp5345.w) / length(tmp5345))) + (((tmp5345.z) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))))) - c_glsl_const_02.v_o)) * (((((((tmp5877))) - (u_neo_elem_16_transform.v_trans))) / vec3<f32>((u_neo_elem_16_transform.v_scale), (u_neo_elem_16_transform.v_scale), (u_neo_elem_16_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5345.w) / length(tmp5345)) * ((tmp5345.w) / length(tmp5345))) + (((tmp5345.x) / length(tmp5345)) * ((tmp5345.x) / length(tmp5345))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))) - (((tmp5345.w) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) + (((tmp5345.w) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))) + (((tmp5345.w) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))))), ((c_glsl_const_01.v_o * ((((tmp5345.w) / length(tmp5345)) * ((tmp5345.w) / length(tmp5345))) + (((tmp5345.y) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5345.y) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) - (((tmp5345.w) / length(tmp5345)) * ((tmp5345.x) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.x) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) - (((tmp5345.w) / length(tmp5345)) * ((tmp5345.y) / length(tmp5345))))), (c_glsl_const_01.v_o * ((((tmp5345.y) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))) + (((tmp5345.w) / length(tmp5345)) * ((tmp5345.x) / length(tmp5345))))), ((c_glsl_const_01.v_o * ((((tmp5345.w) / length(tmp5345)) * ((tmp5345.w) / length(tmp5345))) + (((tmp5345.z) / length(tmp5345)) * ((tmp5345.z) / length(tmp5345))))) - c_glsl_const_02.v_o)) * (((((((tmp5877))) - (u_neo_elem_16_transform.v_trans))) / vec3<f32>((u_neo_elem_16_transform.v_scale), (u_neo_elem_16_transform.v_scale), (u_neo_elem_16_transform.v_scale))))).z));
	let tmp3097: vec2<f32> = vec2<f32>((((min(max((tmp3052.x), (tmp3052.y)), c_glsl_const_00.v_o) + (length(max(tmp3052, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3056))) + mix((tmp3111.y), (tmp3111.x), step(c_glsl_const_00.v_o, tmp3113))), (abs(tmp3113) - (tmp3115.v_height)));
	let tmp2825: f32 = mix(mix((tmp2851.w), (tmp2851.y), step(c_glsl_const_00.v_o, (tmp2853.x))), mix((tmp2851.z), (tmp2851.x), step(c_glsl_const_00.v_o, (tmp2853.x))), step(c_glsl_const_00.v_o, (tmp2853.y)));
	let tmp5346: f32 = length(tmp5345);
	let tmp2961: t_neo_elem_13_mod = u_neo_elem_13_mod;
	let tmp2962: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp4992 * tmp4992) + (tmp4995 * tmp4995))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4995 * tmp4998) - (tmp4992 * tmp5001))), (c_glsl_const_01.v_o * ((tmp4995 * tmp5001) + (tmp4992 * tmp4998))), (c_glsl_const_01.v_o * ((tmp4995 * tmp4998) + (tmp4992 * tmp5001))), ((c_glsl_const_01.v_o * ((tmp4992 * tmp4992) + (tmp4998 * tmp4998))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp4998 * tmp5001) - (tmp4992 * tmp4995))), (c_glsl_const_01.v_o * ((tmp4995 * tmp5001) - (tmp4992 * tmp4998))), (c_glsl_const_01.v_o * ((tmp4998 * tmp5001) + (tmp4992 * tmp4995))), ((c_glsl_const_01.v_o * ((tmp4992 * tmp4992) + (tmp5001 * tmp5001))) - c_glsl_const_02.v_o)) * (((((((tmp5517))) - (u_neo_elem_12_transform.v_trans))) / vec3<f32>(tmp5148, tmp5148, tmp5148))));
	let tmp3034: vec2<f32> = (tmp3038.v_radius);
	let tmp5415: f32 = (u_neo_elem_15_transform.v_scale);
	let tmp8525: t_neo_elem_09_transform = u_neo_elem_09_transform;
	let tmp2623: t_neo_elem_17_prim = u_neo_elem_17_prim;
	let tmp3036: f32 = (tmp2962.y);
	let tmp2667: vec2<f32> = ((abs(tmp2699) - (tmp2700.v_dims)) + vec2<f32>(mix(mix((tmp2697.w), (tmp2697.y), step(c_glsl_const_00.v_o, (tmp2699.x))), mix((tmp2697.z), (tmp2697.x), step(c_glsl_const_00.v_o, (tmp2699.x))), step(c_glsl_const_00.v_o, (tmp2699.y))), mix(mix((tmp2697.w), (tmp2697.y), step(c_glsl_const_00.v_o, (tmp2699.x))), mix((tmp2697.z), (tmp2697.x), step(c_glsl_const_00.v_o, (tmp2699.x))), step(c_glsl_const_00.v_o, (tmp2699.y)))));
	let tmp3104: f32 = mix((tmp3111.y), (tmp3111.x), step(c_glsl_const_00.v_o, tmp3113));
	let tmp2885: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5082 * tmp5082) + (tmp5085 * tmp5085))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5085 * tmp5088) - (tmp5082 * tmp5091))), (c_glsl_const_01.v_o * ((tmp5085 * tmp5091) + (tmp5082 * tmp5088))), (c_glsl_const_01.v_o * ((tmp5085 * tmp5088) + (tmp5082 * tmp5091))), ((c_glsl_const_01.v_o * ((tmp5082 * tmp5082) + (tmp5088 * tmp5088))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5088 * tmp5091) - (tmp5082 * tmp5085))), (c_glsl_const_01.v_o * ((tmp5085 * tmp5091) - (tmp5082 * tmp5088))), (c_glsl_const_01.v_o * ((tmp5088 * tmp5091) + (tmp5082 * tmp5085))), ((c_glsl_const_01.v_o * ((tmp5082 * tmp5082) + (tmp5091 * tmp5091))) - c_glsl_const_02.v_o)) * (((((((tmp5607))) - (u_neo_elem_13_transform.v_trans))) / vec3<f32>(tmp5237, tmp5237, tmp5237))));
	let tmp3020: vec2<f32> = vec2<f32>((((min(max((tmp2975.x), (tmp2975.y)), c_glsl_const_00.v_o) + (length(max(tmp2975, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2979))) + mix((tmp3034.y), (tmp3034.x), step(c_glsl_const_00.v_o, tmp3036))), (abs(tmp3036) - (tmp3038.v_height)));
	let tmp5355: f32 = ((tmp5345.y) / tmp5346);
	let tmp5349: f32 = ((tmp5345.w) / tmp5346);
	let tmp5358: f32 = ((tmp5345.z) / tmp5346);
	let tmp2957: vec2<f32> = (tmp2961.v_radius);
	let tmp5352: f32 = ((tmp5345.x) / tmp5346);
	let tmp5966: vec3<f32> = (((((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))))));
	let tmp2748: f32 = mix(mix((tmp2774.w), (tmp2774.y), step(c_glsl_const_00.v_o, (tmp2776.x))), mix((tmp2774.z), (tmp2774.x), step(c_glsl_const_00.v_o, (tmp2776.x))), step(c_glsl_const_00.v_o, (tmp2776.y)));
	let tmp2884: t_neo_elem_14_mod = u_neo_elem_14_mod;
	let tmp2620: vec4<f32> = (tmp2623.v_radius);
	let tmp2622: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))) - ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) - ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) - ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp5966))) - (u_neo_elem_17_transform.v_trans))) / vec3<f32>((u_neo_elem_17_transform.v_scale), (u_neo_elem_17_transform.v_scale), (u_neo_elem_17_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))) - ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) - ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) - ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).y) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).x) / length((u_neo_elem_17_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).w) / length((u_neo_elem_17_transform.v_quat)))) + ((((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat))) * (((u_neo_elem_17_transform.v_quat).z) / length((u_neo_elem_17_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp5966))) - (u_neo_elem_17_transform.v_trans))) / vec3<f32>((u_neo_elem_17_transform.v_scale), (u_neo_elem_17_transform.v_scale), (u_neo_elem_17_transform.v_scale))))).z));
	let tmp5434: vec4<f32> = (u_neo_elem_17_transform.v_quat);
	let tmp2943: vec2<f32> = vec2<f32>((((min(max((tmp2898.x), (tmp2898.y)), c_glsl_const_00.v_o) + (length(max(tmp2898, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2902))) + mix((tmp2957.y), (tmp2957.x), step(c_glsl_const_00.v_o, (tmp2885.y)))), (abs((tmp2885.y)) - (tmp2961.v_height)));
	let tmp8526: t_neo_elem_10_transform = u_neo_elem_10_transform;
	let tmp2959: f32 = (tmp2885.y);
	let tmp5504: f32 = (u_neo_elem_16_transform.v_scale);
	let tmp2546: t_neo_elem_18_prim = u_neo_elem_18_prim;
	let tmp2671: f32 = mix(mix((tmp2697.w), (tmp2697.y), step(c_glsl_const_00.v_o, (tmp2699.x))), mix((tmp2697.z), (tmp2697.x), step(c_glsl_const_00.v_o, (tmp2699.x))), step(c_glsl_const_00.v_o, (tmp2699.y)));
	let tmp5435: f32 = length(tmp5434);
	let tmp6055: vec3<f32> = ((((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))))));
	let tmp2808: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5171 * tmp5171) + (tmp5174 * tmp5174))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5174 * tmp5177) - (tmp5171 * tmp5180))), (c_glsl_const_01.v_o * ((tmp5174 * tmp5180) + (tmp5171 * tmp5177))), (c_glsl_const_01.v_o * ((tmp5174 * tmp5177) + (tmp5171 * tmp5180))), ((c_glsl_const_01.v_o * ((tmp5171 * tmp5171) + (tmp5177 * tmp5177))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5177 * tmp5180) - (tmp5171 * tmp5174))), (c_glsl_const_01.v_o * ((tmp5174 * tmp5180) - (tmp5171 * tmp5177))), (c_glsl_const_01.v_o * ((tmp5177 * tmp5180) + (tmp5171 * tmp5174))), ((c_glsl_const_01.v_o * ((tmp5171 * tmp5171) + (tmp5180 * tmp5180))) - c_glsl_const_02.v_o)) * (((((((tmp5697))) - (u_neo_elem_14_transform.v_trans))) / vec3<f32>(tmp5326, tmp5326, tmp5326))));
	let tmp3027: f32 = mix((tmp3034.y), (tmp3034.x), step(c_glsl_const_00.v_o, tmp3036));
	let tmp2880: vec2<f32> = (tmp2884.v_radius);
	let tmp5524: vec4<f32> = (u_neo_elem_18_transform.v_quat);
	let tmp5441: f32 = ((tmp5434.x) / tmp5435);
	let tmp2950: f32 = mix((tmp2957.y), (tmp2957.x), step(c_glsl_const_00.v_o, tmp2959));
	let tmp5444: f32 = ((tmp5434.y) / tmp5435);
	let tmp2882: f32 = (tmp2808.y);
	let tmp2545: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5524.w) / length(tmp5524)) * ((tmp5524.w) / length(tmp5524))) + (((tmp5524.x) / length(tmp5524)) * ((tmp5524.x) / length(tmp5524))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))) - (((tmp5524.w) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) + (((tmp5524.w) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))) + (((tmp5524.w) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))))), ((c_glsl_const_01.v_o * ((((tmp5524.w) / length(tmp5524)) * ((tmp5524.w) / length(tmp5524))) + (((tmp5524.y) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5524.y) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) - (((tmp5524.w) / length(tmp5524)) * ((tmp5524.x) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) - (((tmp5524.w) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.y) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) + (((tmp5524.w) / length(tmp5524)) * ((tmp5524.x) / length(tmp5524))))), ((c_glsl_const_01.v_o * ((((tmp5524.w) / length(tmp5524)) * ((tmp5524.w) / length(tmp5524))) + (((tmp5524.z) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))))) - c_glsl_const_02.v_o)) * (((((((tmp6055))) - (u_neo_elem_18_transform.v_trans))) / vec3<f32>((u_neo_elem_18_transform.v_scale), (u_neo_elem_18_transform.v_scale), (u_neo_elem_18_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5524.w) / length(tmp5524)) * ((tmp5524.w) / length(tmp5524))) + (((tmp5524.x) / length(tmp5524)) * ((tmp5524.x) / length(tmp5524))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))) - (((tmp5524.w) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) + (((tmp5524.w) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))) + (((tmp5524.w) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))))), ((c_glsl_const_01.v_o * ((((tmp5524.w) / length(tmp5524)) * ((tmp5524.w) / length(tmp5524))) + (((tmp5524.y) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5524.y) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) - (((tmp5524.w) / length(tmp5524)) * ((tmp5524.x) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.x) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) - (((tmp5524.w) / length(tmp5524)) * ((tmp5524.y) / length(tmp5524))))), (c_glsl_const_01.v_o * ((((tmp5524.y) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))) + (((tmp5524.w) / length(tmp5524)) * ((tmp5524.x) / length(tmp5524))))), ((c_glsl_const_01.v_o * ((((tmp5524.w) / length(tmp5524)) * ((tmp5524.w) / length(tmp5524))) + (((tmp5524.z) / length(tmp5524)) * ((tmp5524.z) / length(tmp5524))))) - c_glsl_const_02.v_o)) * (((((((tmp6055))) - (u_neo_elem_18_transform.v_trans))) / vec3<f32>((u_neo_elem_18_transform.v_scale), (u_neo_elem_18_transform.v_scale), (u_neo_elem_18_transform.v_scale))))).z));
	let tmp2807: t_neo_elem_15_mod = u_neo_elem_15_mod;
	let tmp2590: vec2<f32> = ((abs(tmp2622) - (tmp2623.v_dims)) + vec2<f32>(mix(mix((tmp2620.w), (tmp2620.y), step(c_glsl_const_00.v_o, (tmp2622.x))), mix((tmp2620.z), (tmp2620.x), step(c_glsl_const_00.v_o, (tmp2622.x))), step(c_glsl_const_00.v_o, (tmp2622.y))), mix(mix((tmp2620.w), (tmp2620.y), step(c_glsl_const_00.v_o, (tmp2622.x))), mix((tmp2620.z), (tmp2620.x), step(c_glsl_const_00.v_o, (tmp2622.x))), step(c_glsl_const_00.v_o, (tmp2622.y)))));
	let tmp2543: vec4<f32> = (tmp2546.v_radius);
	let tmp5438: f32 = ((tmp5434.w) / tmp5435);
	let tmp8527: t_neo_elem_11_transform = u_neo_elem_11_transform;
	let tmp2866: vec2<f32> = vec2<f32>((((min(max((tmp2821.x), (tmp2821.y)), c_glsl_const_00.v_o) + (length(max(tmp2821, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2825))) + mix((tmp2880.y), (tmp2880.x), step(c_glsl_const_00.v_o, tmp2882))), (abs(tmp2882) - (tmp2884.v_height)));
	let tmp5447: f32 = ((tmp5434.z) / tmp5435);
	let tmp2469: t_neo_elem_19_prim = u_neo_elem_19_prim;
	let tmp5525: f32 = length(tmp5524);
	let tmp5594: f32 = (u_neo_elem_17_transform.v_scale);
	let tmp2731: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5260 * tmp5260) + (tmp5263 * tmp5263))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5263 * tmp5266) - (tmp5260 * tmp5269))), (c_glsl_const_01.v_o * ((tmp5263 * tmp5269) + (tmp5260 * tmp5266))), (c_glsl_const_01.v_o * ((tmp5263 * tmp5266) + (tmp5260 * tmp5269))), ((c_glsl_const_01.v_o * ((tmp5260 * tmp5260) + (tmp5266 * tmp5266))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5266 * tmp5269) - (tmp5260 * tmp5263))), (c_glsl_const_01.v_o * ((tmp5263 * tmp5269) - (tmp5260 * tmp5266))), (c_glsl_const_01.v_o * ((tmp5266 * tmp5269) + (tmp5260 * tmp5263))), ((c_glsl_const_01.v_o * ((tmp5260 * tmp5260) + (tmp5269 * tmp5269))) - c_glsl_const_02.v_o)) * (((((((tmp5787))) - (u_neo_elem_15_transform.v_trans))) / vec3<f32>(tmp5415, tmp5415, tmp5415))));
	let tmp2803: vec2<f32> = (tmp2807.v_radius);
	let tmp6144: vec3<f32> = (((((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))))));
	let tmp5614: vec4<f32> = (u_neo_elem_19_transform.v_quat);
	let tmp2594: f32 = mix(mix((tmp2620.w), (tmp2620.y), step(c_glsl_const_00.v_o, (tmp2622.x))), mix((tmp2620.z), (tmp2620.x), step(c_glsl_const_00.v_o, (tmp2622.x))), step(c_glsl_const_00.v_o, (tmp2622.y)));
	let tmp2468: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5614.w) / length(tmp5614)) * ((tmp5614.w) / length(tmp5614))) + (((tmp5614.x) / length(tmp5614)) * ((tmp5614.x) / length(tmp5614))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))) - (((tmp5614.w) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) + (((tmp5614.w) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))) + (((tmp5614.w) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))))), ((c_glsl_const_01.v_o * ((((tmp5614.w) / length(tmp5614)) * ((tmp5614.w) / length(tmp5614))) + (((tmp5614.y) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5614.y) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) - (((tmp5614.w) / length(tmp5614)) * ((tmp5614.x) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) - (((tmp5614.w) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.y) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) + (((tmp5614.w) / length(tmp5614)) * ((tmp5614.x) / length(tmp5614))))), ((c_glsl_const_01.v_o * ((((tmp5614.w) / length(tmp5614)) * ((tmp5614.w) / length(tmp5614))) + (((tmp5614.z) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))))) - c_glsl_const_02.v_o)) * (((((((tmp6144))) - (u_neo_elem_19_transform.v_trans))) / vec3<f32>((u_neo_elem_19_transform.v_scale), (u_neo_elem_19_transform.v_scale), (u_neo_elem_19_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5614.w) / length(tmp5614)) * ((tmp5614.w) / length(tmp5614))) + (((tmp5614.x) / length(tmp5614)) * ((tmp5614.x) / length(tmp5614))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))) - (((tmp5614.w) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) + (((tmp5614.w) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))) + (((tmp5614.w) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))))), ((c_glsl_const_01.v_o * ((((tmp5614.w) / length(tmp5614)) * ((tmp5614.w) / length(tmp5614))) + (((tmp5614.y) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5614.y) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) - (((tmp5614.w) / length(tmp5614)) * ((tmp5614.x) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.x) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) - (((tmp5614.w) / length(tmp5614)) * ((tmp5614.y) / length(tmp5614))))), (c_glsl_const_01.v_o * ((((tmp5614.y) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))) + (((tmp5614.w) / length(tmp5614)) * ((tmp5614.x) / length(tmp5614))))), ((c_glsl_const_01.v_o * ((((tmp5614.w) / length(tmp5614)) * ((tmp5614.w) / length(tmp5614))) + (((tmp5614.z) / length(tmp5614)) * ((tmp5614.z) / length(tmp5614))))) - c_glsl_const_02.v_o)) * (((((((tmp6144))) - (u_neo_elem_19_transform.v_trans))) / vec3<f32>((u_neo_elem_19_transform.v_scale), (u_neo_elem_19_transform.v_scale), (u_neo_elem_19_transform.v_scale))))).z));
	let tmp2466: vec4<f32> = (tmp2469.v_radius);
	let tmp2805: f32 = (tmp2731.y);
	let tmp2873: f32 = mix((tmp2880.y), (tmp2880.x), step(c_glsl_const_00.v_o, tmp2882));
	let tmp5534: f32 = ((tmp5524.y) / tmp5525);
	let tmp5531: f32 = ((tmp5524.x) / tmp5525);
	let tmp5528: f32 = ((tmp5524.w) / tmp5525);
	let tmp2730: t_neo_elem_16_mod = u_neo_elem_16_mod;
	let tmp2513: vec2<f32> = ((abs(tmp2545) - (tmp2546.v_dims)) + vec2<f32>(mix(mix((tmp2543.w), (tmp2543.y), step(c_glsl_const_00.v_o, (tmp2545.x))), mix((tmp2543.z), (tmp2543.x), step(c_glsl_const_00.v_o, (tmp2545.x))), step(c_glsl_const_00.v_o, (tmp2545.y))), mix(mix((tmp2543.w), (tmp2543.y), step(c_glsl_const_00.v_o, (tmp2545.x))), mix((tmp2543.z), (tmp2543.x), step(c_glsl_const_00.v_o, (tmp2545.x))), step(c_glsl_const_00.v_o, (tmp2545.y)))));
	let tmp8528: t_neo_elem_12_transform = u_neo_elem_12_transform;
	let tmp5537: f32 = ((tmp5524.z) / tmp5525);
	let tmp2789: vec2<f32> = vec2<f32>((((min(max((tmp2744.x), (tmp2744.y)), c_glsl_const_00.v_o) + (length(max(tmp2744, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2748))) + mix((tmp2803.y), (tmp2803.x), step(c_glsl_const_00.v_o, tmp2805))), (abs(tmp2805) - (tmp2807.v_height)));
	let tmp2726: vec2<f32> = (tmp2730.v_radius);
	let tmp2392: t_neo_elem_20_prim = u_neo_elem_20_prim;
	let tmp2654: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5349 * tmp5349) + (tmp5352 * tmp5352))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5352 * tmp5355) - (tmp5349 * tmp5358))), (c_glsl_const_01.v_o * ((tmp5352 * tmp5358) + (tmp5349 * tmp5355))), (c_glsl_const_01.v_o * ((tmp5352 * tmp5355) + (tmp5349 * tmp5358))), ((c_glsl_const_01.v_o * ((tmp5349 * tmp5349) + (tmp5355 * tmp5355))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5355 * tmp5358) - (tmp5349 * tmp5352))), (c_glsl_const_01.v_o * ((tmp5352 * tmp5358) - (tmp5349 * tmp5355))), (c_glsl_const_01.v_o * ((tmp5355 * tmp5358) + (tmp5349 * tmp5352))), ((c_glsl_const_01.v_o * ((tmp5349 * tmp5349) + (tmp5358 * tmp5358))) - c_glsl_const_02.v_o)) * (((((((tmp5877))) - (u_neo_elem_16_transform.v_trans))) / vec3<f32>(tmp5504, tmp5504, tmp5504))));
	let tmp5615: f32 = length(tmp5614);
	let tmp6233: vec3<f32> = ((((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))))));
	let tmp8529: t_neo_elem_13_transform = u_neo_elem_13_transform;
	let tmp5684: f32 = (u_neo_elem_18_transform.v_scale);
	let tmp5624: f32 = ((tmp5614.y) / tmp5615);
	let tmp5627: f32 = ((tmp5614.z) / tmp5615);
	let tmp5704: vec4<f32> = (u_neo_elem_20_transform.v_quat);
	let tmp2796: f32 = mix((tmp2803.y), (tmp2803.x), step(c_glsl_const_00.v_o, tmp2805));
	let tmp2728: f32 = (tmp2654.y);
	let tmp2712: vec2<f32> = vec2<f32>((((min(max((tmp2667.x), (tmp2667.y)), c_glsl_const_00.v_o) + (length(max(tmp2667, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2671))) + mix((tmp2726.y), (tmp2726.x), step(c_glsl_const_00.v_o, tmp2728))), (abs(tmp2728) - (tmp2730.v_height)));
	let tmp2389: vec4<f32> = (tmp2392.v_radius);
	let tmp2391: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5704.w) / length(tmp5704)) * ((tmp5704.w) / length(tmp5704))) + (((tmp5704.x) / length(tmp5704)) * ((tmp5704.x) / length(tmp5704))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))) - (((tmp5704.w) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) + (((tmp5704.w) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))) + (((tmp5704.w) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))))), ((c_glsl_const_01.v_o * ((((tmp5704.w) / length(tmp5704)) * ((tmp5704.w) / length(tmp5704))) + (((tmp5704.y) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5704.y) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) - (((tmp5704.w) / length(tmp5704)) * ((tmp5704.x) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) - (((tmp5704.w) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.y) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) + (((tmp5704.w) / length(tmp5704)) * ((tmp5704.x) / length(tmp5704))))), ((c_glsl_const_01.v_o * ((((tmp5704.w) / length(tmp5704)) * ((tmp5704.w) / length(tmp5704))) + (((tmp5704.z) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))))) - c_glsl_const_02.v_o)) * (((((((tmp6233))) - (u_neo_elem_20_transform.v_trans))) / vec3<f32>((u_neo_elem_20_transform.v_scale), (u_neo_elem_20_transform.v_scale), (u_neo_elem_20_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5704.w) / length(tmp5704)) * ((tmp5704.w) / length(tmp5704))) + (((tmp5704.x) / length(tmp5704)) * ((tmp5704.x) / length(tmp5704))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))) - (((tmp5704.w) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) + (((tmp5704.w) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))) + (((tmp5704.w) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))))), ((c_glsl_const_01.v_o * ((((tmp5704.w) / length(tmp5704)) * ((tmp5704.w) / length(tmp5704))) + (((tmp5704.y) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5704.y) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) - (((tmp5704.w) / length(tmp5704)) * ((tmp5704.x) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.x) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) - (((tmp5704.w) / length(tmp5704)) * ((tmp5704.y) / length(tmp5704))))), (c_glsl_const_01.v_o * ((((tmp5704.y) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))) + (((tmp5704.w) / length(tmp5704)) * ((tmp5704.x) / length(tmp5704))))), ((c_glsl_const_01.v_o * ((((tmp5704.w) / length(tmp5704)) * ((tmp5704.w) / length(tmp5704))) + (((tmp5704.z) / length(tmp5704)) * ((tmp5704.z) / length(tmp5704))))) - c_glsl_const_02.v_o)) * (((((((tmp6233))) - (u_neo_elem_20_transform.v_trans))) / vec3<f32>((u_neo_elem_20_transform.v_scale), (u_neo_elem_20_transform.v_scale), (u_neo_elem_20_transform.v_scale))))).z));
	let tmp5618: f32 = ((tmp5614.w) / tmp5615);
	let tmp2436: vec2<f32> = ((abs(tmp2468) - (tmp2469.v_dims)) + vec2<f32>(mix(mix((tmp2466.w), (tmp2466.y), step(c_glsl_const_00.v_o, (tmp2468.x))), mix((tmp2466.z), (tmp2466.x), step(c_glsl_const_00.v_o, (tmp2468.x))), step(c_glsl_const_00.v_o, (tmp2468.y))), mix(mix((tmp2466.w), (tmp2466.y), step(c_glsl_const_00.v_o, (tmp2468.x))), mix((tmp2466.z), (tmp2466.x), step(c_glsl_const_00.v_o, (tmp2468.x))), step(c_glsl_const_00.v_o, (tmp2468.y)))));
	let tmp2517: f32 = mix(mix((tmp2543.w), (tmp2543.y), step(c_glsl_const_00.v_o, (tmp2545.x))), mix((tmp2543.z), (tmp2543.x), step(c_glsl_const_00.v_o, (tmp2545.x))), step(c_glsl_const_00.v_o, (tmp2545.y)));
	let tmp5621: f32 = ((tmp5614.x) / tmp5615);
	let tmp2315: t_neo_elem_21_prim = u_neo_elem_21_prim;
	let tmp8530: t_neo_elem_14_transform = u_neo_elem_14_transform;
	let tmp6322: vec3<f32> = (((((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))))));
	let tmp5774: f32 = (u_neo_elem_19_transform.v_scale);
	let tmp5705: f32 = length(tmp5704);
	let tmp2653: t_neo_elem_17_mod = u_neo_elem_17_mod;
	let tmp2440: f32 = mix(mix((tmp2466.w), (tmp2466.y), step(c_glsl_const_00.v_o, (tmp2468.x))), mix((tmp2466.z), (tmp2466.x), step(c_glsl_const_00.v_o, (tmp2468.x))), step(c_glsl_const_00.v_o, (tmp2468.y)));
	let tmp5794: vec4<f32> = (u_neo_elem_21_transform.v_quat);
	let tmp5708: f32 = ((tmp5704.w) / tmp5705);
	let tmp2719: f32 = mix((tmp2726.y), (tmp2726.x), step(c_glsl_const_00.v_o, tmp2728));
	let tmp2312: vec4<f32> = (tmp2315.v_radius);
	let tmp2314: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5794.w) / length(tmp5794)) * ((tmp5794.w) / length(tmp5794))) + (((tmp5794.x) / length(tmp5794)) * ((tmp5794.x) / length(tmp5794))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))) - (((tmp5794.w) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) + (((tmp5794.w) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))) + (((tmp5794.w) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))))), ((c_glsl_const_01.v_o * ((((tmp5794.w) / length(tmp5794)) * ((tmp5794.w) / length(tmp5794))) + (((tmp5794.y) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5794.y) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) - (((tmp5794.w) / length(tmp5794)) * ((tmp5794.x) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) - (((tmp5794.w) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.y) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) + (((tmp5794.w) / length(tmp5794)) * ((tmp5794.x) / length(tmp5794))))), ((c_glsl_const_01.v_o * ((((tmp5794.w) / length(tmp5794)) * ((tmp5794.w) / length(tmp5794))) + (((tmp5794.z) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))))) - c_glsl_const_02.v_o)) * (((((((tmp6322))) - (u_neo_elem_21_transform.v_trans))) / vec3<f32>((u_neo_elem_21_transform.v_scale), (u_neo_elem_21_transform.v_scale), (u_neo_elem_21_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5794.w) / length(tmp5794)) * ((tmp5794.w) / length(tmp5794))) + (((tmp5794.x) / length(tmp5794)) * ((tmp5794.x) / length(tmp5794))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))) - (((tmp5794.w) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) + (((tmp5794.w) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))) + (((tmp5794.w) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))))), ((c_glsl_const_01.v_o * ((((tmp5794.w) / length(tmp5794)) * ((tmp5794.w) / length(tmp5794))) + (((tmp5794.y) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5794.y) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) - (((tmp5794.w) / length(tmp5794)) * ((tmp5794.x) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.x) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) - (((tmp5794.w) / length(tmp5794)) * ((tmp5794.y) / length(tmp5794))))), (c_glsl_const_01.v_o * ((((tmp5794.y) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))) + (((tmp5794.w) / length(tmp5794)) * ((tmp5794.x) / length(tmp5794))))), ((c_glsl_const_01.v_o * ((((tmp5794.w) / length(tmp5794)) * ((tmp5794.w) / length(tmp5794))) + (((tmp5794.z) / length(tmp5794)) * ((tmp5794.z) / length(tmp5794))))) - c_glsl_const_02.v_o)) * (((((((tmp6322))) - (u_neo_elem_21_transform.v_trans))) / vec3<f32>((u_neo_elem_21_transform.v_scale), (u_neo_elem_21_transform.v_scale), (u_neo_elem_21_transform.v_scale))))).z));
	let tmp2577: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5438 * tmp5438) + (tmp5441 * tmp5441))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5441 * tmp5444) - (tmp5438 * tmp5447))), (c_glsl_const_01.v_o * ((tmp5441 * tmp5447) + (tmp5438 * tmp5444))), (c_glsl_const_01.v_o * ((tmp5441 * tmp5444) + (tmp5438 * tmp5447))), ((c_glsl_const_01.v_o * ((tmp5438 * tmp5438) + (tmp5444 * tmp5444))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5444 * tmp5447) - (tmp5438 * tmp5441))), (c_glsl_const_01.v_o * ((tmp5441 * tmp5447) - (tmp5438 * tmp5444))), (c_glsl_const_01.v_o * ((tmp5444 * tmp5447) + (tmp5438 * tmp5441))), ((c_glsl_const_01.v_o * ((tmp5438 * tmp5438) + (tmp5447 * tmp5447))) - c_glsl_const_02.v_o)) * (((((((tmp5966))) - (u_neo_elem_17_transform.v_trans))) / vec3<f32>(tmp5594, tmp5594, tmp5594))));
	let tmp2359: vec2<f32> = ((abs(tmp2391) - (tmp2392.v_dims)) + vec2<f32>(mix(mix((tmp2389.w), (tmp2389.y), step(c_glsl_const_00.v_o, (tmp2391.x))), mix((tmp2389.z), (tmp2389.x), step(c_glsl_const_00.v_o, (tmp2391.x))), step(c_glsl_const_00.v_o, (tmp2391.y))), mix(mix((tmp2389.w), (tmp2389.y), step(c_glsl_const_00.v_o, (tmp2391.x))), mix((tmp2389.z), (tmp2389.x), step(c_glsl_const_00.v_o, (tmp2391.x))), step(c_glsl_const_00.v_o, (tmp2391.y)))));
	let tmp5711: f32 = ((tmp5704.x) / tmp5705);
	let tmp2649: vec2<f32> = (tmp2653.v_radius);
	let tmp5714: f32 = ((tmp5704.y) / tmp5705);
	let tmp5717: f32 = ((tmp5704.z) / tmp5705);
	let tmp5795: f32 = length(tmp5794);
	let tmp6411: vec3<f32> = ((((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))))));
	let tmp8531: t_neo_elem_15_transform = u_neo_elem_15_transform;
	let tmp2238: t_neo_elem_22_prim = u_neo_elem_22_prim;
	let tmp2635: vec2<f32> = vec2<f32>((((min(max((tmp2590.x), (tmp2590.y)), c_glsl_const_00.v_o) + (length(max(tmp2590, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2594))) + mix((tmp2649.y), (tmp2649.x), step(c_glsl_const_00.v_o, (tmp2577.y)))), (abs((tmp2577.y)) - (tmp2653.v_height)));
	let tmp2576: t_neo_elem_18_mod = u_neo_elem_18_mod;
	let tmp2651: f32 = (tmp2577.y);
	let tmp5864: f32 = (u_neo_elem_20_transform.v_scale);
	let tmp2235: vec4<f32> = (tmp2238.v_radius);
	let tmp2237: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))) - ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) - ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) - ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6411))) - (u_neo_elem_22_transform.v_trans))) / vec3<f32>((u_neo_elem_22_transform.v_scale), (u_neo_elem_22_transform.v_scale), (u_neo_elem_22_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))) - ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) - ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) - ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).y) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).x) / length((u_neo_elem_22_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).w) / length((u_neo_elem_22_transform.v_quat)))) + ((((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat))) * (((u_neo_elem_22_transform.v_quat).z) / length((u_neo_elem_22_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6411))) - (u_neo_elem_22_transform.v_trans))) / vec3<f32>((u_neo_elem_22_transform.v_scale), (u_neo_elem_22_transform.v_scale), (u_neo_elem_22_transform.v_scale))))).z));
	let tmp2500: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5528 * tmp5528) + (tmp5531 * tmp5531))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5531 * tmp5534) - (tmp5528 * tmp5537))), (c_glsl_const_01.v_o * ((tmp5531 * tmp5537) + (tmp5528 * tmp5534))), (c_glsl_const_01.v_o * ((tmp5531 * tmp5534) + (tmp5528 * tmp5537))), ((c_glsl_const_01.v_o * ((tmp5528 * tmp5528) + (tmp5534 * tmp5534))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5534 * tmp5537) - (tmp5528 * tmp5531))), (c_glsl_const_01.v_o * ((tmp5531 * tmp5537) - (tmp5528 * tmp5534))), (c_glsl_const_01.v_o * ((tmp5534 * tmp5537) + (tmp5528 * tmp5531))), ((c_glsl_const_01.v_o * ((tmp5528 * tmp5528) + (tmp5537 * tmp5537))) - c_glsl_const_02.v_o)) * (((((((tmp6055))) - (u_neo_elem_18_transform.v_trans))) / vec3<f32>(tmp5684, tmp5684, tmp5684))));
	let tmp5804: f32 = ((tmp5794.y) / tmp5795);
	let tmp5883: vec4<f32> = (u_neo_elem_22_transform.v_quat);
	let tmp2363: f32 = mix(mix((tmp2389.w), (tmp2389.y), step(c_glsl_const_00.v_o, (tmp2391.x))), mix((tmp2389.z), (tmp2389.x), step(c_glsl_const_00.v_o, (tmp2391.x))), step(c_glsl_const_00.v_o, (tmp2391.y)));
	let tmp5798: f32 = ((tmp5794.w) / tmp5795);
	let tmp5801: f32 = ((tmp5794.x) / tmp5795);
	let tmp2282: vec2<f32> = ((abs(tmp2314) - (tmp2315.v_dims)) + vec2<f32>(mix(mix((tmp2312.w), (tmp2312.y), step(c_glsl_const_00.v_o, (tmp2314.x))), mix((tmp2312.z), (tmp2312.x), step(c_glsl_const_00.v_o, (tmp2314.x))), step(c_glsl_const_00.v_o, (tmp2314.y))), mix(mix((tmp2312.w), (tmp2312.y), step(c_glsl_const_00.v_o, (tmp2314.x))), mix((tmp2312.z), (tmp2312.x), step(c_glsl_const_00.v_o, (tmp2314.x))), step(c_glsl_const_00.v_o, (tmp2314.y)))));
	let tmp2572: vec2<f32> = (tmp2576.v_radius);
	let tmp5807: f32 = ((tmp5794.z) / tmp5795);
	let tmp2161: t_neo_elem_23_prim = u_neo_elem_23_prim;
	let tmp8532: t_neo_elem_16_transform = u_neo_elem_16_transform;
	let tmp6500: vec3<f32> = (((((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))))));
	let tmp2642: f32 = mix((tmp2649.y), (tmp2649.x), step(c_glsl_const_00.v_o, tmp2651));
	let tmp2558: vec2<f32> = vec2<f32>((((min(max((tmp2513.x), (tmp2513.y)), c_glsl_const_00.v_o) + (length(max(tmp2513, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2517))) + mix((tmp2572.y), (tmp2572.x), step(c_glsl_const_00.v_o, (tmp2500.y)))), (abs((tmp2500.y)) - (tmp2576.v_height)));
	let tmp5884: f32 = length(tmp5883);
	let tmp5953: f32 = (u_neo_elem_21_transform.v_scale);
	let tmp2574: f32 = (tmp2500.y);
	let tmp2499: t_neo_elem_19_mod = u_neo_elem_19_mod;
	let tmp2423: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5618 * tmp5618) + (tmp5621 * tmp5621))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5621 * tmp5624) - (tmp5618 * tmp5627))), (c_glsl_const_01.v_o * ((tmp5621 * tmp5627) + (tmp5618 * tmp5624))), (c_glsl_const_01.v_o * ((tmp5621 * tmp5624) + (tmp5618 * tmp5627))), ((c_glsl_const_01.v_o * ((tmp5618 * tmp5618) + (tmp5624 * tmp5624))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5624 * tmp5627) - (tmp5618 * tmp5621))), (c_glsl_const_01.v_o * ((tmp5621 * tmp5627) - (tmp5618 * tmp5624))), (c_glsl_const_01.v_o * ((tmp5624 * tmp5627) + (tmp5618 * tmp5621))), ((c_glsl_const_01.v_o * ((tmp5618 * tmp5618) + (tmp5627 * tmp5627))) - c_glsl_const_02.v_o)) * (((((((tmp6144))) - (u_neo_elem_19_transform.v_trans))) / vec3<f32>(tmp5774, tmp5774, tmp5774))));
	let tmp2205: vec2<f32> = ((abs(tmp2237) - (tmp2238.v_dims)) + vec2<f32>(mix(mix((tmp2235.w), (tmp2235.y), step(c_glsl_const_00.v_o, (tmp2237.x))), mix((tmp2235.z), (tmp2235.x), step(c_glsl_const_00.v_o, (tmp2237.x))), step(c_glsl_const_00.v_o, (tmp2237.y))), mix(mix((tmp2235.w), (tmp2235.y), step(c_glsl_const_00.v_o, (tmp2237.x))), mix((tmp2235.z), (tmp2235.x), step(c_glsl_const_00.v_o, (tmp2237.x))), step(c_glsl_const_00.v_o, (tmp2237.y)))));
	let tmp5893: f32 = ((tmp5883.y) / tmp5884);
	let tmp5887: f32 = ((tmp5883.w) / tmp5884);
	let tmp2495: vec2<f32> = (tmp2499.v_radius);
	let tmp5972: vec4<f32> = (u_neo_elem_23_transform.v_quat);
	let tmp2158: vec4<f32> = (tmp2161.v_radius);
	let tmp5890: f32 = ((tmp5883.x) / tmp5884);
	let tmp2160: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5972.w) / length(tmp5972)) * ((tmp5972.w) / length(tmp5972))) + (((tmp5972.x) / length(tmp5972)) * ((tmp5972.x) / length(tmp5972))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))) - (((tmp5972.w) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) + (((tmp5972.w) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))) + (((tmp5972.w) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))))), ((c_glsl_const_01.v_o * ((((tmp5972.w) / length(tmp5972)) * ((tmp5972.w) / length(tmp5972))) + (((tmp5972.y) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5972.y) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) - (((tmp5972.w) / length(tmp5972)) * ((tmp5972.x) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) - (((tmp5972.w) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.y) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) + (((tmp5972.w) / length(tmp5972)) * ((tmp5972.x) / length(tmp5972))))), ((c_glsl_const_01.v_o * ((((tmp5972.w) / length(tmp5972)) * ((tmp5972.w) / length(tmp5972))) + (((tmp5972.z) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))))) - c_glsl_const_02.v_o)) * (((((((tmp6500))) - (u_neo_elem_23_transform.v_trans))) / vec3<f32>((u_neo_elem_23_transform.v_scale), (u_neo_elem_23_transform.v_scale), (u_neo_elem_23_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp5972.w) / length(tmp5972)) * ((tmp5972.w) / length(tmp5972))) + (((tmp5972.x) / length(tmp5972)) * ((tmp5972.x) / length(tmp5972))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))) - (((tmp5972.w) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) + (((tmp5972.w) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))) + (((tmp5972.w) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))))), ((c_glsl_const_01.v_o * ((((tmp5972.w) / length(tmp5972)) * ((tmp5972.w) / length(tmp5972))) + (((tmp5972.y) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp5972.y) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) - (((tmp5972.w) / length(tmp5972)) * ((tmp5972.x) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.x) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) - (((tmp5972.w) / length(tmp5972)) * ((tmp5972.y) / length(tmp5972))))), (c_glsl_const_01.v_o * ((((tmp5972.y) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))) + (((tmp5972.w) / length(tmp5972)) * ((tmp5972.x) / length(tmp5972))))), ((c_glsl_const_01.v_o * ((((tmp5972.w) / length(tmp5972)) * ((tmp5972.w) / length(tmp5972))) + (((tmp5972.z) / length(tmp5972)) * ((tmp5972.z) / length(tmp5972))))) - c_glsl_const_02.v_o)) * (((((((tmp6500))) - (u_neo_elem_23_transform.v_trans))) / vec3<f32>((u_neo_elem_23_transform.v_scale), (u_neo_elem_23_transform.v_scale), (u_neo_elem_23_transform.v_scale))))).z));
	let tmp5896: f32 = ((tmp5883.z) / tmp5884);
	let tmp2286: f32 = mix(mix((tmp2312.w), (tmp2312.y), step(c_glsl_const_00.v_o, (tmp2314.x))), mix((tmp2312.z), (tmp2312.x), step(c_glsl_const_00.v_o, (tmp2314.x))), step(c_glsl_const_00.v_o, (tmp2314.y)));
	let tmp2084: t_neo_elem_24_prim = u_neo_elem_24_prim;
	let tmp6589: vec3<f32> = ((((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))))));
	let tmp2481: vec2<f32> = vec2<f32>((((min(max((tmp2436.x), (tmp2436.y)), c_glsl_const_00.v_o) + (length(max(tmp2436, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2440))) + mix((tmp2495.y), (tmp2495.x), step(c_glsl_const_00.v_o, (tmp2423.y)))), (abs((tmp2423.y)) - (tmp2499.v_height)));
	let tmp6042: f32 = (u_neo_elem_22_transform.v_scale);
	let tmp2497: f32 = (tmp2423.y);
	let tmp5973: f32 = length(tmp5972);
	let tmp2565: f32 = mix((tmp2572.y), (tmp2572.x), step(c_glsl_const_00.v_o, tmp2574));
	let tmp2422: t_neo_elem_20_mod = u_neo_elem_20_mod;
	let tmp2083: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))) - ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) - ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) - ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6589))) - (u_neo_elem_24_transform.v_trans))) / vec3<f32>((u_neo_elem_24_transform.v_scale), (u_neo_elem_24_transform.v_scale), (u_neo_elem_24_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))) - ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) - ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) - ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).y) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).x) / length((u_neo_elem_24_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).w) / length((u_neo_elem_24_transform.v_quat)))) + ((((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat))) * (((u_neo_elem_24_transform.v_quat).z) / length((u_neo_elem_24_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6589))) - (u_neo_elem_24_transform.v_trans))) / vec3<f32>((u_neo_elem_24_transform.v_scale), (u_neo_elem_24_transform.v_scale), (u_neo_elem_24_transform.v_scale))))).z));
	let tmp6061: vec4<f32> = (u_neo_elem_24_transform.v_quat);
	let tmp2418: vec2<f32> = (tmp2422.v_radius);
	let tmp5982: f32 = ((tmp5972.y) / tmp5973);
	let tmp2346: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5708 * tmp5708) + (tmp5711 * tmp5711))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5711 * tmp5714) - (tmp5708 * tmp5717))), (c_glsl_const_01.v_o * ((tmp5711 * tmp5717) + (tmp5708 * tmp5714))), (c_glsl_const_01.v_o * ((tmp5711 * tmp5714) + (tmp5708 * tmp5717))), ((c_glsl_const_01.v_o * ((tmp5708 * tmp5708) + (tmp5714 * tmp5714))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5714 * tmp5717) - (tmp5708 * tmp5711))), (c_glsl_const_01.v_o * ((tmp5711 * tmp5717) - (tmp5708 * tmp5714))), (c_glsl_const_01.v_o * ((tmp5714 * tmp5717) + (tmp5708 * tmp5711))), ((c_glsl_const_01.v_o * ((tmp5708 * tmp5708) + (tmp5717 * tmp5717))) - c_glsl_const_02.v_o)) * (((((((tmp6233))) - (u_neo_elem_20_transform.v_trans))) / vec3<f32>(tmp5864, tmp5864, tmp5864))));
	let tmp5979: f32 = ((tmp5972.x) / tmp5973);
	let tmp2128: vec2<f32> = ((abs(tmp2160) - (tmp2161.v_dims)) + vec2<f32>(mix(mix((tmp2158.w), (tmp2158.y), step(c_glsl_const_00.v_o, (tmp2160.x))), mix((tmp2158.z), (tmp2158.x), step(c_glsl_const_00.v_o, (tmp2160.x))), step(c_glsl_const_00.v_o, (tmp2160.y))), mix(mix((tmp2158.w), (tmp2158.y), step(c_glsl_const_00.v_o, (tmp2160.x))), mix((tmp2158.z), (tmp2158.x), step(c_glsl_const_00.v_o, (tmp2160.x))), step(c_glsl_const_00.v_o, (tmp2160.y)))));
	let tmp8533: t_neo_elem_17_transform = u_neo_elem_17_transform;
	let tmp5976: f32 = ((tmp5972.w) / tmp5973);
	let tmp2081: vec4<f32> = (tmp2084.v_radius);
	let tmp5985: f32 = ((tmp5972.z) / tmp5973);
	let tmp2209: f32 = mix(mix((tmp2235.w), (tmp2235.y), step(c_glsl_const_00.v_o, (tmp2237.x))), mix((tmp2235.z), (tmp2235.x), step(c_glsl_const_00.v_o, (tmp2237.x))), step(c_glsl_const_00.v_o, (tmp2237.y)));
	let tmp6131: f32 = (u_neo_elem_23_transform.v_scale);
	let tmp6678: vec3<f32> = (((((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))))));
	let tmp2488: f32 = mix((tmp2495.y), (tmp2495.x), step(c_glsl_const_00.v_o, tmp2497));
	let tmp2345: t_neo_elem_21_mod = u_neo_elem_21_mod;
	let tmp2007: t_neo_elem_25_prim = u_neo_elem_25_prim;
	let tmp6062: f32 = length(tmp6061);
	let tmp2420: f32 = (tmp2346.y);
	let tmp2404: vec2<f32> = vec2<f32>((((min(max((tmp2359.x), (tmp2359.y)), c_glsl_const_00.v_o) + (length(max(tmp2359, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2363))) + mix((tmp2418.y), (tmp2418.x), step(c_glsl_const_00.v_o, tmp2420))), (abs(tmp2420) - (tmp2422.v_height)));
	let tmp2006: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))) - ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) - ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) - ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6678))) - (u_neo_elem_25_transform.v_trans))) / vec3<f32>((u_neo_elem_25_transform.v_scale), (u_neo_elem_25_transform.v_scale), (u_neo_elem_25_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))) - ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) - ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) - ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).y) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).x) / length((u_neo_elem_25_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).w) / length((u_neo_elem_25_transform.v_quat)))) + ((((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat))) * (((u_neo_elem_25_transform.v_quat).z) / length((u_neo_elem_25_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6678))) - (u_neo_elem_25_transform.v_trans))) / vec3<f32>((u_neo_elem_25_transform.v_scale), (u_neo_elem_25_transform.v_scale), (u_neo_elem_25_transform.v_scale))))).z));
	let tmp2341: vec2<f32> = (tmp2345.v_radius);
	let tmp2132: f32 = mix(mix((tmp2158.w), (tmp2158.y), step(c_glsl_const_00.v_o, (tmp2160.x))), mix((tmp2158.z), (tmp2158.x), step(c_glsl_const_00.v_o, (tmp2160.x))), step(c_glsl_const_00.v_o, (tmp2160.y)));
	let tmp6150: vec4<f32> = (u_neo_elem_25_transform.v_quat);
	let tmp2051: vec2<f32> = ((abs(tmp2083) - (tmp2084.v_dims)) + vec2<f32>(mix(mix((tmp2081.w), (tmp2081.y), step(c_glsl_const_00.v_o, (tmp2083.x))), mix((tmp2081.z), (tmp2081.x), step(c_glsl_const_00.v_o, (tmp2083.x))), step(c_glsl_const_00.v_o, (tmp2083.y))), mix(mix((tmp2081.w), (tmp2081.y), step(c_glsl_const_00.v_o, (tmp2083.x))), mix((tmp2081.z), (tmp2081.x), step(c_glsl_const_00.v_o, (tmp2083.x))), step(c_glsl_const_00.v_o, (tmp2083.y)))));
	let tmp2004: vec4<f32> = (tmp2007.v_radius);
	let tmp2269: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5798 * tmp5798) + (tmp5801 * tmp5801))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5801 * tmp5804) - (tmp5798 * tmp5807))), (c_glsl_const_01.v_o * ((tmp5801 * tmp5807) + (tmp5798 * tmp5804))), (c_glsl_const_01.v_o * ((tmp5801 * tmp5804) + (tmp5798 * tmp5807))), ((c_glsl_const_01.v_o * ((tmp5798 * tmp5798) + (tmp5804 * tmp5804))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5804 * tmp5807) - (tmp5798 * tmp5801))), (c_glsl_const_01.v_o * ((tmp5801 * tmp5807) - (tmp5798 * tmp5804))), (c_glsl_const_01.v_o * ((tmp5804 * tmp5807) + (tmp5798 * tmp5801))), ((c_glsl_const_01.v_o * ((tmp5798 * tmp5798) + (tmp5807 * tmp5807))) - c_glsl_const_02.v_o)) * (((((((tmp6322))) - (u_neo_elem_21_transform.v_trans))) / vec3<f32>(tmp5953, tmp5953, tmp5953))));
	let tmp8534: t_neo_elem_18_transform = u_neo_elem_18_transform;
	let tmp6074: f32 = ((tmp6061.z) / tmp6062);
	let tmp6065: f32 = ((tmp6061.w) / tmp6062);
	let tmp6068: f32 = ((tmp6061.x) / tmp6062);
	let tmp6071: f32 = ((tmp6061.y) / tmp6062);
	let tmp1930: t_neo_elem_26_prim = u_neo_elem_26_prim;
	let tmp2268: t_neo_elem_22_mod = u_neo_elem_22_mod;
	let tmp6767: vec3<f32> = ((((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))))));
	let tmp2411: f32 = mix((tmp2418.y), (tmp2418.x), step(c_glsl_const_00.v_o, tmp2420));
	let tmp2343: f32 = (tmp2269.y);
	let tmp2327: vec2<f32> = vec2<f32>((((min(max((tmp2282.x), (tmp2282.y)), c_glsl_const_00.v_o) + (length(max(tmp2282, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2286))) + mix((tmp2341.y), (tmp2341.x), step(c_glsl_const_00.v_o, tmp2343))), (abs(tmp2343) - (tmp2345.v_height)));
	let tmp6220: f32 = (u_neo_elem_24_transform.v_scale);
	let tmp6151: f32 = length(tmp6150);
	let tmp1853: t_neo_elem_27_prim = u_neo_elem_27_prim;
	let tmp2192: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5887 * tmp5887) + (tmp5890 * tmp5890))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5890 * tmp5893) - (tmp5887 * tmp5896))), (c_glsl_const_01.v_o * ((tmp5890 * tmp5896) + (tmp5887 * tmp5893))), (c_glsl_const_01.v_o * ((tmp5890 * tmp5893) + (tmp5887 * tmp5896))), ((c_glsl_const_01.v_o * ((tmp5887 * tmp5887) + (tmp5893 * tmp5893))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5893 * tmp5896) - (tmp5887 * tmp5890))), (c_glsl_const_01.v_o * ((tmp5890 * tmp5896) - (tmp5887 * tmp5893))), (c_glsl_const_01.v_o * ((tmp5893 * tmp5896) + (tmp5887 * tmp5890))), ((c_glsl_const_01.v_o * ((tmp5887 * tmp5887) + (tmp5896 * tmp5896))) - c_glsl_const_02.v_o)) * (((((((tmp6411))) - (u_neo_elem_22_transform.v_trans))) / vec3<f32>(tmp6042, tmp6042, tmp6042))));
	let tmp2055: f32 = mix(mix((tmp2081.w), (tmp2081.y), step(c_glsl_const_00.v_o, (tmp2083.x))), mix((tmp2081.z), (tmp2081.x), step(c_glsl_const_00.v_o, (tmp2083.x))), step(c_glsl_const_00.v_o, (tmp2083.y)));
	let tmp6857: vec3<f32> = (((((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))))));
	let tmp6239: vec4<f32> = (u_neo_elem_26_transform.v_quat);
	let tmp2264: vec2<f32> = (tmp2268.v_radius);
	let tmp6160: f32 = ((tmp6150.y) / tmp6151);
	let tmp6163: f32 = ((tmp6150.z) / tmp6151);
	let tmp6157: f32 = ((tmp6150.x) / tmp6151);
	let tmp1929: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp6239.w) / length(tmp6239)) * ((tmp6239.w) / length(tmp6239))) + (((tmp6239.x) / length(tmp6239)) * ((tmp6239.x) / length(tmp6239))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))) - (((tmp6239.w) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) + (((tmp6239.w) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))) + (((tmp6239.w) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))))), ((c_glsl_const_01.v_o * ((((tmp6239.w) / length(tmp6239)) * ((tmp6239.w) / length(tmp6239))) + (((tmp6239.y) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6239.y) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) - (((tmp6239.w) / length(tmp6239)) * ((tmp6239.x) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) - (((tmp6239.w) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.y) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) + (((tmp6239.w) / length(tmp6239)) * ((tmp6239.x) / length(tmp6239))))), ((c_glsl_const_01.v_o * ((((tmp6239.w) / length(tmp6239)) * ((tmp6239.w) / length(tmp6239))) + (((tmp6239.z) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))))) - c_glsl_const_02.v_o)) * (((((((tmp6767))) - (u_neo_elem_26_transform.v_trans))) / vec3<f32>((u_neo_elem_26_transform.v_scale), (u_neo_elem_26_transform.v_scale), (u_neo_elem_26_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp6239.w) / length(tmp6239)) * ((tmp6239.w) / length(tmp6239))) + (((tmp6239.x) / length(tmp6239)) * ((tmp6239.x) / length(tmp6239))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))) - (((tmp6239.w) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) + (((tmp6239.w) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))) + (((tmp6239.w) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))))), ((c_glsl_const_01.v_o * ((((tmp6239.w) / length(tmp6239)) * ((tmp6239.w) / length(tmp6239))) + (((tmp6239.y) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6239.y) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) - (((tmp6239.w) / length(tmp6239)) * ((tmp6239.x) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.x) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) - (((tmp6239.w) / length(tmp6239)) * ((tmp6239.y) / length(tmp6239))))), (c_glsl_const_01.v_o * ((((tmp6239.y) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))) + (((tmp6239.w) / length(tmp6239)) * ((tmp6239.x) / length(tmp6239))))), ((c_glsl_const_01.v_o * ((((tmp6239.w) / length(tmp6239)) * ((tmp6239.w) / length(tmp6239))) + (((tmp6239.z) / length(tmp6239)) * ((tmp6239.z) / length(tmp6239))))) - c_glsl_const_02.v_o)) * (((((((tmp6767))) - (u_neo_elem_26_transform.v_trans))) / vec3<f32>((u_neo_elem_26_transform.v_scale), (u_neo_elem_26_transform.v_scale), (u_neo_elem_26_transform.v_scale))))).z));
	let tmp1974: vec2<f32> = ((abs(tmp2006) - (tmp2007.v_dims)) + vec2<f32>(mix(mix((tmp2004.w), (tmp2004.y), step(c_glsl_const_00.v_o, (tmp2006.x))), mix((tmp2004.z), (tmp2004.x), step(c_glsl_const_00.v_o, (tmp2006.x))), step(c_glsl_const_00.v_o, (tmp2006.y))), mix(mix((tmp2004.w), (tmp2004.y), step(c_glsl_const_00.v_o, (tmp2006.x))), mix((tmp2004.z), (tmp2004.x), step(c_glsl_const_00.v_o, (tmp2006.x))), step(c_glsl_const_00.v_o, (tmp2006.y)))));
	let tmp1927: vec4<f32> = (tmp1930.v_radius);
	let tmp6154: f32 = ((tmp6150.w) / tmp6151);
	let tmp8535: t_neo_elem_19_transform = u_neo_elem_19_transform;
	let tmp1852: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))) - ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) - ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) - ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6857))) - (u_neo_elem_27_transform.v_trans))) / vec3<f32>((u_neo_elem_27_transform.v_scale), (u_neo_elem_27_transform.v_scale), (u_neo_elem_27_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))) - ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) - ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) - ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).y) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).x) / length((u_neo_elem_27_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).w) / length((u_neo_elem_27_transform.v_quat)))) + ((((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat))) * (((u_neo_elem_27_transform.v_quat).z) / length((u_neo_elem_27_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6857))) - (u_neo_elem_27_transform.v_trans))) / vec3<f32>((u_neo_elem_27_transform.v_scale), (u_neo_elem_27_transform.v_scale), (u_neo_elem_27_transform.v_scale))))).z));
	let tmp1850: vec4<f32> = (tmp1853.v_radius);
	let tmp2334: f32 = mix((tmp2341.y), (tmp2341.x), step(c_glsl_const_00.v_o, tmp2343));
	let tmp6240: f32 = length(tmp6239);
	let tmp6328: vec4<f32> = (u_neo_elem_27_transform.v_quat);
	let tmp2266: f32 = (tmp2192.y);
	let tmp6309: f32 = (u_neo_elem_25_transform.v_scale);
	let tmp2191: t_neo_elem_23_mod = u_neo_elem_23_mod;
	let tmp2250: vec2<f32> = vec2<f32>((((min(max((tmp2205.x), (tmp2205.y)), c_glsl_const_00.v_o) + (length(max(tmp2205, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2209))) + mix((tmp2264.y), (tmp2264.x), step(c_glsl_const_00.v_o, tmp2266))), (abs(tmp2266) - (tmp2268.v_height)));
	let tmp8536: t_neo_elem_20_transform = u_neo_elem_20_transform;
	let tmp1897: vec2<f32> = ((abs(tmp1929) - (tmp1930.v_dims)) + vec2<f32>(mix(mix((tmp1927.w), (tmp1927.y), step(c_glsl_const_00.v_o, (tmp1929.x))), mix((tmp1927.z), (tmp1927.x), step(c_glsl_const_00.v_o, (tmp1929.x))), step(c_glsl_const_00.v_o, (tmp1929.y))), mix(mix((tmp1927.w), (tmp1927.y), step(c_glsl_const_00.v_o, (tmp1929.x))), mix((tmp1927.z), (tmp1927.x), step(c_glsl_const_00.v_o, (tmp1929.x))), step(c_glsl_const_00.v_o, (tmp1929.y)))));
	let tmp6329: f32 = length(tmp6328);
	let tmp2115: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp5976 * tmp5976) + (tmp5979 * tmp5979))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5979 * tmp5982) - (tmp5976 * tmp5985))), (c_glsl_const_01.v_o * ((tmp5979 * tmp5985) + (tmp5976 * tmp5982))), (c_glsl_const_01.v_o * ((tmp5979 * tmp5982) + (tmp5976 * tmp5985))), ((c_glsl_const_01.v_o * ((tmp5976 * tmp5976) + (tmp5982 * tmp5982))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp5982 * tmp5985) - (tmp5976 * tmp5979))), (c_glsl_const_01.v_o * ((tmp5979 * tmp5985) - (tmp5976 * tmp5982))), (c_glsl_const_01.v_o * ((tmp5982 * tmp5985) + (tmp5976 * tmp5979))), ((c_glsl_const_01.v_o * ((tmp5976 * tmp5976) + (tmp5985 * tmp5985))) - c_glsl_const_02.v_o)) * (((((((tmp6500))) - (u_neo_elem_23_transform.v_trans))) / vec3<f32>(tmp6131, tmp6131, tmp6131))));
	let tmp6246: f32 = ((tmp6239.x) / tmp6240);
	let tmp6243: f32 = ((tmp6239.w) / tmp6240);
	let tmp1978: f32 = mix(mix((tmp2004.w), (tmp2004.y), step(c_glsl_const_00.v_o, (tmp2006.x))), mix((tmp2004.z), (tmp2004.x), step(c_glsl_const_00.v_o, (tmp2006.x))), step(c_glsl_const_00.v_o, (tmp2006.y)));
	let tmp2187: vec2<f32> = (tmp2191.v_radius);
	let tmp6252: f32 = ((tmp6239.z) / tmp6240);
	let tmp6249: f32 = ((tmp6239.y) / tmp6240);
	let tmp6338: f32 = ((tmp6328.y) / tmp6329);
	let tmp6332: f32 = ((tmp6328.w) / tmp6329);
	let tmp6335: f32 = ((tmp6328.x) / tmp6329);
	let tmp2257: f32 = mix((tmp2264.y), (tmp2264.x), step(c_glsl_const_00.v_o, tmp2266));
	let tmp1776: t_neo_elem_28_prim = u_neo_elem_28_prim;
	let tmp2173: vec2<f32> = vec2<f32>((((min(max((tmp2128.x), (tmp2128.y)), c_glsl_const_00.v_o) + (length(max(tmp2128, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2132))) + mix((tmp2187.y), (tmp2187.x), step(c_glsl_const_00.v_o, (tmp2115.y)))), (abs((tmp2115.y)) - (tmp2191.v_height)));
	let tmp1820: vec2<f32> = ((abs(tmp1852) - (tmp1853.v_dims)) + vec2<f32>(mix(mix((tmp1850.w), (tmp1850.y), step(c_glsl_const_00.v_o, (tmp1852.x))), mix((tmp1850.z), (tmp1850.x), step(c_glsl_const_00.v_o, (tmp1852.x))), step(c_glsl_const_00.v_o, (tmp1852.y))), mix(mix((tmp1850.w), (tmp1850.y), step(c_glsl_const_00.v_o, (tmp1852.x))), mix((tmp1850.z), (tmp1850.x), step(c_glsl_const_00.v_o, (tmp1852.x))), step(c_glsl_const_00.v_o, (tmp1852.y)))));
	let tmp6946: vec3<f32> = ((((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))))));
	let tmp2114: t_neo_elem_24_mod = u_neo_elem_24_mod;
	let tmp6398: f32 = (u_neo_elem_26_transform.v_scale);
	let tmp6341: f32 = ((tmp6328.z) / tmp6329);
	let tmp2189: f32 = (tmp2115.y);
	let tmp1775: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))) - ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) - ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) - ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6946))) - (u_neo_elem_28_transform.v_trans))) / vec3<f32>((u_neo_elem_28_transform.v_scale), (u_neo_elem_28_transform.v_scale), (u_neo_elem_28_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))) - ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) - ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) - ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).y) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).x) / length((u_neo_elem_28_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).w) / length((u_neo_elem_28_transform.v_quat)))) + ((((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat))) * (((u_neo_elem_28_transform.v_quat).z) / length((u_neo_elem_28_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp6946))) - (u_neo_elem_28_transform.v_trans))) / vec3<f32>((u_neo_elem_28_transform.v_scale), (u_neo_elem_28_transform.v_scale), (u_neo_elem_28_transform.v_scale))))).z));
	let tmp1773: vec4<f32> = (tmp1776.v_radius);
	let tmp8537: t_neo_elem_21_transform = u_neo_elem_21_transform;
	let tmp1699: t_neo_elem_29_prim = u_neo_elem_29_prim;
	let tmp2038: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6065 * tmp6065) + (tmp6068 * tmp6068))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6068 * tmp6071) - (tmp6065 * tmp6074))), (c_glsl_const_01.v_o * ((tmp6068 * tmp6074) + (tmp6065 * tmp6071))), (c_glsl_const_01.v_o * ((tmp6068 * tmp6071) + (tmp6065 * tmp6074))), ((c_glsl_const_01.v_o * ((tmp6065 * tmp6065) + (tmp6071 * tmp6071))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6071 * tmp6074) - (tmp6065 * tmp6068))), (c_glsl_const_01.v_o * ((tmp6068 * tmp6074) - (tmp6065 * tmp6071))), (c_glsl_const_01.v_o * ((tmp6071 * tmp6074) + (tmp6065 * tmp6068))), ((c_glsl_const_01.v_o * ((tmp6065 * tmp6065) + (tmp6074 * tmp6074))) - c_glsl_const_02.v_o)) * (((((((tmp6589))) - (u_neo_elem_24_transform.v_trans))) / vec3<f32>(tmp6220, tmp6220, tmp6220))));
	let tmp6487: f32 = (u_neo_elem_27_transform.v_scale);
	let tmp7036: vec3<f32> = (((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))))));
	let tmp1901: f32 = mix(mix((tmp1927.w), (tmp1927.y), step(c_glsl_const_00.v_o, (tmp1929.x))), mix((tmp1927.z), (tmp1927.x), step(c_glsl_const_00.v_o, (tmp1929.x))), step(c_glsl_const_00.v_o, (tmp1929.y)));
	let tmp6417: vec4<f32> = (u_neo_elem_28_transform.v_quat);
	let tmp2110: vec2<f32> = (tmp2114.v_radius);
	let tmp6418: f32 = length(tmp6417);
	let tmp2180: f32 = mix((tmp2187.y), (tmp2187.x), step(c_glsl_const_00.v_o, tmp2189));
	let tmp2096: vec2<f32> = vec2<f32>((((min(max((tmp2051.x), (tmp2051.y)), c_glsl_const_00.v_o) + (length(max(tmp2051, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2055))) + mix((tmp2110.y), (tmp2110.x), step(c_glsl_const_00.v_o, (tmp2038.y)))), (abs((tmp2038.y)) - (tmp2114.v_height)));
	let tmp2112: f32 = (tmp2038.y);
	let tmp2037: t_neo_elem_25_mod = u_neo_elem_25_mod;
	let tmp1698: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))) - ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) - ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) - ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7036))) - (u_neo_elem_29_transform.v_trans))) / vec3<f32>((u_neo_elem_29_transform.v_scale), (u_neo_elem_29_transform.v_scale), (u_neo_elem_29_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))) - ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) - ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) - ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).y) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).x) / length((u_neo_elem_29_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).w) / length((u_neo_elem_29_transform.v_quat)))) + ((((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat))) * (((u_neo_elem_29_transform.v_quat).z) / length((u_neo_elem_29_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7036))) - (u_neo_elem_29_transform.v_trans))) / vec3<f32>((u_neo_elem_29_transform.v_scale), (u_neo_elem_29_transform.v_scale), (u_neo_elem_29_transform.v_scale))))).z));
	let tmp6506: vec4<f32> = (u_neo_elem_29_transform.v_quat);
	let tmp1696: vec4<f32> = (tmp1699.v_radius);
	let tmp1824: f32 = mix(mix((tmp1850.w), (tmp1850.y), step(c_glsl_const_00.v_o, (tmp1852.x))), mix((tmp1850.z), (tmp1850.x), step(c_glsl_const_00.v_o, (tmp1852.x))), step(c_glsl_const_00.v_o, (tmp1852.y)));
	let tmp2033: vec2<f32> = (tmp2037.v_radius);
	let tmp6421: f32 = ((tmp6417.w) / tmp6418);
	let tmp1961: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6154 * tmp6154) + (tmp6157 * tmp6157))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6157 * tmp6160) - (tmp6154 * tmp6163))), (c_glsl_const_01.v_o * ((tmp6157 * tmp6163) + (tmp6154 * tmp6160))), (c_glsl_const_01.v_o * ((tmp6157 * tmp6160) + (tmp6154 * tmp6163))), ((c_glsl_const_01.v_o * ((tmp6154 * tmp6154) + (tmp6160 * tmp6160))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6160 * tmp6163) - (tmp6154 * tmp6157))), (c_glsl_const_01.v_o * ((tmp6157 * tmp6163) - (tmp6154 * tmp6160))), (c_glsl_const_01.v_o * ((tmp6160 * tmp6163) + (tmp6154 * tmp6157))), ((c_glsl_const_01.v_o * ((tmp6154 * tmp6154) + (tmp6163 * tmp6163))) - c_glsl_const_02.v_o)) * (((((((tmp6678))) - (u_neo_elem_25_transform.v_trans))) / vec3<f32>(tmp6309, tmp6309, tmp6309))));
	let tmp8538: t_neo_elem_22_transform = u_neo_elem_22_transform;
	let tmp6427: f32 = ((tmp6417.y) / tmp6418);
	let tmp1743: vec2<f32> = ((abs(tmp1775) - (tmp1776.v_dims)) + vec2<f32>(mix(mix((tmp1773.w), (tmp1773.y), step(c_glsl_const_00.v_o, (tmp1775.x))), mix((tmp1773.z), (tmp1773.x), step(c_glsl_const_00.v_o, (tmp1775.x))), step(c_glsl_const_00.v_o, (tmp1775.y))), mix(mix((tmp1773.w), (tmp1773.y), step(c_glsl_const_00.v_o, (tmp1775.x))), mix((tmp1773.z), (tmp1773.x), step(c_glsl_const_00.v_o, (tmp1775.x))), step(c_glsl_const_00.v_o, (tmp1775.y)))));
	let tmp6424: f32 = ((tmp6417.x) / tmp6418);
	let tmp6507: f32 = length(tmp6506);
	let tmp6430: f32 = ((tmp6417.z) / tmp6418);
	let tmp6510: f32 = ((tmp6506.w) / tmp6507);
	let tmp2103: f32 = mix((tmp2110.y), (tmp2110.x), step(c_glsl_const_00.v_o, tmp2112));
	let tmp2019: vec2<f32> = vec2<f32>((((min(max((tmp1974.x), (tmp1974.y)), c_glsl_const_00.v_o) + (length(max(tmp1974, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1978))) + mix((tmp2033.y), (tmp2033.x), step(c_glsl_const_00.v_o, (tmp1961.y)))), (abs((tmp1961.y)) - (tmp2037.v_height)));
	let tmp7125: vec3<f32> = ((((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))))));
	let tmp6576: f32 = (u_neo_elem_28_transform.v_scale);
	let tmp2035: f32 = (tmp1961.y);
	let tmp6519: f32 = ((tmp6506.z) / tmp6507);
	let tmp6516: f32 = ((tmp6506.y) / tmp6507);
	let tmp1960: t_neo_elem_26_mod = u_neo_elem_26_mod;
	let tmp6513: f32 = ((tmp6506.x) / tmp6507);
	let tmp1666: vec2<f32> = ((abs(tmp1698) - (tmp1699.v_dims)) + vec2<f32>(mix(mix((tmp1696.w), (tmp1696.y), step(c_glsl_const_00.v_o, (tmp1698.x))), mix((tmp1696.z), (tmp1696.x), step(c_glsl_const_00.v_o, (tmp1698.x))), step(c_glsl_const_00.v_o, (tmp1698.y))), mix(mix((tmp1696.w), (tmp1696.y), step(c_glsl_const_00.v_o, (tmp1698.x))), mix((tmp1696.z), (tmp1696.x), step(c_glsl_const_00.v_o, (tmp1698.x))), step(c_glsl_const_00.v_o, (tmp1698.y)))));
	let tmp1622: t_neo_elem_30_prim = u_neo_elem_30_prim;
	let tmp6665: f32 = (u_neo_elem_29_transform.v_scale);
	let tmp1621: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))) - ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) - ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) - ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7125))) - (u_neo_elem_30_transform.v_trans))) / vec3<f32>((u_neo_elem_30_transform.v_scale), (u_neo_elem_30_transform.v_scale), (u_neo_elem_30_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))) - ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) - ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) - ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).y) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).x) / length((u_neo_elem_30_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).w) / length((u_neo_elem_30_transform.v_quat)))) + ((((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat))) * (((u_neo_elem_30_transform.v_quat).z) / length((u_neo_elem_30_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7125))) - (u_neo_elem_30_transform.v_trans))) / vec3<f32>((u_neo_elem_30_transform.v_scale), (u_neo_elem_30_transform.v_scale), (u_neo_elem_30_transform.v_scale))))).z));
	let tmp6595: vec4<f32> = (u_neo_elem_30_transform.v_quat);
	let tmp8539: t_neo_elem_23_transform = u_neo_elem_23_transform;
	let tmp1884: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6243 * tmp6243) + (tmp6246 * tmp6246))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6246 * tmp6249) - (tmp6243 * tmp6252))), (c_glsl_const_01.v_o * ((tmp6246 * tmp6252) + (tmp6243 * tmp6249))), (c_glsl_const_01.v_o * ((tmp6246 * tmp6249) + (tmp6243 * tmp6252))), ((c_glsl_const_01.v_o * ((tmp6243 * tmp6243) + (tmp6249 * tmp6249))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6249 * tmp6252) - (tmp6243 * tmp6246))), (c_glsl_const_01.v_o * ((tmp6246 * tmp6252) - (tmp6243 * tmp6249))), (c_glsl_const_01.v_o * ((tmp6249 * tmp6252) + (tmp6243 * tmp6246))), ((c_glsl_const_01.v_o * ((tmp6243 * tmp6243) + (tmp6252 * tmp6252))) - c_glsl_const_02.v_o)) * (((((((tmp6767))) - (u_neo_elem_26_transform.v_trans))) / vec3<f32>(tmp6398, tmp6398, tmp6398))));
	let tmp1883: t_neo_elem_27_mod = u_neo_elem_27_mod;
	let tmp1619: vec4<f32> = (tmp1622.v_radius);
	let tmp1747: f32 = mix(mix((tmp1773.w), (tmp1773.y), step(c_glsl_const_00.v_o, (tmp1775.x))), mix((tmp1773.z), (tmp1773.x), step(c_glsl_const_00.v_o, (tmp1775.x))), step(c_glsl_const_00.v_o, (tmp1775.y)));
	let tmp1956: vec2<f32> = (tmp1960.v_radius);
	let tmp1879: vec2<f32> = (tmp1883.v_radius);
	let tmp1807: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6332 * tmp6332) + (tmp6335 * tmp6335))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6335 * tmp6338) - (tmp6332 * tmp6341))), (c_glsl_const_01.v_o * ((tmp6335 * tmp6341) + (tmp6332 * tmp6338))), (c_glsl_const_01.v_o * ((tmp6335 * tmp6338) + (tmp6332 * tmp6341))), ((c_glsl_const_01.v_o * ((tmp6332 * tmp6332) + (tmp6338 * tmp6338))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6338 * tmp6341) - (tmp6332 * tmp6335))), (c_glsl_const_01.v_o * ((tmp6335 * tmp6341) - (tmp6332 * tmp6338))), (c_glsl_const_01.v_o * ((tmp6338 * tmp6341) + (tmp6332 * tmp6335))), ((c_glsl_const_01.v_o * ((tmp6332 * tmp6332) + (tmp6341 * tmp6341))) - c_glsl_const_02.v_o)) * (((((((tmp6857))) - (u_neo_elem_27_transform.v_trans))) / vec3<f32>(tmp6487, tmp6487, tmp6487))));
	let tmp7214: vec3<f32> = (((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))))));
	let tmp1942: vec2<f32> = vec2<f32>((((min(max((tmp1897.x), (tmp1897.y)), c_glsl_const_00.v_o) + (length(max(tmp1897, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1901))) + mix((tmp1956.y), (tmp1956.x), step(c_glsl_const_00.v_o, (tmp1884.y)))), (abs((tmp1884.y)) - (tmp1960.v_height)));
	let tmp1545: t_neo_elem_31_prim = u_neo_elem_31_prim;
	let tmp2026: f32 = mix((tmp2033.y), (tmp2033.x), step(c_glsl_const_00.v_o, tmp2035));
	let tmp1670: f32 = mix(mix((tmp1696.w), (tmp1696.y), step(c_glsl_const_00.v_o, (tmp1698.x))), mix((tmp1696.z), (tmp1696.x), step(c_glsl_const_00.v_o, (tmp1698.x))), step(c_glsl_const_00.v_o, (tmp1698.y)));
	let tmp1958: f32 = (tmp1884.y);
	let tmp6596: f32 = length(tmp6595);
	let tmp1865: vec2<f32> = vec2<f32>((((min(max((tmp1820.x), (tmp1820.y)), c_glsl_const_00.v_o) + (length(max(tmp1820, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1824))) + mix((tmp1879.y), (tmp1879.x), step(c_glsl_const_00.v_o, (tmp1807.y)))), (abs((tmp1807.y)) - (tmp1883.v_height)));
	let tmp1468: t_neo_elem_32_prim = u_neo_elem_32_prim;
	let tmp1542: vec4<f32> = (tmp1545.v_radius);
	let tmp1589: vec2<f32> = ((abs(tmp1621) - (tmp1622.v_dims)) + vec2<f32>(mix(mix((tmp1619.w), (tmp1619.y), step(c_glsl_const_00.v_o, (tmp1621.x))), mix((tmp1619.z), (tmp1619.x), step(c_glsl_const_00.v_o, (tmp1621.x))), step(c_glsl_const_00.v_o, (tmp1621.y))), mix(mix((tmp1619.w), (tmp1619.y), step(c_glsl_const_00.v_o, (tmp1621.x))), mix((tmp1619.z), (tmp1619.x), step(c_glsl_const_00.v_o, (tmp1621.x))), step(c_glsl_const_00.v_o, (tmp1621.y)))));
	let tmp1544: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))) - ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) - ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) - ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7214))) - (u_neo_elem_31_transform.v_trans))) / vec3<f32>((u_neo_elem_31_transform.v_scale), (u_neo_elem_31_transform.v_scale), (u_neo_elem_31_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))) - ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) - ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) - ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).y) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).x) / length((u_neo_elem_31_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).w) / length((u_neo_elem_31_transform.v_quat)))) + ((((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat))) * (((u_neo_elem_31_transform.v_quat).z) / length((u_neo_elem_31_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7214))) - (u_neo_elem_31_transform.v_trans))) / vec3<f32>((u_neo_elem_31_transform.v_scale), (u_neo_elem_31_transform.v_scale), (u_neo_elem_31_transform.v_scale))))).z));
	let tmp8540: t_neo_elem_24_transform = u_neo_elem_24_transform;
	let tmp1881: f32 = (tmp1807.y);
	let tmp7304: vec3<f32> = ((((((((((((((((((t_position(a_pos).v_pos))))))))))))))))));
	let tmp6605: f32 = ((tmp6595.y) / tmp6596);
	let tmp6599: f32 = ((tmp6595.w) / tmp6596);
	let tmp6602: f32 = ((tmp6595.x) / tmp6596);
	let tmp6608: f32 = ((tmp6595.z) / tmp6596);
	let tmp6684: vec4<f32> = (u_neo_elem_31_transform.v_quat);
	let tmp6685: f32 = length(tmp6684);
	let tmp6754: f32 = (u_neo_elem_30_transform.v_scale);
	let tmp1465: vec4<f32> = (tmp1468.v_radius);
	let tmp1467: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))) - ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) - ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) - ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7304))) - (u_neo_elem_32_transform.v_trans))) / vec3<f32>((u_neo_elem_32_transform.v_scale), (u_neo_elem_32_transform.v_scale), (u_neo_elem_32_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))) - ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) - ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) - ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).y) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).x) / length((u_neo_elem_32_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).w) / length((u_neo_elem_32_transform.v_quat)))) + ((((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat))) * (((u_neo_elem_32_transform.v_quat).z) / length((u_neo_elem_32_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7304))) - (u_neo_elem_32_transform.v_trans))) / vec3<f32>((u_neo_elem_32_transform.v_scale), (u_neo_elem_32_transform.v_scale), (u_neo_elem_32_transform.v_scale))))).z));
	let tmp6774: vec4<f32> = (u_neo_elem_32_transform.v_quat);
	let tmp1949: f32 = mix((tmp1956.y), (tmp1956.x), step(c_glsl_const_00.v_o, tmp1958));
	let tmp1806: t_neo_elem_28_mod = u_neo_elem_28_mod;
	let tmp6694: f32 = ((tmp6684.y) / tmp6685);
	let tmp6691: f32 = ((tmp6684.x) / tmp6685);
	let tmp6688: f32 = ((tmp6684.w) / tmp6685);
	let tmp8541: t_neo_elem_25_transform = u_neo_elem_25_transform;
	let tmp1730: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6421 * tmp6421) + (tmp6424 * tmp6424))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6424 * tmp6427) - (tmp6421 * tmp6430))), (c_glsl_const_01.v_o * ((tmp6424 * tmp6430) + (tmp6421 * tmp6427))), (c_glsl_const_01.v_o * ((tmp6424 * tmp6427) + (tmp6421 * tmp6430))), ((c_glsl_const_01.v_o * ((tmp6421 * tmp6421) + (tmp6427 * tmp6427))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6427 * tmp6430) - (tmp6421 * tmp6424))), (c_glsl_const_01.v_o * ((tmp6424 * tmp6430) - (tmp6421 * tmp6427))), (c_glsl_const_01.v_o * ((tmp6427 * tmp6430) + (tmp6421 * tmp6424))), ((c_glsl_const_01.v_o * ((tmp6421 * tmp6421) + (tmp6430 * tmp6430))) - c_glsl_const_02.v_o)) * (((((((tmp6946))) - (u_neo_elem_28_transform.v_trans))) / vec3<f32>(tmp6576, tmp6576, tmp6576))));
	let tmp6697: f32 = ((tmp6684.z) / tmp6685);
	let tmp6775: f32 = length(tmp6774);
	let tmp1593: f32 = mix(mix((tmp1619.w), (tmp1619.y), step(c_glsl_const_00.v_o, (tmp1621.x))), mix((tmp1619.z), (tmp1619.x), step(c_glsl_const_00.v_o, (tmp1621.x))), step(c_glsl_const_00.v_o, (tmp1621.y)));
	let tmp1872: f32 = mix((tmp1879.y), (tmp1879.x), step(c_glsl_const_00.v_o, tmp1881));
	let tmp1729: t_neo_elem_29_mod = u_neo_elem_29_mod;
	let tmp1802: vec2<f32> = (tmp1806.v_radius);
	let tmp1512: vec2<f32> = ((abs(tmp1544) - (tmp1545.v_dims)) + vec2<f32>(mix(mix((tmp1542.w), (tmp1542.y), step(c_glsl_const_00.v_o, (tmp1544.x))), mix((tmp1542.z), (tmp1542.x), step(c_glsl_const_00.v_o, (tmp1544.x))), step(c_glsl_const_00.v_o, (tmp1544.y))), mix(mix((tmp1542.w), (tmp1542.y), step(c_glsl_const_00.v_o, (tmp1544.x))), mix((tmp1542.z), (tmp1542.x), step(c_glsl_const_00.v_o, (tmp1544.x))), step(c_glsl_const_00.v_o, (tmp1544.y)))));
	let tmp6781: f32 = ((tmp6774.x) / tmp6775);
	let tmp6784: f32 = ((tmp6774.y) / tmp6775);
	let tmp1725: vec2<f32> = (tmp1729.v_radius);
	let tmp6787: f32 = ((tmp6774.z) / tmp6775);
	let tmp1653: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6510 * tmp6510) + (tmp6513 * tmp6513))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6513 * tmp6516) - (tmp6510 * tmp6519))), (c_glsl_const_01.v_o * ((tmp6513 * tmp6519) + (tmp6510 * tmp6516))), (c_glsl_const_01.v_o * ((tmp6513 * tmp6516) + (tmp6510 * tmp6519))), ((c_glsl_const_01.v_o * ((tmp6510 * tmp6510) + (tmp6516 * tmp6516))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6516 * tmp6519) - (tmp6510 * tmp6513))), (c_glsl_const_01.v_o * ((tmp6513 * tmp6519) - (tmp6510 * tmp6516))), (c_glsl_const_01.v_o * ((tmp6516 * tmp6519) + (tmp6510 * tmp6513))), ((c_glsl_const_01.v_o * ((tmp6510 * tmp6510) + (tmp6519 * tmp6519))) - c_glsl_const_02.v_o)) * (((((((tmp7036))) - (u_neo_elem_29_transform.v_trans))) / vec3<f32>(tmp6665, tmp6665, tmp6665))));
	let tmp1788: vec2<f32> = vec2<f32>((((min(max((tmp1743.x), (tmp1743.y)), c_glsl_const_00.v_o) + (length(max(tmp1743, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1747))) + mix((tmp1802.y), (tmp1802.x), step(c_glsl_const_00.v_o, (tmp1730.y)))), (abs((tmp1730.y)) - (tmp1806.v_height)));
	let tmp1391: t_neo_elem_33_prim = u_neo_elem_33_prim;
	let tmp1804: f32 = (tmp1730.y);
	let tmp6844: f32 = (u_neo_elem_31_transform.v_scale);
	let tmp6778: f32 = ((tmp6774.w) / tmp6775);
	let tmp1435: vec2<f32> = ((abs(tmp1467) - (tmp1468.v_dims)) + vec2<f32>(mix(mix((tmp1465.w), (tmp1465.y), step(c_glsl_const_00.v_o, (tmp1467.x))), mix((tmp1465.z), (tmp1465.x), step(c_glsl_const_00.v_o, (tmp1467.x))), step(c_glsl_const_00.v_o, (tmp1467.y))), mix(mix((tmp1465.w), (tmp1465.y), step(c_glsl_const_00.v_o, (tmp1467.x))), mix((tmp1465.z), (tmp1465.x), step(c_glsl_const_00.v_o, (tmp1467.x))), step(c_glsl_const_00.v_o, (tmp1467.y)))));
	let tmp7393: vec3<f32> = (((((((((((((((((t_position(a_pos).v_pos)))))))))))))))));
	let tmp8542: t_neo_elem_26_transform = u_neo_elem_26_transform;
	let tmp1711: vec2<f32> = vec2<f32>((((min(max((tmp1666.x), (tmp1666.y)), c_glsl_const_00.v_o) + (length(max(tmp1666, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1670))) + mix((tmp1725.y), (tmp1725.x), step(c_glsl_const_00.v_o, (tmp1653.y)))), (abs((tmp1653.y)) - (tmp1729.v_height)));
	let tmp1516: f32 = mix(mix((tmp1542.w), (tmp1542.y), step(c_glsl_const_00.v_o, (tmp1544.x))), mix((tmp1542.z), (tmp1542.x), step(c_glsl_const_00.v_o, (tmp1544.x))), step(c_glsl_const_00.v_o, (tmp1544.y)));
	let tmp1314: t_neo_elem_34_prim = u_neo_elem_34_prim;
	let tmp6933: f32 = (u_neo_elem_32_transform.v_scale);
	let tmp6863: vec4<f32> = (u_neo_elem_33_transform.v_quat);
	let tmp7483: vec3<f32> = ((((((((((((((((t_position(a_pos).v_pos))))))))))))))));
	let tmp1727: f32 = (tmp1653.y);
	let tmp1390: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp6863.w) / length(tmp6863)) * ((tmp6863.w) / length(tmp6863))) + (((tmp6863.x) / length(tmp6863)) * ((tmp6863.x) / length(tmp6863))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))) - (((tmp6863.w) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) + (((tmp6863.w) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))) + (((tmp6863.w) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))))), ((c_glsl_const_01.v_o * ((((tmp6863.w) / length(tmp6863)) * ((tmp6863.w) / length(tmp6863))) + (((tmp6863.y) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6863.y) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) - (((tmp6863.w) / length(tmp6863)) * ((tmp6863.x) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) - (((tmp6863.w) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.y) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) + (((tmp6863.w) / length(tmp6863)) * ((tmp6863.x) / length(tmp6863))))), ((c_glsl_const_01.v_o * ((((tmp6863.w) / length(tmp6863)) * ((tmp6863.w) / length(tmp6863))) + (((tmp6863.z) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))))) - c_glsl_const_02.v_o)) * (((((((tmp7393))) - (u_neo_elem_33_transform.v_trans))) / vec3<f32>((u_neo_elem_33_transform.v_scale), (u_neo_elem_33_transform.v_scale), (u_neo_elem_33_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp6863.w) / length(tmp6863)) * ((tmp6863.w) / length(tmp6863))) + (((tmp6863.x) / length(tmp6863)) * ((tmp6863.x) / length(tmp6863))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))) - (((tmp6863.w) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) + (((tmp6863.w) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))) + (((tmp6863.w) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))))), ((c_glsl_const_01.v_o * ((((tmp6863.w) / length(tmp6863)) * ((tmp6863.w) / length(tmp6863))) + (((tmp6863.y) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6863.y) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) - (((tmp6863.w) / length(tmp6863)) * ((tmp6863.x) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.x) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) - (((tmp6863.w) / length(tmp6863)) * ((tmp6863.y) / length(tmp6863))))), (c_glsl_const_01.v_o * ((((tmp6863.y) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))) + (((tmp6863.w) / length(tmp6863)) * ((tmp6863.x) / length(tmp6863))))), ((c_glsl_const_01.v_o * ((((tmp6863.w) / length(tmp6863)) * ((tmp6863.w) / length(tmp6863))) + (((tmp6863.z) / length(tmp6863)) * ((tmp6863.z) / length(tmp6863))))) - c_glsl_const_02.v_o)) * (((((((tmp7393))) - (u_neo_elem_33_transform.v_trans))) / vec3<f32>((u_neo_elem_33_transform.v_scale), (u_neo_elem_33_transform.v_scale), (u_neo_elem_33_transform.v_scale))))).z));
	let tmp1388: vec4<f32> = (tmp1391.v_radius);
	let tmp7394: vec3<f32> = (tmp7483);
	let tmp6953: vec4<f32> = (u_neo_elem_34_transform.v_quat);
	let tmp1652: t_neo_elem_30_mod = u_neo_elem_30_mod;
	let tmp6864: f32 = length(tmp6863);
	let tmp1795: f32 = mix((tmp1802.y), (tmp1802.x), step(c_glsl_const_00.v_o, tmp1804));
	let tmp1311: vec4<f32> = (tmp1314.v_radius);
	let tmp8543: t_neo_elem_27_transform = u_neo_elem_27_transform;
	let tmp1313: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp6953.w) / length(tmp6953)) * ((tmp6953.w) / length(tmp6953))) + (((tmp6953.x) / length(tmp6953)) * ((tmp6953.x) / length(tmp6953))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))) - (((tmp6953.w) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) + (((tmp6953.w) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))) + (((tmp6953.w) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))))), ((c_glsl_const_01.v_o * ((((tmp6953.w) / length(tmp6953)) * ((tmp6953.w) / length(tmp6953))) + (((tmp6953.y) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6953.y) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) - (((tmp6953.w) / length(tmp6953)) * ((tmp6953.x) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) - (((tmp6953.w) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.y) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) + (((tmp6953.w) / length(tmp6953)) * ((tmp6953.x) / length(tmp6953))))), ((c_glsl_const_01.v_o * ((((tmp6953.w) / length(tmp6953)) * ((tmp6953.w) / length(tmp6953))) + (((tmp6953.z) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))))) - c_glsl_const_02.v_o)) * ((((((tmp7394)) - (u_neo_elem_34_transform.v_trans))) / vec3<f32>((u_neo_elem_34_transform.v_scale), (u_neo_elem_34_transform.v_scale), (u_neo_elem_34_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp6953.w) / length(tmp6953)) * ((tmp6953.w) / length(tmp6953))) + (((tmp6953.x) / length(tmp6953)) * ((tmp6953.x) / length(tmp6953))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))) - (((tmp6953.w) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) + (((tmp6953.w) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))) + (((tmp6953.w) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))))), ((c_glsl_const_01.v_o * ((((tmp6953.w) / length(tmp6953)) * ((tmp6953.w) / length(tmp6953))) + (((tmp6953.y) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp6953.y) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) - (((tmp6953.w) / length(tmp6953)) * ((tmp6953.x) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.x) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) - (((tmp6953.w) / length(tmp6953)) * ((tmp6953.y) / length(tmp6953))))), (c_glsl_const_01.v_o * ((((tmp6953.y) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))) + (((tmp6953.w) / length(tmp6953)) * ((tmp6953.x) / length(tmp6953))))), ((c_glsl_const_01.v_o * ((((tmp6953.w) / length(tmp6953)) * ((tmp6953.w) / length(tmp6953))) + (((tmp6953.z) / length(tmp6953)) * ((tmp6953.z) / length(tmp6953))))) - c_glsl_const_02.v_o)) * ((((((tmp7394)) - (u_neo_elem_34_transform.v_trans))) / vec3<f32>((u_neo_elem_34_transform.v_scale), (u_neo_elem_34_transform.v_scale), (u_neo_elem_34_transform.v_scale))))).z));
	let tmp1439: f32 = mix(mix((tmp1465.w), (tmp1465.y), step(c_glsl_const_00.v_o, (tmp1467.x))), mix((tmp1465.z), (tmp1465.x), step(c_glsl_const_00.v_o, (tmp1467.x))), step(c_glsl_const_00.v_o, (tmp1467.y)));
	let tmp6870: f32 = ((tmp6863.x) / tmp6864);
	let tmp6873: f32 = ((tmp6863.y) / tmp6864);
	let tmp6867: f32 = ((tmp6863.w) / tmp6864);
	let tmp6954: f32 = length(tmp6953);
	let tmp1237: t_neo_elem_35_prim = u_neo_elem_35_prim;
	let tmp1576: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6599 * tmp6599) + (tmp6602 * tmp6602))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6602 * tmp6605) - (tmp6599 * tmp6608))), (c_glsl_const_01.v_o * ((tmp6602 * tmp6608) + (tmp6599 * tmp6605))), (c_glsl_const_01.v_o * ((tmp6602 * tmp6605) + (tmp6599 * tmp6608))), ((c_glsl_const_01.v_o * ((tmp6599 * tmp6599) + (tmp6605 * tmp6605))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6605 * tmp6608) - (tmp6599 * tmp6602))), (c_glsl_const_01.v_o * ((tmp6602 * tmp6608) - (tmp6599 * tmp6605))), (c_glsl_const_01.v_o * ((tmp6605 * tmp6608) + (tmp6599 * tmp6602))), ((c_glsl_const_01.v_o * ((tmp6599 * tmp6599) + (tmp6608 * tmp6608))) - c_glsl_const_02.v_o)) * (((((((tmp7125))) - (u_neo_elem_30_transform.v_trans))) / vec3<f32>(tmp6754, tmp6754, tmp6754))));
	let tmp1358: vec2<f32> = ((abs(tmp1390) - (tmp1391.v_dims)) + vec2<f32>(mix(mix((tmp1388.w), (tmp1388.y), step(c_glsl_const_00.v_o, (tmp1390.x))), mix((tmp1388.z), (tmp1388.x), step(c_glsl_const_00.v_o, (tmp1390.x))), step(c_glsl_const_00.v_o, (tmp1390.y))), mix(mix((tmp1388.w), (tmp1388.y), step(c_glsl_const_00.v_o, (tmp1390.x))), mix((tmp1388.z), (tmp1388.x), step(c_glsl_const_00.v_o, (tmp1390.x))), step(c_glsl_const_00.v_o, (tmp1390.y)))));
	let tmp7573: vec3<f32> = (((((((((((((((t_position(a_pos).v_pos)))))))))))))));
	let tmp6876: f32 = ((tmp6863.z) / tmp6864);
	let tmp1648: vec2<f32> = (tmp1652.v_radius);
	let tmp1718: f32 = mix((tmp1725.y), (tmp1725.x), step(c_glsl_const_00.v_o, tmp1727));
	let tmp6957: f32 = ((tmp6953.w) / tmp6954);
	let tmp1650: f32 = (tmp1576.y);
	let tmp6960: f32 = ((tmp6953.x) / tmp6954);
	let tmp7484: vec3<f32> = (tmp7573);
	let tmp1575: t_neo_elem_31_mod = u_neo_elem_31_mod;
	let tmp1281: vec2<f32> = ((abs(tmp1313) - (tmp1314.v_dims)) + vec2<f32>(mix(mix((tmp1311.w), (tmp1311.y), step(c_glsl_const_00.v_o, (tmp1313.x))), mix((tmp1311.z), (tmp1311.x), step(c_glsl_const_00.v_o, (tmp1313.x))), step(c_glsl_const_00.v_o, (tmp1313.y))), mix(mix((tmp1311.w), (tmp1311.y), step(c_glsl_const_00.v_o, (tmp1313.x))), mix((tmp1311.z), (tmp1311.x), step(c_glsl_const_00.v_o, (tmp1313.x))), step(c_glsl_const_00.v_o, (tmp1313.y)))));
	let tmp7023: f32 = (u_neo_elem_33_transform.v_scale);
	let tmp1234: vec4<f32> = (tmp1237.v_radius);
	let tmp7042: vec4<f32> = (u_neo_elem_35_transform.v_quat);
	let tmp1634: vec2<f32> = vec2<f32>((((min(max((tmp1589.x), (tmp1589.y)), c_glsl_const_00.v_o) + (length(max(tmp1589, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1593))) + mix((tmp1648.y), (tmp1648.x), step(c_glsl_const_00.v_o, tmp1650))), (abs(tmp1650) - (tmp1652.v_height)));
	let tmp1236: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7042.w) / length(tmp7042)) * ((tmp7042.w) / length(tmp7042))) + (((tmp7042.x) / length(tmp7042)) * ((tmp7042.x) / length(tmp7042))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))) - (((tmp7042.w) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) + (((tmp7042.w) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))) + (((tmp7042.w) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))))), ((c_glsl_const_01.v_o * ((((tmp7042.w) / length(tmp7042)) * ((tmp7042.w) / length(tmp7042))) + (((tmp7042.y) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7042.y) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) - (((tmp7042.w) / length(tmp7042)) * ((tmp7042.x) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) - (((tmp7042.w) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.y) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) + (((tmp7042.w) / length(tmp7042)) * ((tmp7042.x) / length(tmp7042))))), ((c_glsl_const_01.v_o * ((((tmp7042.w) / length(tmp7042)) * ((tmp7042.w) / length(tmp7042))) + (((tmp7042.z) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))))) - c_glsl_const_02.v_o)) * ((((((tmp7484)) - (u_neo_elem_35_transform.v_trans))) / vec3<f32>((u_neo_elem_35_transform.v_scale), (u_neo_elem_35_transform.v_scale), (u_neo_elem_35_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7042.w) / length(tmp7042)) * ((tmp7042.w) / length(tmp7042))) + (((tmp7042.x) / length(tmp7042)) * ((tmp7042.x) / length(tmp7042))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))) - (((tmp7042.w) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) + (((tmp7042.w) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))) + (((tmp7042.w) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))))), ((c_glsl_const_01.v_o * ((((tmp7042.w) / length(tmp7042)) * ((tmp7042.w) / length(tmp7042))) + (((tmp7042.y) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7042.y) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) - (((tmp7042.w) / length(tmp7042)) * ((tmp7042.x) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.x) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) - (((tmp7042.w) / length(tmp7042)) * ((tmp7042.y) / length(tmp7042))))), (c_glsl_const_01.v_o * ((((tmp7042.y) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))) + (((tmp7042.w) / length(tmp7042)) * ((tmp7042.x) / length(tmp7042))))), ((c_glsl_const_01.v_o * ((((tmp7042.w) / length(tmp7042)) * ((tmp7042.w) / length(tmp7042))) + (((tmp7042.z) / length(tmp7042)) * ((tmp7042.z) / length(tmp7042))))) - c_glsl_const_02.v_o)) * ((((((tmp7484)) - (u_neo_elem_35_transform.v_trans))) / vec3<f32>((u_neo_elem_35_transform.v_scale), (u_neo_elem_35_transform.v_scale), (u_neo_elem_35_transform.v_scale))))).z));
	let tmp6963: f32 = ((tmp6953.y) / tmp6954);
	let tmp6966: f32 = ((tmp6953.z) / tmp6954);
	let tmp7663: vec3<f32> = ((((((((((((((t_position(a_pos).v_pos))))))))))))));
	let tmp1499: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6688 * tmp6688) + (tmp6691 * tmp6691))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6691 * tmp6694) - (tmp6688 * tmp6697))), (c_glsl_const_01.v_o * ((tmp6691 * tmp6697) + (tmp6688 * tmp6694))), (c_glsl_const_01.v_o * ((tmp6691 * tmp6694) + (tmp6688 * tmp6697))), ((c_glsl_const_01.v_o * ((tmp6688 * tmp6688) + (tmp6694 * tmp6694))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6694 * tmp6697) - (tmp6688 * tmp6691))), (c_glsl_const_01.v_o * ((tmp6691 * tmp6697) - (tmp6688 * tmp6694))), (c_glsl_const_01.v_o * ((tmp6694 * tmp6697) + (tmp6688 * tmp6691))), ((c_glsl_const_01.v_o * ((tmp6688 * tmp6688) + (tmp6697 * tmp6697))) - c_glsl_const_02.v_o)) * (((((((tmp7214))) - (u_neo_elem_31_transform.v_trans))) / vec3<f32>(tmp6844, tmp6844, tmp6844))));
	let tmp7112: f32 = (u_neo_elem_34_transform.v_scale);
	let tmp1362: f32 = mix(mix((tmp1388.w), (tmp1388.y), step(c_glsl_const_00.v_o, (tmp1390.x))), mix((tmp1388.z), (tmp1388.x), step(c_glsl_const_00.v_o, (tmp1390.x))), step(c_glsl_const_00.v_o, (tmp1390.y)));
	let tmp7391: vec3<f32> = (tmp7484);
	let tmp8544: t_neo_elem_28_transform = u_neo_elem_28_transform;
	let tmp1498: t_neo_elem_32_mod = u_neo_elem_32_mod;
	let tmp1160: t_neo_elem_36_prim = u_neo_elem_36_prim;
	let tmp1571: vec2<f32> = (tmp1575.v_radius);
	let tmp7043: f32 = length(tmp7042);
	let tmp7046: f32 = ((tmp7042.w) / tmp7043);
	let tmp1557: vec2<f32> = vec2<f32>((((min(max((tmp1512.x), (tmp1512.y)), c_glsl_const_00.v_o) + (length(max(tmp1512, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1516))) + mix((tmp1571.y), (tmp1571.x), step(c_glsl_const_00.v_o, (tmp1499.y)))), (abs((tmp1499.y)) - (tmp1575.v_height)));
	let tmp7574: vec3<f32> = (tmp7663);
	let tmp7055: f32 = ((tmp7042.z) / tmp7043);
	let tmp1494: vec2<f32> = (tmp1498.v_radius);
	let tmp8545: t_neo_elem_29_transform = u_neo_elem_29_transform;
	let tmp1422: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6778 * tmp6778) + (tmp6781 * tmp6781))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6781 * tmp6784) - (tmp6778 * tmp6787))), (c_glsl_const_01.v_o * ((tmp6781 * tmp6787) + (tmp6778 * tmp6784))), (c_glsl_const_01.v_o * ((tmp6781 * tmp6784) + (tmp6778 * tmp6787))), ((c_glsl_const_01.v_o * ((tmp6778 * tmp6778) + (tmp6784 * tmp6784))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6784 * tmp6787) - (tmp6778 * tmp6781))), (c_glsl_const_01.v_o * ((tmp6781 * tmp6787) - (tmp6778 * tmp6784))), (c_glsl_const_01.v_o * ((tmp6784 * tmp6787) + (tmp6778 * tmp6781))), ((c_glsl_const_01.v_o * ((tmp6778 * tmp6778) + (tmp6787 * tmp6787))) - c_glsl_const_02.v_o)) * (((((((tmp7304))) - (u_neo_elem_32_transform.v_trans))) / vec3<f32>(tmp6933, tmp6933, tmp6933))));
	let tmp1204: vec2<f32> = ((abs(tmp1236) - (tmp1237.v_dims)) + vec2<f32>(mix(mix((tmp1234.w), (tmp1234.y), step(c_glsl_const_00.v_o, (tmp1236.x))), mix((tmp1234.z), (tmp1234.x), step(c_glsl_const_00.v_o, (tmp1236.x))), step(c_glsl_const_00.v_o, (tmp1236.y))), mix(mix((tmp1234.w), (tmp1234.y), step(c_glsl_const_00.v_o, (tmp1236.x))), mix((tmp1234.z), (tmp1234.x), step(c_glsl_const_00.v_o, (tmp1236.x))), step(c_glsl_const_00.v_o, (tmp1236.y)))));
	let tmp1157: vec4<f32> = (tmp1160.v_radius);
	let tmp7131: vec4<f32> = (u_neo_elem_36_transform.v_quat);
	let tmp1641: f32 = mix((tmp1648.y), (tmp1648.x), step(c_glsl_const_00.v_o, tmp1650));
	let tmp1573: f32 = (tmp1499.y);
	let tmp1285: f32 = mix(mix((tmp1311.w), (tmp1311.y), step(c_glsl_const_00.v_o, (tmp1313.x))), mix((tmp1311.z), (tmp1311.x), step(c_glsl_const_00.v_o, (tmp1313.x))), step(c_glsl_const_00.v_o, (tmp1313.y)));
	let tmp7052: f32 = ((tmp7042.y) / tmp7043);
	let tmp1159: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7131.w) / length(tmp7131)) * ((tmp7131.w) / length(tmp7131))) + (((tmp7131.x) / length(tmp7131)) * ((tmp7131.x) / length(tmp7131))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))) - (((tmp7131.w) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) + (((tmp7131.w) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))) + (((tmp7131.w) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))))), ((c_glsl_const_01.v_o * ((((tmp7131.w) / length(tmp7131)) * ((tmp7131.w) / length(tmp7131))) + (((tmp7131.y) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7131.y) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) - (((tmp7131.w) / length(tmp7131)) * ((tmp7131.x) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) - (((tmp7131.w) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.y) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) + (((tmp7131.w) / length(tmp7131)) * ((tmp7131.x) / length(tmp7131))))), ((c_glsl_const_01.v_o * ((((tmp7131.w) / length(tmp7131)) * ((tmp7131.w) / length(tmp7131))) + (((tmp7131.z) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))))) - c_glsl_const_02.v_o)) * ((((((tmp7574)) - (u_neo_elem_36_transform.v_trans))) / vec3<f32>((u_neo_elem_36_transform.v_scale), (u_neo_elem_36_transform.v_scale), (u_neo_elem_36_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7131.w) / length(tmp7131)) * ((tmp7131.w) / length(tmp7131))) + (((tmp7131.x) / length(tmp7131)) * ((tmp7131.x) / length(tmp7131))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))) - (((tmp7131.w) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) + (((tmp7131.w) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))) + (((tmp7131.w) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))))), ((c_glsl_const_01.v_o * ((((tmp7131.w) / length(tmp7131)) * ((tmp7131.w) / length(tmp7131))) + (((tmp7131.y) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7131.y) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) - (((tmp7131.w) / length(tmp7131)) * ((tmp7131.x) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.x) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) - (((tmp7131.w) / length(tmp7131)) * ((tmp7131.y) / length(tmp7131))))), (c_glsl_const_01.v_o * ((((tmp7131.y) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))) + (((tmp7131.w) / length(tmp7131)) * ((tmp7131.x) / length(tmp7131))))), ((c_glsl_const_01.v_o * ((((tmp7131.w) / length(tmp7131)) * ((tmp7131.w) / length(tmp7131))) + (((tmp7131.z) / length(tmp7131)) * ((tmp7131.z) / length(tmp7131))))) - c_glsl_const_02.v_o)) * ((((((tmp7574)) - (u_neo_elem_36_transform.v_trans))) / vec3<f32>((u_neo_elem_36_transform.v_scale), (u_neo_elem_36_transform.v_scale), (u_neo_elem_36_transform.v_scale))))).z));
	let tmp7049: f32 = ((tmp7042.x) / tmp7043);
	let tmp1480: vec2<f32> = vec2<f32>((((min(max((tmp1435.x), (tmp1435.y)), c_glsl_const_00.v_o) + (length(max(tmp1435, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1439))) + mix((tmp1494.y), (tmp1494.x), step(c_glsl_const_00.v_o, (tmp1422.y)))), (abs((tmp1422.y)) - (tmp1498.v_height)));
	let tmp1496: f32 = (tmp1422.y);
	let tmp7481: vec3<f32> = (tmp7574);
	let tmp7132: f32 = length(tmp7131);
	let tmp1082: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))) - ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) - ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) - ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))) - (u_neo_elem_37_transform.v_trans))) / vec3<f32>((u_neo_elem_37_transform.v_scale), (u_neo_elem_37_transform.v_scale), (u_neo_elem_37_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))) - ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) - ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) - ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).y) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).x) / length((u_neo_elem_37_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).w) / length((u_neo_elem_37_transform.v_quat)))) + ((((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat))) * (((u_neo_elem_37_transform.v_quat).z) / length((u_neo_elem_37_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((((((((((((((((t_position(a_pos).v_pos)))))))))))))))) - (u_neo_elem_37_transform.v_trans))) / vec3<f32>((u_neo_elem_37_transform.v_scale), (u_neo_elem_37_transform.v_scale), (u_neo_elem_37_transform.v_scale))))).z));
	let tmp7201: f32 = (u_neo_elem_35_transform.v_scale);
	let tmp7138: f32 = ((tmp7131.x) / tmp7132);
	let tmp7386: vec3<f32> = (tmp7481);
	let tmp7144: f32 = ((tmp7131.z) / tmp7132);
	let tmp7135: f32 = ((tmp7131.w) / tmp7132);
	let tmp1564: f32 = mix((tmp1571.y), (tmp1571.x), step(c_glsl_const_00.v_o, tmp1573));
	let tmp7141: f32 = ((tmp7131.y) / tmp7132);
	let tmp1421: t_neo_elem_33_mod = u_neo_elem_33_mod;
	let tmp1127: vec2<f32> = ((abs(tmp1159) - (tmp1160.v_dims)) + vec2<f32>(mix(mix((tmp1157.w), (tmp1157.y), step(c_glsl_const_00.v_o, (tmp1159.x))), mix((tmp1157.z), (tmp1157.x), step(c_glsl_const_00.v_o, (tmp1159.x))), step(c_glsl_const_00.v_o, (tmp1159.y))), mix(mix((tmp1157.w), (tmp1157.y), step(c_glsl_const_00.v_o, (tmp1159.x))), mix((tmp1157.z), (tmp1157.x), step(c_glsl_const_00.v_o, (tmp1159.x))), step(c_glsl_const_00.v_o, (tmp1159.y)))));
	let tmp7387: vec3<f32> = (u_neo_elem_36_transform.v_trans);
	let tmp1208: f32 = mix(mix((tmp1234.w), (tmp1234.y), step(c_glsl_const_00.v_o, (tmp1236.x))), mix((tmp1234.z), (tmp1234.x), step(c_glsl_const_00.v_o, (tmp1236.x))), step(c_glsl_const_00.v_o, (tmp1236.y)));
	let tmp7752: vec3<f32> = (((((((((((((t_position(a_pos).v_pos)))))))))))));
	let tmp1081: f32 = (u_neo_elem_37_prim.v_angle);
	let tmp8546: t_neo_elem_30_transform = u_neo_elem_30_transform;
	let tmp7291: f32 = (u_neo_elem_36_transform.v_scale);
	let tmp1077: f32 = (u_neo_elem_37_prim.v_th);
	let tmp7664: vec3<f32> = (tmp7752);
	let tmp1487: f32 = mix((tmp1494.y), (tmp1494.x), step(c_glsl_const_00.v_o, tmp1496));
	let tmp1344: t_neo_elem_34_mod = u_neo_elem_34_mod;
	let tmp7221: vec4<f32> = (u_neo_elem_37_transform.v_quat);
	let tmp1417: vec2<f32> = (tmp1421.v_radius);
	let tmp1345: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6867 * tmp6867) + (tmp6870 * tmp6870))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6870 * tmp6873) - (tmp6867 * tmp6876))), (c_glsl_const_01.v_o * ((tmp6870 * tmp6876) + (tmp6867 * tmp6873))), (c_glsl_const_01.v_o * ((tmp6870 * tmp6873) + (tmp6867 * tmp6876))), ((c_glsl_const_01.v_o * ((tmp6867 * tmp6867) + (tmp6873 * tmp6873))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6873 * tmp6876) - (tmp6867 * tmp6870))), (c_glsl_const_01.v_o * ((tmp6870 * tmp6876) - (tmp6867 * tmp6873))), (c_glsl_const_01.v_o * ((tmp6873 * tmp6876) + (tmp6867 * tmp6870))), ((c_glsl_const_01.v_o * ((tmp6867 * tmp6867) + (tmp6876 * tmp6876))) - c_glsl_const_02.v_o)) * (((((((tmp7393))) - (u_neo_elem_33_transform.v_trans))) / vec3<f32>(tmp7023, tmp7023, tmp7023))));
	let tmp1080: f32 = (u_neo_elem_37_prim.v_r);
	let tmp7388: vec3<f32> = (tmp7386 - tmp7387);
	let tmp1018: vec2<f32> = vec2<f32>((dot((vec2<f32>(abs((tmp1082.x)), (tmp1082.y)) - vec2<f32>((u_neo_elem_37_prim.v_wi), tmp1080)), vec2<f32>(cos(tmp1081), sin(tmp1081))) - (u_neo_elem_37_prim.v_le)), (abs((dot((vec2<f32>(abs((tmp1082.x)), (tmp1082.y)) - vec2<f32>((u_neo_elem_37_prim.v_wi), tmp1080)), vec2<f32>(opp((vec2<f32>(cos(tmp1081), sin(tmp1081)).y)), (vec2<f32>(cos(tmp1081), sin(tmp1081)).x))) + tmp1080)) - (tmp1077 / c_glsl_const_01.v_o)));
	let tmp7841: vec3<f32> = ((((((((((((t_position(a_pos).v_pos))))))))))));
	let tmp1131: f32 = mix(mix((tmp1157.w), (tmp1157.y), step(c_glsl_const_00.v_o, (tmp1159.x))), mix((tmp1157.z), (tmp1157.x), step(c_glsl_const_00.v_o, (tmp1159.x))), step(c_glsl_const_00.v_o, (tmp1159.y)));
	let tmp1069: vec2<f32> = vec2<f32>((u_neo_elem_37_prim.v_wi), tmp1080);
	let tmp7222: f32 = length(tmp7221);
	let tmp1340: vec2<f32> = (tmp1344.v_radius);
	let tmp1403: vec2<f32> = vec2<f32>((((min(max((tmp1358.x), (tmp1358.y)), c_glsl_const_00.v_o) + (length(max(tmp1358, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1362))) + mix((tmp1417.y), (tmp1417.x), step(c_glsl_const_00.v_o, (tmp1345.y)))), (abs((tmp1345.y)) - (tmp1421.v_height)));
	let tmp1079: f32 = (u_neo_elem_37_prim.v_wi);
	let tmp1268: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp6957 * tmp6957) + (tmp6960 * tmp6960))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6960 * tmp6963) - (tmp6957 * tmp6966))), (c_glsl_const_01.v_o * ((tmp6960 * tmp6966) + (tmp6957 * tmp6963))), (c_glsl_const_01.v_o * ((tmp6960 * tmp6963) + (tmp6957 * tmp6966))), ((c_glsl_const_01.v_o * ((tmp6957 * tmp6957) + (tmp6963 * tmp6963))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp6963 * tmp6966) - (tmp6957 * tmp6960))), (c_glsl_const_01.v_o * ((tmp6960 * tmp6966) - (tmp6957 * tmp6963))), (c_glsl_const_01.v_o * ((tmp6963 * tmp6966) + (tmp6957 * tmp6960))), ((c_glsl_const_01.v_o * ((tmp6957 * tmp6957) + (tmp6966 * tmp6966))) - c_glsl_const_02.v_o)) * ((((((tmp7394)) - (u_neo_elem_34_transform.v_trans))) / vec3<f32>(tmp7112, tmp7112, tmp7112))));
	let tmp970: t_neo_elem_38_prim = u_neo_elem_38_prim;
	let tmp7571: vec3<f32> = (tmp7664);
	let tmp1070: vec2<f32> = vec2<f32>(abs((tmp1082.x)), (tmp1082.y));
	let tmp1419: f32 = (tmp1345.y);
	let tmp893: t_neo_elem_39_prim = u_neo_elem_39_prim;
	let tmp969: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))) - ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) - ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) - ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7841))) - (u_neo_elem_38_transform.v_trans))) / vec3<f32>((u_neo_elem_38_transform.v_scale), (u_neo_elem_38_transform.v_scale), (u_neo_elem_38_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))) - ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) - ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) - ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).y) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).x) / length((u_neo_elem_38_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).w) / length((u_neo_elem_38_transform.v_quat)))) + ((((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat))) * (((u_neo_elem_38_transform.v_quat).z) / length((u_neo_elem_38_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7841))) - (u_neo_elem_38_transform.v_trans))) / vec3<f32>((u_neo_elem_38_transform.v_scale), (u_neo_elem_38_transform.v_scale), (u_neo_elem_38_transform.v_scale))))).z));
	let tmp7228: f32 = ((tmp7221.x) / tmp7222);
	let tmp967: vec4<f32> = (tmp970.v_radius);
	let tmp7234: f32 = ((tmp7221.z) / tmp7222);
	let tmp7753: vec3<f32> = (tmp7841);
	let tmp7477: vec3<f32> = (u_neo_elem_37_transform.v_trans);
	let tmp7225: f32 = ((tmp7221.w) / tmp7222);
	let tmp7931: vec3<f32> = (((((((((((t_position(a_pos).v_pos)))))))))));
	let tmp1342: f32 = (tmp1268.y);
	let tmp7310: vec4<f32> = (u_neo_elem_38_transform.v_quat);
	let tmp1267: t_neo_elem_35_mod = u_neo_elem_35_mod;
	let tmp1066: vec2<f32> = vec2<f32>(cos(tmp1081), sin(tmp1081));
	let tmp1326: vec2<f32> = vec2<f32>((((min(max((tmp1281.x), (tmp1281.y)), c_glsl_const_00.v_o) + (length(max(tmp1281, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1285))) + mix((tmp1340.y), (tmp1340.x), step(c_glsl_const_00.v_o, tmp1342))), (abs(tmp1342) - (tmp1344.v_height)));
	let tmp7476: vec3<f32> = (tmp7571);
	let tmp1060: f32 = ((tmp1070.x) - tmp1079);
	let tmp7231: f32 = ((tmp7221.y) / tmp7222);
	let tmp8547: t_neo_elem_31_transform = u_neo_elem_31_transform;
	let tmp1058: f32 = dot((tmp1070 - tmp1069), tmp1066);
	let tmp1191: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp7046 * tmp7046) + (tmp7049 * tmp7049))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7049 * tmp7052) - (tmp7046 * tmp7055))), (c_glsl_const_01.v_o * ((tmp7049 * tmp7055) + (tmp7046 * tmp7052))), (c_glsl_const_01.v_o * ((tmp7049 * tmp7052) + (tmp7046 * tmp7055))), ((c_glsl_const_01.v_o * ((tmp7046 * tmp7046) + (tmp7052 * tmp7052))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7052 * tmp7055) - (tmp7046 * tmp7049))), (c_glsl_const_01.v_o * ((tmp7049 * tmp7055) - (tmp7046 * tmp7052))), (c_glsl_const_01.v_o * ((tmp7052 * tmp7055) + (tmp7046 * tmp7049))), ((c_glsl_const_01.v_o * ((tmp7046 * tmp7046) + (tmp7055 * tmp7055))) - c_glsl_const_02.v_o)) * (((((tmp7391) - (u_neo_elem_35_transform.v_trans))) / vec3<f32>(tmp7201, tmp7201, tmp7201))));
	let tmp892: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))) - ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) - ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) - ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7931))) - (u_neo_elem_39_transform.v_trans))) / vec3<f32>((u_neo_elem_39_transform.v_scale), (u_neo_elem_39_transform.v_scale), (u_neo_elem_39_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))) - ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) - ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) - ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).y) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).x) / length((u_neo_elem_39_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).w) / length((u_neo_elem_39_transform.v_quat)))) + ((((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat))) * (((u_neo_elem_39_transform.v_quat).z) / length((u_neo_elem_39_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp7931))) - (u_neo_elem_39_transform.v_trans))) / vec3<f32>((u_neo_elem_39_transform.v_scale), (u_neo_elem_39_transform.v_scale), (u_neo_elem_39_transform.v_scale))))).z));
	let tmp7400: vec4<f32> = (u_neo_elem_39_transform.v_quat);
	let tmp7405: vec4<f32> = tmp7400;
	let tmp7661: vec3<f32> = (tmp7753);
	let tmp7402: vec4<f32> = tmp7400;
	let tmp1263: vec2<f32> = (tmp1267.v_radius);
	let tmp1410: f32 = mix((tmp1417.y), (tmp1417.x), step(c_glsl_const_00.v_o, tmp1419));
	let tmp7411: vec4<f32> = tmp7400;
	let tmp7380: f32 = (u_neo_elem_37_transform.v_scale);
	let tmp890: vec4<f32> = (tmp893.v_radius);
	let tmp7408: vec4<f32> = tmp7400;
	let tmp7842: vec3<f32> = (tmp7931);
	let tmp1048: f32 = mix((abs((tmp1070.y)) - (tmp1077 / c_glsl_const_01.v_o)), c_glsl_const_03.v_o, step(c_glsl_const_00.v_o, tmp1060));
	let tmp8548: t_neo_elem_32_transform = u_neo_elem_32_transform;
	let tmp7311: f32 = length(tmp7310);
	let tmp7478: vec3<f32> = (tmp7476 - tmp7477);
	let tmp7401: f32 = length(tmp7400);
	let tmp8021: vec3<f32> = ((((((((((t_position(a_pos).v_pos))))))))));
	let tmp816: t_neo_elem_40_prim = u_neo_elem_40_prim;
	let tmp7369: f32 = (((tmp7310.w) / tmp7311) * ((tmp7310.w) / tmp7311));
	let tmp937: vec2<f32> = ((abs(tmp969) - (tmp970.v_dims)) + vec2<f32>(mix(mix((tmp967.w), (tmp967.y), step(c_glsl_const_00.v_o, (tmp969.x))), mix((tmp967.z), (tmp967.x), step(c_glsl_const_00.v_o, (tmp969.x))), step(c_glsl_const_00.v_o, (tmp969.y))), mix(mix((tmp967.w), (tmp967.y), step(c_glsl_const_00.v_o, (tmp969.x))), mix((tmp967.z), (tmp967.x), step(c_glsl_const_00.v_o, (tmp969.x))), step(c_glsl_const_00.v_o, (tmp969.y)))));
	let tmp7370: f32 = (((tmp7310.z) / tmp7311) * ((tmp7310.z) / tmp7311));
	let tmp7379: vec3<f32> = (tmp7478);
	let tmp1033: f32 = mix(tmp1048, mix(tmp1048, min(tmp1048, (abs((length((tmp1070 - tmp1069)) - tmp1080)) - (tmp1077 / c_glsl_const_01.v_o))), step(c_glsl_const_00.v_o, opp(tmp1058))), step(c_glsl_const_00.v_o, tmp1060));
	let tmp7323: f32 = ((tmp7310.z) / tmp7311);
	let tmp1190: t_neo_elem_36_mod = u_neo_elem_36_mod;
	let tmp7320: f32 = ((tmp7310.y) / tmp7311);
	let tmp7317: f32 = ((tmp7310.x) / tmp7311);
	let tmp7403: f32 = (tmp7402.w);
	let tmp1265: f32 = (tmp1191.y);
	let tmp7406: f32 = (tmp7405.x);
	let tmp1333: f32 = mix((tmp1340.y), (tmp1340.x), step(c_glsl_const_00.v_o, tmp1342));
	let tmp7381: vec3<f32> = vec3<f32>(tmp7380, tmp7380, tmp7380);
	let tmp7750: vec3<f32> = (tmp7842);
	let tmp7409: f32 = (tmp7408.y);
	let tmp7412: f32 = (tmp7411.z);
	let tmp7566: vec3<f32> = (tmp7661);
	let tmp7567: vec3<f32> = (u_neo_elem_38_transform.v_trans);
	let tmp7314: f32 = ((tmp7310.w) / tmp7311);
	let tmp1249: vec2<f32> = vec2<f32>((((min(max((tmp1204.x), (tmp1204.y)), c_glsl_const_00.v_o) + (length(max(tmp1204, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1208))) + mix((tmp1263.y), (tmp1263.x), step(c_glsl_const_00.v_o, tmp1265))), (abs(tmp1265) - (tmp1267.v_height)));
	let tmp1083: t_neo_elem_37_prim = u_neo_elem_37_prim;
	let tmp7404: f32 = (tmp7403 / tmp7401);
	let tmp7415: f32 = (tmp7404 * tmp7404);
	let tmp7416: f32 = ((tmp7406 / tmp7401) * (tmp7406 / tmp7401));
	let tmp7368: t_glsl_const_01 = c_glsl_const_01;
	let tmp7438: f32 = ((tmp7409 / tmp7401) * (tmp7409 / tmp7401));
	let tmp7470: f32 = (u_neo_elem_38_transform.v_scale);
	let tmp7495: vec4<f32> = (u_neo_elem_40_transform.v_quat);
	let tmp7382: vec3<f32> = (tmp7379 / tmp7381);
	let tmp1114: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp7135 * tmp7135) + (tmp7138 * tmp7138))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7138 * tmp7141) - (tmp7135 * tmp7144))), (c_glsl_const_01.v_o * ((tmp7138 * tmp7144) + (tmp7135 * tmp7141))), (c_glsl_const_01.v_o * ((tmp7138 * tmp7141) + (tmp7135 * tmp7144))), ((c_glsl_const_01.v_o * ((tmp7135 * tmp7135) + (tmp7141 * tmp7141))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7141 * tmp7144) - (tmp7135 * tmp7138))), (c_glsl_const_01.v_o * ((tmp7138 * tmp7144) - (tmp7135 * tmp7141))), (c_glsl_const_01.v_o * ((tmp7141 * tmp7144) + (tmp7135 * tmp7138))), ((c_glsl_const_01.v_o * ((tmp7135 * tmp7135) + (tmp7144 * tmp7144))) - c_glsl_const_02.v_o)) * (((tmp7388) / vec3<f32>(tmp7291, tmp7291, tmp7291))));
	let tmp7490: vec4<f32> = (u_neo_elem_40_transform.v_quat);
	let tmp7498: vec4<f32> = tmp7490;
	let tmp7568: vec3<f32> = (tmp7566 - tmp7567);
	let tmp7460: f32 = ((tmp7412 / tmp7401) * (tmp7412 / tmp7401));
	let tmp7501: vec4<f32> = tmp7490;
	let tmp7407: f32 = (tmp7406 / tmp7401);
	let tmp7932: vec3<f32> = (tmp8021);
	let tmp7656: vec3<f32> = (tmp7750);
	let tmp815: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7490.w) / length(tmp7490)) * ((tmp7490.w) / length(tmp7490))) + (((tmp7495.x) / length(tmp7490)) * ((tmp7495.x) / length(tmp7490))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))) - (((tmp7490.w) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) + (((tmp7490.w) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))) + (((tmp7490.w) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))))), ((c_glsl_const_01.v_o * ((((tmp7490.w) / length(tmp7490)) * ((tmp7490.w) / length(tmp7490))) + (((tmp7498.y) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7498.y) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) - (((tmp7490.w) / length(tmp7490)) * ((tmp7495.x) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) - (((tmp7490.w) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7498.y) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) + (((tmp7490.w) / length(tmp7490)) * ((tmp7495.x) / length(tmp7490))))), ((c_glsl_const_01.v_o * ((((tmp7490.w) / length(tmp7490)) * ((tmp7490.w) / length(tmp7490))) + (((tmp7501.z) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))))) - c_glsl_const_02.v_o)) * ((((((tmp7932)) - (u_neo_elem_40_transform.v_trans))) / vec3<f32>((u_neo_elem_40_transform.v_scale), (u_neo_elem_40_transform.v_scale), (u_neo_elem_40_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7490.w) / length(tmp7490)) * ((tmp7490.w) / length(tmp7490))) + (((tmp7495.x) / length(tmp7490)) * ((tmp7495.x) / length(tmp7490))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))) - (((tmp7490.w) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) + (((tmp7490.w) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))) + (((tmp7490.w) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))))), ((c_glsl_const_01.v_o * ((((tmp7490.w) / length(tmp7490)) * ((tmp7490.w) / length(tmp7490))) + (((tmp7498.y) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7498.y) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) - (((tmp7490.w) / length(tmp7490)) * ((tmp7495.x) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7495.x) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) - (((tmp7490.w) / length(tmp7490)) * ((tmp7498.y) / length(tmp7490))))), (c_glsl_const_01.v_o * ((((tmp7498.y) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))) + (((tmp7490.w) / length(tmp7490)) * ((tmp7495.x) / length(tmp7490))))), ((c_glsl_const_01.v_o * ((((tmp7490.w) / length(tmp7490)) * ((tmp7490.w) / length(tmp7490))) + (((tmp7501.z) / length(tmp7490)) * ((tmp7501.z) / length(tmp7490))))) - c_glsl_const_02.v_o)) * ((((((tmp7932)) - (u_neo_elem_40_transform.v_trans))) / vec3<f32>((u_neo_elem_40_transform.v_scale), (u_neo_elem_40_transform.v_scale), (u_neo_elem_40_transform.v_scale))))).z));
	let tmp7410: f32 = (tmp7409 / tmp7401);
	let tmp7459: f32 = (tmp7404 * tmp7404);
	let tmp813: vec4<f32> = (tmp816.v_radius);
	let tmp7657: vec3<f32> = (u_neo_elem_39_transform.v_trans);
	let tmp7364: f32 = (tmp7320 * tmp7323);
	let tmp7437: f32 = (tmp7404 * tmp7404);
	let tmp7413: f32 = (tmp7412 / tmp7401);
	let tmp7365: f32 = (tmp7314 * tmp7317);
	let tmp1186: vec2<f32> = (tmp1190.v_radius);
	let tmp860: vec2<f32> = ((abs(tmp892) - (tmp893.v_dims)) + vec2<f32>(mix(mix((tmp890.w), (tmp890.y), step(c_glsl_const_00.v_o, (tmp892.x))), mix((tmp890.z), (tmp890.x), step(c_glsl_const_00.v_o, (tmp892.x))), step(c_glsl_const_00.v_o, (tmp892.y))), mix(mix((tmp890.w), (tmp890.y), step(c_glsl_const_00.v_o, (tmp892.x))), mix((tmp890.z), (tmp890.x), step(c_glsl_const_00.v_o, (tmp892.x))), step(c_glsl_const_00.v_o, (tmp892.y)))));
	let tmp7371: f32 = (tmp7369 + tmp7370);
	let tmp7492: vec4<f32> = tmp7490;
	let tmp7417: f32 = (tmp7415 + tmp7416);
	let tmp1172: vec2<f32> = vec2<f32>((((min(max((tmp1127.x), (tmp1127.y)), c_glsl_const_00.v_o) + (length(max(tmp1127, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1131))) + mix((tmp1186.y), (tmp1186.x), step(c_glsl_const_00.v_o, (tmp1114.y)))), (abs((tmp1114.y)) - (tmp1190.v_height)));
	let tmp7363: t_glsl_const_01 = c_glsl_const_01;
	let tmp7839: vec3<f32> = (tmp7932);
	let tmp7414: t_glsl_const_01 = c_glsl_const_01;
	let tmp7422: f32 = (tmp7407 * tmp7410);
	let tmp7423: f32 = (tmp7404 * tmp7413);
	let tmp7471: vec3<f32> = vec3<f32>(tmp7470, tmp7470, tmp7470);
	let tmp7427: f32 = (tmp7407 * tmp7413);
	let tmp7428: f32 = (tmp7404 * tmp7410);
	let tmp7432: f32 = (tmp7407 * tmp7410);
	let tmp7433: f32 = (tmp7404 * tmp7413);
	let tmp7436: t_glsl_const_01 = c_glsl_const_01;
	let tmp7439: f32 = (tmp7437 + tmp7438);
	let tmp7560: f32 = (u_neo_elem_39_transform.v_scale);
	let tmp7366: f32 = (tmp7364 + tmp7365);
	let tmp7444: f32 = (tmp7410 * tmp7413);
	let tmp7445: f32 = (tmp7404 * tmp7407);
	let tmp7449: f32 = (tmp7407 * tmp7413);
	let tmp7450: f32 = (tmp7404 * tmp7410);
	let tmp7454: f32 = (tmp7410 * tmp7413);
	let tmp7455: f32 = (tmp7404 * tmp7407);
	let tmp7458: t_glsl_const_01 = c_glsl_const_01;
	let tmp941: f32 = mix(mix((tmp967.w), (tmp967.y), step(c_glsl_const_00.v_o, (tmp969.x))), mix((tmp967.z), (tmp967.x), step(c_glsl_const_00.v_o, (tmp969.x))), step(c_glsl_const_00.v_o, (tmp969.y)));
	let tmp8549: t_neo_elem_33_transform = u_neo_elem_33_transform;
	let tmp7372: f32 = (tmp7368.v_o * tmp7371);
	let tmp7373: t_glsl_const_02 = c_glsl_const_02;
	let tmp7502: f32 = (tmp7501.z);
	let tmp7499: f32 = (tmp7498.y);
	let tmp7491: f32 = length(tmp7490);
	let tmp7461: f32 = (tmp7459 + tmp7460);
	let tmp7496: f32 = (tmp7495.x);
	let tmp7493: f32 = (tmp7492.w);
	let tmp1188: f32 = (tmp1114.y);
	let tmp7469: vec3<f32> = (tmp7568);
	let tmp1256: f32 = mix((tmp1263.y), (tmp1263.x), step(c_glsl_const_00.v_o, tmp1265));
	let tmp7658: vec3<f32> = (tmp7656 - tmp7657);
	let tmp7418: f32 = (tmp7414.v_o * tmp7417);
	let tmp7419: t_glsl_const_02 = c_glsl_const_02;
	let tmp7463: t_glsl_const_02 = c_glsl_const_02;
	let tmp7421: t_glsl_const_01 = c_glsl_const_01;
	let tmp7424: f32 = (tmp7422 - tmp7423);
	let tmp7453: t_glsl_const_01 = c_glsl_const_01;
	let tmp7497: f32 = (tmp7496 / tmp7491);
	let tmp783: vec2<f32> = ((abs(tmp815) - (tmp816.v_dims)) + vec2<f32>(mix(mix((tmp813.w), (tmp813.y), step(c_glsl_const_00.v_o, (tmp815.x))), mix((tmp813.z), (tmp813.x), step(c_glsl_const_00.v_o, (tmp815.x))), step(c_glsl_const_00.v_o, (tmp815.y))), mix(mix((tmp813.w), (tmp813.y), step(c_glsl_const_00.v_o, (tmp815.x))), mix((tmp813.z), (tmp813.x), step(c_glsl_const_00.v_o, (tmp815.x))), step(c_glsl_const_00.v_o, (tmp815.y)))));
	let tmp7528: f32 = ((tmp7499 / tmp7491) * (tmp7499 / tmp7491));
	let tmp7500: f32 = (tmp7499 / tmp7491);
	let tmp7506: f32 = (tmp7497 * tmp7497);
	let tmp864: f32 = mix(mix((tmp890.w), (tmp890.y), step(c_glsl_const_00.v_o, (tmp892.x))), mix((tmp890.z), (tmp890.x), step(c_glsl_const_00.v_o, (tmp892.x))), step(c_glsl_const_00.v_o, (tmp892.y)));
	let tmp7451: f32 = (tmp7449 - tmp7450);
	let tmp7448: t_glsl_const_01 = c_glsl_const_01;
	let tmp7505: f32 = ((tmp7493 / tmp7491) * (tmp7493 / tmp7491));
	let tmp7367: f32 = (tmp7363.v_o * tmp7366);
	let tmp7462: f32 = (tmp7458.v_o * tmp7461);
	let tmp7446: f32 = (tmp7444 - tmp7445);
	let tmp7559: vec3<f32> = (tmp7658);
	let tmp7443: t_glsl_const_01 = c_glsl_const_01;
	let tmp1113: t_neo_elem_37_mod = u_neo_elem_37_mod;
	let tmp7441: t_glsl_const_02 = c_glsl_const_02;
	let tmp7550: f32 = ((tmp7502 / tmp7491) * (tmp7502 / tmp7491));
	let tmp7549: f32 = ((tmp7493 / tmp7491) * (tmp7493 / tmp7491));
	let tmp7440: f32 = (tmp7436.v_o * tmp7439);
	let tmp8550: t_neo_elem_34_transform = u_neo_elem_34_transform;
	let tmp8110: vec3<f32> = (((((((((t_position(a_pos).v_pos)))))))));
	let tmp7472: vec3<f32> = (tmp7469 / tmp7471);
	let tmp7561: vec3<f32> = vec3<f32>(tmp7560, tmp7560, tmp7560);
	let tmp7434: f32 = (tmp7432 + tmp7433);
	let tmp7431: t_glsl_const_01 = c_glsl_const_01;
	let tmp7494: f32 = (tmp7493 / tmp7491);
	let tmp7374: f32 = (tmp7372 - tmp7373.v_o);
	let tmp7429: f32 = (tmp7427 + tmp7428);
	let tmp739: t_neo_elem_41_prim = u_neo_elem_41_prim;
	let tmp7746: vec3<f32> = (u_neo_elem_40_transform.v_trans);
	let tmp7426: t_glsl_const_01 = c_glsl_const_01;
	let tmp7745: vec3<f32> = (tmp7839);
	let tmp7503: f32 = (tmp7502 / tmp7491);
	let tmp7456: f32 = (tmp7454 + tmp7455);
	let tmp7527: f32 = (tmp7494 * tmp7494);
	let tmp7457: f32 = (tmp7453.v_o * tmp7456);
	let tmp7650: f32 = (u_neo_elem_40_transform.v_scale);
	let tmp7534: f32 = (tmp7500 * tmp7503);
	let tmp1109: vec2<f32> = (tmp1113.v_radius);
	let tmp7585: vec4<f32> = (u_neo_elem_41_transform.v_quat);
	let tmp1179: f32 = mix((tmp1186.y), (tmp1186.x), step(c_glsl_const_00.v_o, tmp1188));
	let tmp7588: vec4<f32> = (u_neo_elem_41_transform.v_quat);
	let tmp7591: vec4<f32> = (u_neo_elem_41_transform.v_quat);
	let tmp7526: t_glsl_const_01 = c_glsl_const_01;
	let tmp7517: f32 = (tmp7497 * tmp7503);
	let tmp7522: f32 = (tmp7497 * tmp7500);
	let tmp7464: f32 = (tmp7462 - tmp7463.v_o);
	let tmp7747: vec3<f32> = (tmp7745 - tmp7746);
	let tmp7535: f32 = (tmp7494 * tmp7497);
	let tmp7539: f32 = (tmp7497 * tmp7503);
	let tmp7375: mat3x3<f32> = mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp7314 * tmp7314) + (tmp7317 * tmp7317))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7317 * tmp7320) - (tmp7314 * tmp7323))), (c_glsl_const_01.v_o * ((tmp7317 * tmp7323) + (tmp7314 * tmp7320))), (c_glsl_const_01.v_o * ((tmp7317 * tmp7320) + (tmp7314 * tmp7323))), ((c_glsl_const_01.v_o * ((tmp7314 * tmp7314) + (tmp7320 * tmp7320))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7320 * tmp7323) - (tmp7314 * tmp7317))), (c_glsl_const_01.v_o * ((tmp7317 * tmp7323) - (tmp7314 * tmp7320))), tmp7367, tmp7374);
	let tmp7507: f32 = (tmp7505 + tmp7506);
	let tmp7540: f32 = (tmp7494 * tmp7500);
	let tmp7518: f32 = (tmp7494 * tmp7500);
	let tmp7513: f32 = (tmp7494 * tmp7503);
	let tmp738: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * (((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat)))) + (((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7585.x) / length((u_neo_elem_41_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))) - ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) + ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))) + ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * (((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat)))) + (((tmp7588.y) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7588.y) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) - ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7585.x) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) - ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7588.y) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) + ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7585.x) / length((u_neo_elem_41_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * (((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat)))) + (((tmp7591.z) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp8110))) - (u_neo_elem_41_transform.v_trans))) / vec3<f32>((u_neo_elem_41_transform.v_scale), (u_neo_elem_41_transform.v_scale), (u_neo_elem_41_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * (((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat)))) + (((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7585.x) / length((u_neo_elem_41_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))) - ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) + ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))) + ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * (((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat)))) + (((tmp7588.y) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7588.y) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) - ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7585.x) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7585.x) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) - ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7588.y) / length((u_neo_elem_41_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7588.y) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))) + ((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7585.x) / length((u_neo_elem_41_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat))) * (((u_neo_elem_41_transform.v_quat).w) / length((u_neo_elem_41_transform.v_quat)))) + (((tmp7591.z) / length((u_neo_elem_41_transform.v_quat))) * ((tmp7591.z) / length((u_neo_elem_41_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp8110))) - (u_neo_elem_41_transform.v_trans))) / vec3<f32>((u_neo_elem_41_transform.v_scale), (u_neo_elem_41_transform.v_scale), (u_neo_elem_41_transform.v_scale))))).z));
	let tmp7544: f32 = (tmp7500 * tmp7503);
	let tmp7545: f32 = (tmp7494 * tmp7497);
	let tmp7551: f32 = (tmp7549 + tmp7550);
	let tmp7529: f32 = (tmp7527 + tmp7528);
	let tmp7582: vec4<f32> = (u_neo_elem_41_transform.v_quat);
	let tmp8022: vec3<f32> = (tmp8110);
	let tmp7420: f32 = (tmp7418 - tmp7419.v_o);
	let tmp7523: f32 = (tmp7494 * tmp7503);
	let tmp1001: vec3<f32> = (mat3x3<f32>(((c_glsl_const_01.v_o * ((tmp7225 * tmp7225) + (tmp7228 * tmp7228))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7228 * tmp7231) - (tmp7225 * tmp7234))), (c_glsl_const_01.v_o * ((tmp7228 * tmp7234) + (tmp7225 * tmp7231))), (c_glsl_const_01.v_o * ((tmp7228 * tmp7231) + (tmp7225 * tmp7234))), ((c_glsl_const_01.v_o * ((tmp7225 * tmp7225) + (tmp7231 * tmp7231))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((tmp7231 * tmp7234) - (tmp7225 * tmp7228))), (c_glsl_const_01.v_o * ((tmp7228 * tmp7234) - (tmp7225 * tmp7231))), (c_glsl_const_01.v_o * ((tmp7231 * tmp7234) + (tmp7225 * tmp7228))), ((c_glsl_const_01.v_o * ((tmp7225 * tmp7225) + (tmp7234 * tmp7234))) - c_glsl_const_02.v_o)) * (tmp7382));
	let tmp736: vec4<f32> = (tmp739.v_radius);
	let tmp7425: f32 = (tmp7421.v_o * tmp7424);
	let tmp7430: f32 = (tmp7426.v_o * tmp7429);
	let tmp7435: f32 = (tmp7431.v_o * tmp7434);
	let tmp7580: vec4<f32> = (u_neo_elem_41_transform.v_quat);
	let tmp7562: vec3<f32> = (tmp7559 / tmp7561);
	let tmp7442: f32 = (tmp7440 - tmp7441.v_o);
	let tmp7447: f32 = (tmp7443.v_o * tmp7446);
	let tmp7548: t_glsl_const_01 = c_glsl_const_01;
	let tmp7504: t_glsl_const_01 = c_glsl_const_01;
	let tmp7452: f32 = (tmp7448.v_o * tmp7451);
	let tmp7512: f32 = (tmp7497 * tmp7500);
	let tmp8199: vec3<f32> = ((((((((t_position(a_pos).v_pos))))))));
	let tmp7651: vec3<f32> = vec3<f32>(tmp7650, tmp7650, tmp7650);
	let tmp7929: vec3<f32> = (tmp8022);
	let tmp7649: vec3<f32> = (tmp7747);
	let tmp7592: f32 = (tmp7591.z);
	let tmp7589: f32 = (tmp7588.y);
	let tmp7586: f32 = (tmp7585.x);
	let tmp7583: f32 = (tmp7582.w);
	let tmp7553: t_glsl_const_02 = c_glsl_const_02;
	let tmp7552: f32 = (tmp7548.v_o * tmp7551);
	let tmp7546: f32 = (tmp7544 + tmp7545);
	let tmp7543: t_glsl_const_01 = c_glsl_const_01;
	let tmp7541: f32 = (tmp7539 - tmp7540);
	let tmp7538: t_glsl_const_01 = c_glsl_const_01;
	let tmp7536: f32 = (tmp7534 - tmp7535);
	let tmp7533: t_glsl_const_01 = c_glsl_const_01;
	let tmp7531: t_glsl_const_02 = c_glsl_const_02;
	let tmp7530: f32 = (tmp7526.v_o * tmp7529);
	let tmp8551: t_neo_elem_35_transform = u_neo_elem_35_transform;
	let tmp7524: f32 = (tmp7522 + tmp7523);
	let tmp7521: t_glsl_const_01 = c_glsl_const_01;
	let tmp7519: f32 = (tmp7517 + tmp7518);
	let tmp7516: t_glsl_const_01 = c_glsl_const_01;
	let tmp7514: f32 = (tmp7512 - tmp7513);
	let tmp7511: t_glsl_const_01 = c_glsl_const_01;
	let tmp7509: t_glsl_const_02 = c_glsl_const_02;
	let tmp7508: f32 = (tmp7504.v_o * tmp7507);
	let tmp7465: mat3x3<f32> = mat3x3<f32>(tmp7420, tmp7425, tmp7430, tmp7435, tmp7442, tmp7447, tmp7452, tmp7457, tmp7464);
	let tmp7399: vec3<f32> = (tmp7562);
	let tmp7376: vec3<f32> = (tmp7375 * (tmp7472));
	let tmp7581: f32 = length(tmp7580);
	let tmp787: f32 = mix(mix((tmp813.w), (tmp813.y), step(c_glsl_const_00.v_o, (tmp815.x))), mix((tmp813.z), (tmp813.x), step(c_glsl_const_00.v_o, (tmp815.x))), step(c_glsl_const_00.v_o, (tmp815.y)));
	let tmp1095: vec2<f32> = vec2<f32>((((mix(tmp1033, min(tmp1033, (length(max(tmp1018, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) + min(max((tmp1018.x), (tmp1018.y)), c_glsl_const_00.v_o))), step(c_glsl_const_00.v_o, tmp1058)) - (tmp1083.v_ra))) + mix((tmp1109.y), (tmp1109.x), step(c_glsl_const_00.v_o, (tmp1001.y)))), (abs((tmp1001.y)) - (tmp1113.v_height)));
	let tmp1111: f32 = (tmp1001.y);
	let tmp1000: t_neo_elem_38_mod = u_neo_elem_38_mod;
	let tmp662: t_neo_elem_42_prim = u_neo_elem_42_prim;
	let tmp7542: f32 = (tmp7538.v_o * tmp7541);
	let tmp7537: f32 = (tmp7533.v_o * tmp7536);
	let tmp7547: f32 = (tmp7543.v_o * tmp7546);
	let tmp7669: vec4<f32> = (u_neo_elem_42_transform.v_quat);
	let tmp8111: vec3<f32> = (tmp8199);
	let tmp7554: f32 = (tmp7552 - tmp7553.v_o);
	let tmp7680: vec4<f32> = tmp7669;
	let tmp7652: vec3<f32> = (tmp7649 / tmp7651);
	let tmp7835: vec3<f32> = (u_neo_elem_41_transform.v_trans);
	let tmp7677: vec4<f32> = tmp7669;
	let tmp661: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7669.w) / length(tmp7669)) * ((tmp7669.w) / length(tmp7669))) + (((tmp7669.x) / length(tmp7669)) * ((tmp7669.x) / length(tmp7669))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))) - (((tmp7669.w) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) + (((tmp7669.w) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))) + (((tmp7669.w) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))))), ((c_glsl_const_01.v_o * ((((tmp7669.w) / length(tmp7669)) * ((tmp7669.w) / length(tmp7669))) + (((tmp7677.y) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7677.y) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) - (((tmp7669.w) / length(tmp7669)) * ((tmp7669.x) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) - (((tmp7669.w) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7677.y) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) + (((tmp7669.w) / length(tmp7669)) * ((tmp7669.x) / length(tmp7669))))), ((c_glsl_const_01.v_o * ((((tmp7669.w) / length(tmp7669)) * ((tmp7669.w) / length(tmp7669))) + (((tmp7680.z) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))))) - c_glsl_const_02.v_o)) * ((((((tmp8111)) - (u_neo_elem_42_transform.v_trans))) / vec3<f32>((u_neo_elem_42_transform.v_scale), (u_neo_elem_42_transform.v_scale), (u_neo_elem_42_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7669.w) / length(tmp7669)) * ((tmp7669.w) / length(tmp7669))) + (((tmp7669.x) / length(tmp7669)) * ((tmp7669.x) / length(tmp7669))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))) - (((tmp7669.w) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) + (((tmp7669.w) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))) + (((tmp7669.w) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))))), ((c_glsl_const_01.v_o * ((((tmp7669.w) / length(tmp7669)) * ((tmp7669.w) / length(tmp7669))) + (((tmp7677.y) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7677.y) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) - (((tmp7669.w) / length(tmp7669)) * ((tmp7669.x) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7669.x) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) - (((tmp7669.w) / length(tmp7669)) * ((tmp7677.y) / length(tmp7669))))), (c_glsl_const_01.v_o * ((((tmp7677.y) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))) + (((tmp7669.w) / length(tmp7669)) * ((tmp7669.x) / length(tmp7669))))), ((c_glsl_const_01.v_o * ((((tmp7669.w) / length(tmp7669)) * ((tmp7669.w) / length(tmp7669))) + (((tmp7680.z) / length(tmp7669)) * ((tmp7680.z) / length(tmp7669))))) - c_glsl_const_02.v_o)) * ((((((tmp8111)) - (u_neo_elem_42_transform.v_trans))) / vec3<f32>((u_neo_elem_42_transform.v_scale), (u_neo_elem_42_transform.v_scale), (u_neo_elem_42_transform.v_scale))))).z));
	let tmp7674: vec4<f32> = tmp7669;
	let tmp659: vec4<f32> = (tmp662.v_radius);
	let tmp7532: f32 = (tmp7530 - tmp7531.v_o);
	let tmp7671: vec4<f32> = tmp7669;
	let tmp7640: f32 = ((tmp7592 / tmp7581) * (tmp7592 / tmp7581));
	let tmp7595: f32 = ((tmp7583 / tmp7581) * (tmp7583 / tmp7581));
	let tmp7525: f32 = (tmp7521.v_o * tmp7524);
	let tmp7596: f32 = ((tmp7586 / tmp7581) * (tmp7586 / tmp7581));
	let tmp7520: f32 = (tmp7516.v_o * tmp7519);
	let tmp7639: f32 = ((tmp7583 / tmp7581) * (tmp7583 / tmp7581));
	let tmp7590: f32 = (tmp7589 / tmp7581);
	let tmp7617: f32 = ((tmp7583 / tmp7581) * (tmp7583 / tmp7581));
	let tmp7618: f32 = (tmp7590 * tmp7590);
	let tmp7510: f32 = (tmp7508 - tmp7509.v_o);
	let tmp923: t_neo_elem_39_mod = u_neo_elem_39_mod;
	let tmp7834: vec3<f32> = (tmp7929);
	let tmp7515: f32 = (tmp7511.v_o * tmp7514);
	let tmp996: vec2<f32> = (tmp1000.v_radius);
	let tmp7466: vec3<f32> = (tmp7465 * tmp7399);
	let tmp7593: f32 = (tmp7592 / tmp7581);
	let tmp924: vec3<f32> = tmp7376;
	let tmp706: vec2<f32> = ((abs(tmp738) - (tmp739.v_dims)) + vec2<f32>(mix(mix((tmp736.w), (tmp736.y), step(c_glsl_const_00.v_o, (tmp738.x))), mix((tmp736.z), (tmp736.x), step(c_glsl_const_00.v_o, (tmp738.x))), step(c_glsl_const_00.v_o, (tmp738.y))), mix(mix((tmp736.w), (tmp736.y), step(c_glsl_const_00.v_o, (tmp738.x))), mix((tmp736.z), (tmp736.x), step(c_glsl_const_00.v_o, (tmp738.x))), step(c_glsl_const_00.v_o, (tmp738.y)))));
	let tmp7587: f32 = (tmp7586 / tmp7581);
	let tmp7584: f32 = (tmp7583 / tmp7581);
	let tmp8552: t_neo_elem_36_transform = u_neo_elem_36_transform;
	let tmp7619: f32 = (tmp7617 + tmp7618);
	let tmp7624: f32 = (tmp7590 * tmp7593);
	let tmp7555: mat3x3<f32> = mat3x3<f32>(tmp7510, tmp7515, tmp7520, tmp7525, tmp7532, tmp7537, tmp7542, tmp7547, tmp7554);
	let tmp7625: f32 = (tmp7584 * tmp7587);
	let tmp7629: f32 = (tmp7587 * tmp7593);
	let tmp7630: f32 = (tmp7584 * tmp7590);
	let tmp7634: f32 = (tmp7590 * tmp7593);
	let tmp7635: f32 = (tmp7584 * tmp7587);
	let tmp585: t_neo_elem_43_prim = u_neo_elem_43_prim;
	let tmp7594: t_glsl_const_01 = c_glsl_const_01;
	let tmp7638: t_glsl_const_01 = c_glsl_const_01;
	let tmp7641: f32 = (tmp7639 + tmp7640);
	let tmp7608: f32 = (tmp7584 * tmp7590);
	let tmp7597: f32 = (tmp7595 + tmp7596);
	let tmp7836: vec3<f32> = (tmp7834 - tmp7835);
	let tmp7672: f32 = (tmp7671.w);
	let tmp7675: f32 = (tmp7674.x);
	let tmp7678: f32 = (tmp7677.y);
	let tmp7602: f32 = (tmp7587 * tmp7590);
	let tmp7603: f32 = (tmp7584 * tmp7593);
	let tmp7681: f32 = (tmp7680.z);
	let tmp8019: vec3<f32> = (tmp8111);
	let tmp7670: f32 = length(tmp7669);
	let tmp847: vec3<f32> = tmp7466;
	let tmp982: vec2<f32> = vec2<f32>((((min(max((tmp937.x), (tmp937.y)), c_glsl_const_00.v_o) + (length(max(tmp937, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp941))) + mix((tmp996.y), (tmp996.x), step(c_glsl_const_00.v_o, (tmp924.y)))), (abs((tmp924.y)) - (tmp1000.v_height)));
	let tmp8288: vec3<f32> = (((((((t_position(a_pos).v_pos)))))));
	let tmp7739: f32 = (u_neo_elem_41_transform.v_scale);
	let tmp1102: f32 = mix((tmp1109.y), (tmp1109.x), step(c_glsl_const_00.v_o, tmp1111));
	let tmp7607: f32 = (tmp7587 * tmp7593);
	let tmp7489: vec3<f32> = (tmp7652);
	let tmp998: f32 = (tmp924.y);
	let tmp919: vec2<f32> = (tmp923.v_radius);
	let tmp7612: f32 = (tmp7587 * tmp7590);
	let tmp7613: f32 = (tmp7584 * tmp7593);
	let tmp7616: t_glsl_const_01 = c_glsl_const_01;
	let tmp7673: f32 = (tmp7672 / tmp7670);
	let tmp7760: vec4<f32> = (u_neo_elem_43_transform.v_quat);
	let tmp7609: f32 = (tmp7607 + tmp7608);
	let tmp7556: vec3<f32> = (tmp7555 * tmp7489);
	let tmp7769: vec4<f32> = (u_neo_elem_43_transform.v_quat);
	let tmp7676: f32 = (tmp7675 / tmp7670);
	let tmp8200: vec3<f32> = (tmp8288);
	let tmp7626: f32 = (tmp7624 - tmp7625);
	let tmp7738: vec3<f32> = (tmp7836);
	let tmp582: vec4<f32> = (tmp585.v_radius);
	let tmp7642: f32 = (tmp7638.v_o * tmp7641);
	let tmp7598: f32 = (tmp7594.v_o * tmp7597);
	let tmp7599: t_glsl_const_02 = c_glsl_const_02;
	let tmp7766: vec4<f32> = (u_neo_elem_43_transform.v_quat);
	let tmp7601: t_glsl_const_01 = c_glsl_const_01;
	let tmp7604: f32 = (tmp7602 - tmp7603);
	let tmp7684: f32 = (tmp7673 * tmp7673);
	let tmp7606: t_glsl_const_01 = c_glsl_const_01;
	let tmp7682: f32 = (tmp7681 / tmp7670);
	let tmp7679: f32 = (tmp7678 / tmp7670);
	let tmp7685: f32 = (tmp7676 * tmp7676);
	let tmp7636: f32 = (tmp7634 + tmp7635);
	let tmp7728: f32 = (tmp7673 * tmp7673);
	let tmp7924: vec3<f32> = (tmp8019);
	let tmp7740: vec3<f32> = vec3<f32>(tmp7739, tmp7739, tmp7739);
	let tmp7729: f32 = (tmp7682 * tmp7682);
	let tmp7763: vec4<f32> = (u_neo_elem_43_transform.v_quat);
	let tmp7706: f32 = (tmp7673 * tmp7673);
	let tmp7707: f32 = (tmp7679 * tmp7679);
	let tmp7396: f32 = (((((((min(max((tmp1326.x), (tmp1326.y)), c_glsl_const_00.v_o) + (length(max(tmp1326, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1333)))) * (tmp8550.v_scale)))));
	let tmp584: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7760.w) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7763.x) / length((u_neo_elem_43_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))) - (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7760.w) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7766.y) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7766.y) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) - (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7763.x) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) - (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7766.y) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7763.x) / length((u_neo_elem_43_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7760.w) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7769.z) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((tmp8200)) - (u_neo_elem_43_transform.v_trans))) / vec3<f32>((u_neo_elem_43_transform.v_scale), (u_neo_elem_43_transform.v_scale), (u_neo_elem_43_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7760.w) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7763.x) / length((u_neo_elem_43_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))) - (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7760.w) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7766.y) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7766.y) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) - (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7763.x) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7763.x) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) - (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7766.y) / length((u_neo_elem_43_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7766.y) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7763.x) / length((u_neo_elem_43_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7760.w) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7760.w) / length((u_neo_elem_43_transform.v_quat)))) + (((tmp7769.z) / length((u_neo_elem_43_transform.v_quat))) * ((tmp7769.z) / length((u_neo_elem_43_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((tmp8200)) - (u_neo_elem_43_transform.v_trans))) / vec3<f32>((u_neo_elem_43_transform.v_scale), (u_neo_elem_43_transform.v_scale), (u_neo_elem_43_transform.v_scale))))).z));
	let tmp7623: t_glsl_const_01 = c_glsl_const_01;
	let tmp629: vec2<f32> = ((abs(tmp661) - (tmp662.v_dims)) + vec2<f32>(mix(mix((tmp659.w), (tmp659.y), step(c_glsl_const_00.v_o, (tmp661.x))), mix((tmp659.z), (tmp659.x), step(c_glsl_const_00.v_o, (tmp661.x))), step(c_glsl_const_00.v_o, (tmp661.y))), mix(mix((tmp659.w), (tmp659.y), step(c_glsl_const_00.v_o, (tmp661.x))), mix((tmp659.z), (tmp659.x), step(c_glsl_const_00.v_o, (tmp661.x))), step(c_glsl_const_00.v_o, (tmp661.y)))));
	let tmp710: f32 = mix(mix((tmp736.w), (tmp736.y), step(c_glsl_const_00.v_o, (tmp738.x))), mix((tmp736.z), (tmp736.x), step(c_glsl_const_00.v_o, (tmp738.x))), step(c_glsl_const_00.v_o, (tmp738.y)));
	let tmp7758: vec4<f32> = (u_neo_elem_43_transform.v_quat);
	let tmp7633: t_glsl_const_01 = c_glsl_const_01;
	let tmp905: vec2<f32> = vec2<f32>((((min(max((tmp860.x), (tmp860.y)), c_glsl_const_00.v_o) + (length(max(tmp860, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp864))) + mix((tmp919.y), (tmp919.x), step(c_glsl_const_00.v_o, (tmp847.y)))), (abs((tmp847.y)) - (tmp923.v_height)));
	let tmp7621: t_glsl_const_02 = c_glsl_const_02;
	let tmp7620: f32 = (tmp7616.v_o * tmp7619);
	let tmp7631: f32 = (tmp7629 - tmp7630);
	let tmp7628: t_glsl_const_01 = c_glsl_const_01;
	let tmp7643: t_glsl_const_02 = c_glsl_const_02;
	let tmp921: f32 = (tmp847.y);
	let tmp846: t_neo_elem_40_mod = u_neo_elem_40_mod;
	let tmp7925: vec3<f32> = (u_neo_elem_42_transform.v_trans);
	let tmp7614: f32 = (tmp7612 + tmp7613);
	let tmp7611: t_glsl_const_01 = c_glsl_const_01;
	let tmp7696: f32 = (tmp7676 * tmp7682);
	let tmp7697: f32 = (tmp7673 * tmp7679);
	let tmp508: t_neo_elem_44_prim = u_neo_elem_44_prim;
	let tmp7708: f32 = (tmp7706 + tmp7707);
	let tmp7392: f32 = ((((((min(max((tmp1249.x), (tmp1249.y)), c_glsl_const_00.v_o) + (length(max(tmp1249, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1256)))) * (tmp8551.v_scale))));
	let tmp7701: f32 = (tmp7676 * tmp7679);
	let tmp7702: f32 = (tmp7673 * tmp7682);
	let tmp7759: f32 = length(tmp7758);
	let tmp7723: f32 = (tmp7679 * tmp7682);
	let tmp7705: t_glsl_const_01 = c_glsl_const_01;
	let tmp7761: f32 = (tmp7760.w);
	let tmp7724: f32 = (tmp7673 * tmp7676);
	let tmp7395: f32 = (min((max((min((min((max((min((max((min((min((min((min((min((min((min((min((min((min((max((max((max((max((min((min((min((min((max((min((max((max((max((max((min((min((((((((min(max((tmp3867.x), (tmp3867.y)), c_glsl_const_00.v_o) + (length(max(tmp3867, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3874)))) * (tmp8516.v_scale))))), (((((((min(max((tmp3944.x), (tmp3944.y)), c_glsl_const_00.v_o) + (length(max(tmp3944, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3951)))) * (tmp8517.v_scale))))))), (((((((min(max((tmp3790.x), (tmp3790.y)), c_glsl_const_00.v_o) + (length(max(tmp3790, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3797)))) * (tmp8518.v_scale))))))), opp((((((((min(max((tmp3713.x), (tmp3713.y)), c_glsl_const_00.v_o) + (length(max(tmp3713, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3720)))) * (tmp8519.v_scale)))))))), opp((((((((min(max((tmp3636.x), (tmp3636.y)), c_glsl_const_00.v_o) + (length(max(tmp3636, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3643)))) * (tmp8520.v_scale)))))))), opp((((((((min(max((tmp3559.x), (tmp3559.y)), c_glsl_const_00.v_o) + (length(max(tmp3559, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3566)))) * (tmp8521.v_scale)))))))), opp((((((((min(max((tmp3482.x), (tmp3482.y)), c_glsl_const_00.v_o) + (length(max(tmp3482, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3489)))) * (tmp8522.v_scale)))))))), (((((((min(max((tmp3405.x), (tmp3405.y)), c_glsl_const_00.v_o) + (length(max(tmp3405, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3412)))) * (tmp8523.v_scale))))))), opp((((((((min(max((tmp3328.x), (tmp3328.y)), c_glsl_const_00.v_o) + (length(max(tmp3328, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3335)))) * (tmp8524.v_scale)))))))), (((((((min(max((tmp3251.x), (tmp3251.y)), c_glsl_const_00.v_o) + (length(max(tmp3251, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3258)))) * (tmp8525.v_scale))))))), (((((((min(max((tmp3174.x), (tmp3174.y)), c_glsl_const_00.v_o) + (length(max(tmp3174, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3181)))) * (tmp8526.v_scale))))))), (((((((min(max((tmp3097.x), (tmp3097.y)), c_glsl_const_00.v_o) + (length(max(tmp3097, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3104)))) * (tmp8527.v_scale))))))), (((((((min(max((tmp3020.x), (tmp3020.y)), c_glsl_const_00.v_o) + (length(max(tmp3020, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp3027)))) * (tmp8528.v_scale))))))), opp((((((((min(max((tmp2943.x), (tmp2943.y)), c_glsl_const_00.v_o) + (length(max(tmp2943, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2950)))) * (tmp8529.v_scale)))))))), opp((((((((min(max((tmp2866.x), (tmp2866.y)), c_glsl_const_00.v_o) + (length(max(tmp2866, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2873)))) * (tmp8530.v_scale)))))))), opp((((((((min(max((tmp2789.x), (tmp2789.y)), c_glsl_const_00.v_o) + (length(max(tmp2789, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2796)))) * (tmp8531.v_scale)))))))), opp((((((((min(max((tmp2712.x), (tmp2712.y)), c_glsl_const_00.v_o) + (length(max(tmp2712, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2719)))) * (tmp8532.v_scale)))))))), (((((((min(max((tmp2635.x), (tmp2635.y)), c_glsl_const_00.v_o) + (length(max(tmp2635, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2642)))) * (tmp8533.v_scale))))))), (((((((min(max((tmp2558.x), (tmp2558.y)), c_glsl_const_00.v_o) + (length(max(tmp2558, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2565)))) * (tmp8534.v_scale))))))), (((((((min(max((tmp2481.x), (tmp2481.y)), c_glsl_const_00.v_o) + (length(max(tmp2481, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2488)))) * (tmp8535.v_scale))))))), (((((((min(max((tmp2404.x), (tmp2404.y)), c_glsl_const_00.v_o) + (length(max(tmp2404, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2411)))) * (tmp8536.v_scale))))))), (((((((min(max((tmp2327.x), (tmp2327.y)), c_glsl_const_00.v_o) + (length(max(tmp2327, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2334)))) * (tmp8537.v_scale))))))), (((((((min(max((tmp2250.x), (tmp2250.y)), c_glsl_const_00.v_o) + (length(max(tmp2250, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2257)))) * (tmp8538.v_scale))))))), (((((((min(max((tmp2173.x), (tmp2173.y)), c_glsl_const_00.v_o) + (length(max(tmp2173, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2180)))) * (tmp8539.v_scale))))))), (((((((min(max((tmp2096.x), (tmp2096.y)), c_glsl_const_00.v_o) + (length(max(tmp2096, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2103)))) * (tmp8540.v_scale))))))), (((((((min(max((tmp2019.x), (tmp2019.y)), c_glsl_const_00.v_o) + (length(max(tmp2019, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp2026)))) * (tmp8541.v_scale))))))), (((((((min(max((tmp1942.x), (tmp1942.y)), c_glsl_const_00.v_o) + (length(max(tmp1942, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1949)))) * (tmp8542.v_scale))))))), opp((((((((min(max((tmp1865.x), (tmp1865.y)), c_glsl_const_00.v_o) + (length(max(tmp1865, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1872)))) * (tmp8543.v_scale)))))))), (((((((min(max((tmp1788.x), (tmp1788.y)), c_glsl_const_00.v_o) + (length(max(tmp1788, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1795)))) * (tmp8544.v_scale))))))), opp((((((((min(max((tmp1711.x), (tmp1711.y)), c_glsl_const_00.v_o) + (length(max(tmp1711, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1718)))) * (tmp8545.v_scale)))))))), (((((((min(max((tmp1634.x), (tmp1634.y)), c_glsl_const_00.v_o) + (length(max(tmp1634, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1641)))) * (tmp8546.v_scale))))))), (((((((min(max((tmp1557.x), (tmp1557.y)), c_glsl_const_00.v_o) + (length(max(tmp1557, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1564)))) * (tmp8547.v_scale))))))), opp((((((((min(max((tmp1480.x), (tmp1480.y)), c_glsl_const_00.v_o) + (length(max(tmp1480, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1487)))) * (tmp8548.v_scale)))))))), (((((((min(max((tmp1403.x), (tmp1403.y)), c_glsl_const_00.v_o) + (length(max(tmp1403, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1410)))) * (tmp8549.v_scale)))))));
	let tmp7600: f32 = (tmp7598 - tmp7599.v_o);
	let tmp7397: f32 = opp(tmp7396);
	let tmp7637: f32 = (tmp7633.v_o * tmp7636);
	let tmp7605: f32 = (tmp7601.v_o * tmp7604);
	let tmp7926: vec3<f32> = (tmp7924 - tmp7925);
	let tmp7610: f32 = (tmp7606.v_o * tmp7609);
	let tmp7622: f32 = (tmp7620 - tmp7621.v_o);
	let tmp7714: f32 = (tmp7673 * tmp7676);
	let tmp7683: t_glsl_const_01 = c_glsl_const_01;
	let tmp7828: f32 = (u_neo_elem_42_transform.v_scale);
	let tmp7686: f32 = (tmp7684 + tmp7685);
	let tmp8377: vec3<f32> = ((((((t_position(a_pos).v_pos))))));
	let tmp7727: t_glsl_const_01 = c_glsl_const_01;
	let tmp7632: f32 = (tmp7628.v_o * tmp7631);
	let tmp7691: f32 = (tmp7676 * tmp7679);
	let tmp7713: f32 = (tmp7679 * tmp7682);
	let tmp7692: f32 = (tmp7673 * tmp7682);
	let tmp8108: vec3<f32> = (tmp8200);
	let tmp7627: f32 = (tmp7623.v_o * tmp7626);
	let tmp770: vec3<f32> = tmp7556;
	let tmp989: f32 = mix((tmp996.y), (tmp996.x), step(c_glsl_const_00.v_o, tmp998));
	let tmp7730: f32 = (tmp7728 + tmp7729);
	let tmp7718: f32 = (tmp7676 * tmp7682);
	let tmp7644: f32 = (tmp7642 - tmp7643.v_o);
	let tmp7770: f32 = (tmp7769.z);
	let tmp842: vec2<f32> = (tmp846.v_radius);
	let tmp7767: f32 = (tmp7766.y);
	let tmp7615: f32 = (tmp7611.v_o * tmp7614);
	let tmp7741: vec3<f32> = (tmp7738 / tmp7740);
	let tmp7719: f32 = (tmp7673 * tmp7679);
	let tmp7764: f32 = (tmp7763.x);
	let tmp7817: f32 = ((tmp7761 / tmp7759) * (tmp7761 / tmp7759));
	let tmp7818: f32 = ((tmp7770 / tmp7759) * (tmp7770 / tmp7759));
	let tmp7827: vec3<f32> = (tmp7926);
	let tmp7829: vec3<f32> = vec3<f32>(tmp7828, tmp7828, tmp7828);
	let tmp7850: vec4<f32> = (u_neo_elem_44_transform.v_quat);
	let tmp7853: vec4<f32> = (u_neo_elem_44_transform.v_quat);
	let tmp7856: vec4<f32> = (u_neo_elem_44_transform.v_quat);
	let tmp7859: vec4<f32> = (u_neo_elem_44_transform.v_quat);
	let tmp8289: vec3<f32> = (tmp8377);
	let tmp507: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7850.w) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7853.x) / length((u_neo_elem_44_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))) - (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7850.w) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7856.y) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7856.y) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) - (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7853.x) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) - (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7856.y) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7853.x) / length((u_neo_elem_44_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7850.w) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7859.z) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((tmp8289)) - (u_neo_elem_44_transform.v_trans))) / vec3<f32>((u_neo_elem_44_transform.v_scale), (u_neo_elem_44_transform.v_scale), (u_neo_elem_44_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7850.w) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7853.x) / length((u_neo_elem_44_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))) - (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7850.w) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7856.y) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7856.y) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) - (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7853.x) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7853.x) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) - (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7856.y) / length((u_neo_elem_44_transform.v_quat)))))), (c_glsl_const_01.v_o * ((((tmp7856.y) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7853.x) / length((u_neo_elem_44_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp7850.w) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7850.w) / length((u_neo_elem_44_transform.v_quat)))) + (((tmp7859.z) / length((u_neo_elem_44_transform.v_quat))) * ((tmp7859.z) / length((u_neo_elem_44_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((tmp8289)) - (u_neo_elem_44_transform.v_trans))) / vec3<f32>((u_neo_elem_44_transform.v_scale), (u_neo_elem_44_transform.v_scale), (u_neo_elem_44_transform.v_scale))))).z));
	let tmp7389: f32 = (((((min(max((tmp1172.x), (tmp1172.y)), c_glsl_const_00.v_o) + (length(max(tmp1172, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1179)))) * (tmp8552.v_scale)));
	let tmp7762: f32 = (tmp7761 / tmp7759);
	let tmp7579: vec3<f32> = (tmp7741);
	let tmp7771: f32 = (tmp7770 / tmp7759);
	let tmp7398: f32 = max(tmp7395, tmp7397);
	let tmp505: vec4<f32> = (tmp508.v_radius);
	let tmp7768: f32 = (tmp7767 / tmp7759);
	let tmp7765: f32 = (tmp7764 / tmp7759);
	let tmp8553: t_neo_elem_37_transform = u_neo_elem_37_transform;
	let tmp552: vec2<f32> = ((abs(tmp584) - (tmp585.v_dims)) + vec2<f32>(mix(mix((tmp582.w), (tmp582.y), step(c_glsl_const_00.v_o, (tmp584.x))), mix((tmp582.z), (tmp582.x), step(c_glsl_const_00.v_o, (tmp584.x))), step(c_glsl_const_00.v_o, (tmp584.y))), mix(mix((tmp582.w), (tmp582.y), step(c_glsl_const_00.v_o, (tmp584.x))), mix((tmp582.z), (tmp582.x), step(c_glsl_const_00.v_o, (tmp584.x))), step(c_glsl_const_00.v_o, (tmp584.y)))));
	let tmp7848: vec4<f32> = (u_neo_elem_44_transform.v_quat);
	let tmp633: f32 = mix(mix((tmp659.w), (tmp659.y), step(c_glsl_const_00.v_o, (tmp661.x))), mix((tmp659.z), (tmp659.x), step(c_glsl_const_00.v_o, (tmp661.x))), step(c_glsl_const_00.v_o, (tmp661.y)));
	let tmp7645: mat3x3<f32> = mat3x3<f32>(tmp7600, tmp7605, tmp7610, tmp7615, tmp7622, tmp7627, tmp7632, tmp7637, tmp7644);
	let tmp7687: f32 = (tmp7683.v_o * tmp7686);
	let tmp7688: t_glsl_const_02 = c_glsl_const_02;
	let tmp7690: t_glsl_const_01 = c_glsl_const_01;
	let tmp828: vec2<f32> = vec2<f32>((((min(max((tmp783.x), (tmp783.y)), c_glsl_const_00.v_o) + (length(max(tmp783, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp787))) + mix((tmp842.y), (tmp842.x), step(c_glsl_const_00.v_o, (tmp770.y)))), (abs((tmp770.y)) - (tmp846.v_height)));
	let tmp7693: f32 = (tmp7691 - tmp7692);
	let tmp7695: t_glsl_const_01 = c_glsl_const_01;
	let tmp7698: f32 = (tmp7696 + tmp7697);
	let tmp7700: t_glsl_const_01 = c_glsl_const_01;
	let tmp7703: f32 = (tmp7701 + tmp7702);
	let tmp7709: f32 = (tmp7705.v_o * tmp7708);
	let tmp7710: t_glsl_const_02 = c_glsl_const_02;
	let tmp7486: f32 = (tmp7392);
	let tmp7712: t_glsl_const_01 = c_glsl_const_01;
	let tmp7715: f32 = (tmp7713 - tmp7714);
	let tmp7717: t_glsl_const_01 = c_glsl_const_01;
	let tmp7720: f32 = (tmp7718 - tmp7719);
	let tmp7722: t_glsl_const_01 = c_glsl_const_01;
	let tmp7725: f32 = (tmp7723 + tmp7724);
	let tmp7731: f32 = (tmp7727.v_o * tmp7730);
	let tmp912: f32 = mix((tmp919.y), (tmp919.x), step(c_glsl_const_00.v_o, tmp921));
	let tmp7732: t_glsl_const_02 = c_glsl_const_02;
	let tmp844: f32 = (tmp770.y);
	let tmp7773: f32 = (tmp7762 * tmp7762);
	let tmp7774: f32 = (tmp7765 * tmp7765);
	let tmp7795: f32 = (tmp7762 * tmp7762);
	let tmp7796: f32 = (tmp7768 * tmp7768);
	let tmp8015: vec3<f32> = (u_neo_elem_43_transform.v_trans);
	let tmp8014: vec3<f32> = (tmp8108);
	let tmp7816: t_glsl_const_01 = c_glsl_const_01;
	let tmp7711: f32 = (tmp7709 - tmp7710.v_o);
	let tmp7704: f32 = (tmp7700.v_o * tmp7703);
	let tmp7699: f32 = (tmp7695.v_o * tmp7698);
	let tmp7830: vec3<f32> = (tmp7827 / tmp7829);
	let tmp7819: f32 = (tmp7817 + tmp7818);
	let tmp7808: f32 = (tmp7762 * tmp7768);
	let tmp7646: vec3<f32> = (tmp7645 * tmp7579);
	let tmp7694: f32 = (tmp7690.v_o * tmp7693);
	let tmp7851: f32 = (tmp7850.w);
	let tmp7781: f32 = (tmp7762 * tmp7771);
	let tmp7854: f32 = (tmp7853.x);
	let tmp7790: f32 = (tmp7765 * tmp7768);
	let tmp7857: f32 = (tmp7856.y);
	let tmp7849: f32 = length(tmp7848);
	let tmp7860: f32 = (tmp7859.z);
	let tmp7785: f32 = (tmp7765 * tmp7771);
	let tmp7786: f32 = (tmp7762 * tmp7768);
	let tmp7791: f32 = (tmp7762 * tmp7771);
	let tmp7794: t_glsl_const_01 = c_glsl_const_01;
	let tmp7726: f32 = (tmp7722.v_o * tmp7725);
	let tmp7797: f32 = (tmp7795 + tmp7796);
	let tmp7689: f32 = (tmp7687 - tmp7688.v_o);
	let tmp7918: f32 = (u_neo_elem_43_transform.v_scale);
	let tmp8016: vec3<f32> = (tmp8014 - tmp8015);
	let tmp7772: t_glsl_const_01 = c_glsl_const_01;
	let tmp7482: f32 = (tmp7389);
	let tmp7721: f32 = (tmp7717.v_o * tmp7720);
	let tmp7485: f32 = (tmp7398);
	let tmp7716: f32 = (tmp7712.v_o * tmp7715);
	let tmp7487: f32 = opp(tmp7486);
	let tmp7802: f32 = (tmp7768 * tmp7771);
	let tmp8197: vec3<f32> = (tmp8289);
	let tmp7803: f32 = (tmp7762 * tmp7765);
	let tmp7807: f32 = (tmp7765 * tmp7771);
	let tmp7733: f32 = (tmp7731 - tmp7732.v_o);
	let tmp7780: f32 = (tmp7765 * tmp7768);
	let tmp7383: f32 = (((min(max((tmp1095.x), (tmp1095.y)), c_glsl_const_00.v_o) + (length(max(tmp1095, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp1102))));
	let tmp7384: f32 = (tmp8553.v_scale);
	let tmp8466: vec3<f32> = (((((t_position(a_pos).v_pos)))));
	let tmp7812: f32 = (tmp7768 * tmp7771);
	let tmp431: t_neo_elem_45_prim = u_neo_elem_45_prim;
	let tmp7813: f32 = (tmp7762 * tmp7765);
	let tmp769: t_neo_elem_41_mod = u_neo_elem_41_mod;
	let tmp7775: f32 = (tmp7773 + tmp7774);
	let tmp7820: f32 = (tmp7816.v_o * tmp7819);
	let tmp7821: t_glsl_const_02 = c_glsl_const_02;
	let tmp7668: vec3<f32> = (tmp7830);
	let tmp835: f32 = mix((tmp842.y), (tmp842.x), step(c_glsl_const_00.v_o, tmp844));
	let tmp8103: vec3<f32> = (tmp8197);
	let tmp7949: vec4<f32> = (u_neo_elem_45_transform.v_quat);
	let tmp7863: f32 = ((tmp7851 / tmp7849) * (tmp7851 / tmp7849));
	let tmp7864: f32 = ((tmp7854 / tmp7849) * (tmp7854 / tmp7849));
	let tmp7885: f32 = ((tmp7851 / tmp7849) * (tmp7851 / tmp7849));
	let tmp7886: f32 = ((tmp7857 / tmp7849) * (tmp7857 / tmp7849));
	let tmp7855: f32 = (tmp7854 / tmp7849);
	let tmp7908: f32 = ((tmp7860 / tmp7849) * (tmp7860 / tmp7849));
	let tmp7917: vec3<f32> = (tmp8016);
	let tmp7919: vec3<f32> = vec3<f32>(tmp7918, tmp7918, tmp7918);
	let tmp7938: vec4<f32> = (u_neo_elem_45_transform.v_quat);
	let tmp8554: t_neo_elem_38_transform = u_neo_elem_38_transform;
	let tmp7858: f32 = (tmp7857 / tmp7849);
	let tmp7861: f32 = (tmp7860 / tmp7849);
	let tmp7940: vec4<f32> = tmp7938;
	let tmp7943: vec4<f32> = tmp7938;
	let tmp7946: vec4<f32> = tmp7938;
	let tmp430: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7940.w) / length(tmp7938)) * ((tmp7940.w) / length(tmp7938))) + (((tmp7943.x) / length(tmp7938)) * ((tmp7943.x) / length(tmp7938))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))) - (((tmp7940.w) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) + (((tmp7940.w) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))) + (((tmp7940.w) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))))), ((c_glsl_const_01.v_o * ((((tmp7940.w) / length(tmp7938)) * ((tmp7940.w) / length(tmp7938))) + (((tmp7946.y) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7946.y) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) - (((tmp7940.w) / length(tmp7938)) * ((tmp7943.x) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) - (((tmp7940.w) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7946.y) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) + (((tmp7940.w) / length(tmp7938)) * ((tmp7943.x) / length(tmp7938))))), ((c_glsl_const_01.v_o * ((((tmp7940.w) / length(tmp7938)) * ((tmp7940.w) / length(tmp7938))) + (((tmp7949.z) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))))) - c_glsl_const_02.v_o)) * (((((((tmp8466))) - (u_neo_elem_45_transform.v_trans))) / vec3<f32>((u_neo_elem_45_transform.v_scale), (u_neo_elem_45_transform.v_scale), (u_neo_elem_45_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp7940.w) / length(tmp7938)) * ((tmp7940.w) / length(tmp7938))) + (((tmp7943.x) / length(tmp7938)) * ((tmp7943.x) / length(tmp7938))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))) - (((tmp7940.w) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) + (((tmp7940.w) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))) + (((tmp7940.w) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))))), ((c_glsl_const_01.v_o * ((((tmp7940.w) / length(tmp7938)) * ((tmp7940.w) / length(tmp7938))) + (((tmp7946.y) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp7946.y) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) - (((tmp7940.w) / length(tmp7938)) * ((tmp7943.x) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7943.x) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) - (((tmp7940.w) / length(tmp7938)) * ((tmp7946.y) / length(tmp7938))))), (c_glsl_const_01.v_o * ((((tmp7946.y) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))) + (((tmp7940.w) / length(tmp7938)) * ((tmp7943.x) / length(tmp7938))))), ((c_glsl_const_01.v_o * ((((tmp7940.w) / length(tmp7938)) * ((tmp7940.w) / length(tmp7938))) + (((tmp7949.z) / length(tmp7938)) * ((tmp7949.z) / length(tmp7938))))) - c_glsl_const_02.v_o)) * (((((((tmp8466))) - (u_neo_elem_45_transform.v_trans))) / vec3<f32>((u_neo_elem_45_transform.v_scale), (u_neo_elem_45_transform.v_scale), (u_neo_elem_45_transform.v_scale))))).z));
	let tmp7377: f32 = ((min(max((tmp982.x), (tmp982.y)), c_glsl_const_00.v_o) + (length(max(tmp982, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp989)));
	let tmp7385: f32 = (tmp7383 * tmp7384);
	let tmp7734: mat3x3<f32> = mat3x3<f32>(tmp7689, tmp7694, tmp7699, tmp7704, tmp7711, tmp7716, tmp7721, tmp7726, tmp7733);
	let tmp7852: f32 = (tmp7851 / tmp7849);
	let tmp428: vec4<f32> = (tmp431.v_radius);
	let tmp7776: f32 = (tmp7772.v_o * tmp7775);
	let tmp7777: t_glsl_const_02 = c_glsl_const_02;
	let tmp7779: t_glsl_const_01 = c_glsl_const_01;
	let tmp556: f32 = mix(mix((tmp582.w), (tmp582.y), step(c_glsl_const_00.v_o, (tmp584.x))), mix((tmp582.z), (tmp582.x), step(c_glsl_const_00.v_o, (tmp584.x))), step(c_glsl_const_00.v_o, (tmp584.y)));
	let tmp7488: f32 = max(tmp7485, tmp7487);
	let tmp7799: t_glsl_const_02 = c_glsl_const_02;
	let tmp7801: t_glsl_const_01 = c_glsl_const_01;
	let tmp8378: vec3<f32> = (tmp8466);
	let tmp7784: t_glsl_const_01 = c_glsl_const_01;
	let tmp7804: f32 = (tmp7802 - tmp7803);
	let tmp7806: t_glsl_const_01 = c_glsl_const_01;
	let tmp7787: f32 = (tmp7785 + tmp7786);
	let tmp8104: vec3<f32> = (u_neo_elem_44_transform.v_trans);
	let tmp7907: f32 = (tmp7852 * tmp7852);
	let tmp7809: f32 = (tmp7807 - tmp7808);
	let tmp7798: f32 = (tmp7794.v_o * tmp7797);
	let tmp7789: t_glsl_const_01 = c_glsl_const_01;
	let tmp7814: f32 = (tmp7812 + tmp7813);
	let tmp7576: f32 = (tmp7482);
	let tmp765: vec2<f32> = (tmp769.v_radius);
	let tmp475: vec2<f32> = ((abs(tmp507) - (tmp508.v_dims)) + vec2<f32>(mix(mix((tmp505.w), (tmp505.y), step(c_glsl_const_00.v_o, (tmp507.x))), mix((tmp505.z), (tmp505.x), step(c_glsl_const_00.v_o, (tmp507.x))), step(c_glsl_const_00.v_o, (tmp507.y))), mix(mix((tmp505.w), (tmp505.y), step(c_glsl_const_00.v_o, (tmp507.x))), mix((tmp505.z), (tmp505.x), step(c_glsl_const_00.v_o, (tmp507.x))), step(c_glsl_const_00.v_o, (tmp507.y)))));
	let tmp7792: f32 = (tmp7790 + tmp7791);
	let tmp7811: t_glsl_const_01 = c_glsl_const_01;
	let tmp7782: f32 = (tmp7780 - tmp7781);
	let tmp693: vec3<f32> = tmp7646;
	let tmp7865: f32 = (tmp7863 + tmp7864);
	let tmp7862: t_glsl_const_01 = c_glsl_const_01;
	let tmp7822: f32 = (tmp7820 - tmp7821.v_o);
	let tmp7815: f32 = (tmp7811.v_o * tmp7814);
	let tmp7810: f32 = (tmp7806.v_o * tmp7809);
	let tmp7805: f32 = (tmp7801.v_o * tmp7804);
	let tmp7800: f32 = (tmp7798 - tmp7799.v_o);
	let tmp7793: f32 = (tmp7789.v_o * tmp7792);
	let tmp7788: f32 = (tmp7784.v_o * tmp7787);
	let tmp7783: f32 = (tmp7779.v_o * tmp7782);
	let tmp7778: f32 = (tmp7776 - tmp7777.v_o);
	let tmp7735: vec3<f32> = (tmp7734 * tmp7668);
	let tmp7577: f32 = opp(tmp7576);
	let tmp7575: f32 = (tmp7488);
	let tmp354: t_neo_elem_46_prim = u_neo_elem_46_prim;
	let tmp692: t_neo_elem_42_mod = u_neo_elem_42_mod;
	let tmp767: f32 = (tmp693.y);
	let tmp8485: vec3<f32> = ((((t_position(a_pos).v_pos))));
	let tmp7479: f32 = (tmp7385);
	let tmp7474: f32 = (tmp8554.v_scale);
	let tmp7473: f32 = (tmp7377);
	let tmp8286: vec3<f32> = (tmp8378);
	let tmp7467: f32 = ((min(max((tmp905.x), (tmp905.y)), c_glsl_const_00.v_o) + (length(max(tmp905, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp912)));
	let tmp8008: f32 = (u_neo_elem_44_transform.v_scale);
	let tmp751: vec2<f32> = vec2<f32>((((min(max((tmp706.x), (tmp706.y)), c_glsl_const_00.v_o) + (length(max(tmp706, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp710))) + mix((tmp765.y), (tmp765.x), step(c_glsl_const_00.v_o, tmp767))), (abs(tmp767) - (tmp769.v_height)));
	let tmp7939: f32 = length(tmp7938);
	let tmp8105: vec3<f32> = (tmp8103 - tmp8104);
	let tmp7941: f32 = (tmp7940.w);
	let tmp7950: f32 = (tmp7949.z);
	let tmp7947: f32 = (tmp7946.y);
	let tmp7944: f32 = (tmp7943.x);
	let tmp7920: vec3<f32> = (tmp7917 / tmp7919);
	let tmp7909: f32 = (tmp7907 + tmp7908);
	let tmp7906: t_glsl_const_01 = c_glsl_const_01;
	let tmp7903: f32 = (tmp7852 * tmp7855);
	let tmp8555: t_neo_elem_39_transform = u_neo_elem_39_transform;
	let tmp7902: f32 = (tmp7858 * tmp7861);
	let tmp7898: f32 = (tmp7852 * tmp7858);
	let tmp7897: f32 = (tmp7855 * tmp7861);
	let tmp7893: f32 = (tmp7852 * tmp7855);
	let tmp7892: f32 = (tmp7858 * tmp7861);
	let tmp7887: f32 = (tmp7885 + tmp7886);
	let tmp7884: t_glsl_const_01 = c_glsl_const_01;
	let tmp7881: f32 = (tmp7852 * tmp7861);
	let tmp7880: f32 = (tmp7855 * tmp7858);
	let tmp7876: f32 = (tmp7852 * tmp7858);
	let tmp7875: f32 = (tmp7855 * tmp7861);
	let tmp7871: f32 = (tmp7852 * tmp7861);
	let tmp7870: f32 = (tmp7855 * tmp7858);
	let tmp7823: mat3x3<f32> = mat3x3<f32>(tmp7778, tmp7783, tmp7788, tmp7793, tmp7800, tmp7805, tmp7810, tmp7815, tmp7822);
	let tmp7942: f32 = (tmp7941 / tmp7939);
	let tmp7975: f32 = (tmp7942 * tmp7942);
	let tmp8007: vec3<f32> = (tmp8105);
	let tmp7896: t_glsl_const_01 = c_glsl_const_01;
	let tmp7904: f32 = (tmp7902 + tmp7903);
	let tmp398: vec2<f32> = ((abs(tmp430) - (tmp431.v_dims)) + vec2<f32>(mix(mix((tmp428.w), (tmp428.y), step(c_glsl_const_00.v_o, (tmp430.x))), mix((tmp428.z), (tmp428.x), step(c_glsl_const_00.v_o, (tmp430.x))), step(c_glsl_const_00.v_o, (tmp430.y))), mix(mix((tmp428.w), (tmp428.y), step(c_glsl_const_00.v_o, (tmp430.x))), mix((tmp428.z), (tmp428.x), step(c_glsl_const_00.v_o, (tmp430.x))), step(c_glsl_const_00.v_o, (tmp430.y)))));
	let tmp8009: vec3<f32> = vec3<f32>(tmp8008, tmp8008, tmp8008);
	let tmp7945: f32 = (tmp7944 / tmp7939);
	let tmp7948: f32 = (tmp7947 / tmp7939);
	let tmp7951: f32 = (tmp7950 / tmp7939);
	let tmp7894: f32 = (tmp7892 - tmp7893);
	let tmp8193: vec3<f32> = (u_neo_elem_45_transform.v_trans);
	let tmp7563: f32 = (tmp7467);
	let tmp7564: f32 = (tmp8555.v_scale);
	let tmp8027: vec4<f32> = (u_neo_elem_46_transform.v_quat);
	let tmp7901: t_glsl_const_01 = c_glsl_const_01;
	let tmp7997: f32 = (tmp7942 * tmp7942);
	let tmp7998: f32 = (tmp7951 * tmp7951);
	let tmp7879: t_glsl_const_01 = c_glsl_const_01;
	let tmp7899: f32 = (tmp7897 - tmp7898);
	let tmp7572: f32 = (tmp7479);
	let tmp7578: f32 = max(tmp7575, tmp7577);
	let tmp353: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp8027.w) / length(tmp8027)) * ((tmp8027.w) / length(tmp8027))) + (((tmp8027.x) / length(tmp8027)) * ((tmp8027.x) / length(tmp8027))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))) - (((tmp8027.w) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) + (((tmp8027.w) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))) + (((tmp8027.w) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))))), ((c_glsl_const_01.v_o * ((((tmp8027.w) / length(tmp8027)) * ((tmp8027.w) / length(tmp8027))) + (((tmp8027.y) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8027.y) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) - (((tmp8027.w) / length(tmp8027)) * ((tmp8027.x) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) - (((tmp8027.w) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.y) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) + (((tmp8027.w) / length(tmp8027)) * ((tmp8027.x) / length(tmp8027))))), ((c_glsl_const_01.v_o * ((((tmp8027.w) / length(tmp8027)) * ((tmp8027.w) / length(tmp8027))) + (((tmp8027.z) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))))) - c_glsl_const_02.v_o)) * (((((((tmp8485))) - (u_neo_elem_46_transform.v_trans))) / vec3<f32>((u_neo_elem_46_transform.v_scale), (u_neo_elem_46_transform.v_scale), (u_neo_elem_46_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp8027.w) / length(tmp8027)) * ((tmp8027.w) / length(tmp8027))) + (((tmp8027.x) / length(tmp8027)) * ((tmp8027.x) / length(tmp8027))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))) - (((tmp8027.w) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) + (((tmp8027.w) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))) + (((tmp8027.w) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))))), ((c_glsl_const_01.v_o * ((((tmp8027.w) / length(tmp8027)) * ((tmp8027.w) / length(tmp8027))) + (((tmp8027.y) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8027.y) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) - (((tmp8027.w) / length(tmp8027)) * ((tmp8027.x) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.x) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) - (((tmp8027.w) / length(tmp8027)) * ((tmp8027.y) / length(tmp8027))))), (c_glsl_const_01.v_o * ((((tmp8027.y) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))) + (((tmp8027.w) / length(tmp8027)) * ((tmp8027.x) / length(tmp8027))))), ((c_glsl_const_01.v_o * ((((tmp8027.w) / length(tmp8027)) * ((tmp8027.w) / length(tmp8027))) + (((tmp8027.z) / length(tmp8027)) * ((tmp8027.z) / length(tmp8027))))) - c_glsl_const_02.v_o)) * (((((((tmp8485))) - (u_neo_elem_46_transform.v_trans))) / vec3<f32>((u_neo_elem_46_transform.v_scale), (u_neo_elem_46_transform.v_scale), (u_neo_elem_46_transform.v_scale))))).z));
	let tmp7954: f32 = (tmp7945 * tmp7945);
	let tmp8192: vec3<f32> = (tmp8286);
	let tmp351: vec4<f32> = (tmp354.v_radius);
	let tmp7891: t_glsl_const_01 = c_glsl_const_01;
	let tmp7953: f32 = (tmp7942 * tmp7942);
	let tmp7889: t_glsl_const_02 = c_glsl_const_02;
	let tmp7888: f32 = (tmp7884.v_o * tmp7887);
	let tmp7976: f32 = (tmp7948 * tmp7948);
	let tmp8467: vec3<f32> = (tmp8485);
	let tmp7882: f32 = (tmp7880 + tmp7881);
	let tmp7877: f32 = (tmp7875 + tmp7876);
	let tmp479: f32 = mix(mix((tmp505.w), (tmp505.y), step(c_glsl_const_00.v_o, (tmp507.x))), mix((tmp505.z), (tmp505.x), step(c_glsl_const_00.v_o, (tmp507.x))), step(c_glsl_const_00.v_o, (tmp507.y)));
	let tmp7874: t_glsl_const_01 = c_glsl_const_01;
	let tmp7872: f32 = (tmp7870 - tmp7871);
	let tmp616: vec3<f32> = tmp7735;
	let tmp7869: t_glsl_const_01 = c_glsl_const_01;
	let tmp7867: t_glsl_const_02 = c_glsl_const_02;
	let tmp7866: f32 = (tmp7862.v_o * tmp7865);
	let tmp7910: f32 = (tmp7906.v_o * tmp7909);
	let tmp7911: t_glsl_const_02 = c_glsl_const_02;
	let tmp7475: f32 = (tmp7473 * tmp7474);
	let tmp7757: vec3<f32> = (tmp7920);
	let tmp688: vec2<f32> = (tmp692.v_radius);
	let tmp8029: vec4<f32> = tmp8027;
	let tmp8032: vec4<f32> = tmp8027;
	let tmp8035: vec4<f32> = tmp8027;
	let tmp8038: vec4<f32> = tmp8027;
	let tmp7665: f32 = (tmp7578);
	let tmp7971: f32 = (tmp7942 * tmp7951);
	let tmp8010: vec3<f32> = (tmp8007 / tmp8009);
	let tmp7666: f32 = (tmp7572);
	let tmp7977: f32 = (tmp7975 + tmp7976);
	let tmp7992: f32 = (tmp7948 * tmp7951);
	let tmp7961: f32 = (tmp7942 * tmp7951);
	let tmp7883: f32 = (tmp7879.v_o * tmp7882);
	let tmp7993: f32 = (tmp7942 * tmp7945);
	let tmp7965: f32 = (tmp7945 * tmp7951);
	let tmp7960: f32 = (tmp7945 * tmp7948);
	let tmp7890: f32 = (tmp7888 - tmp7889.v_o);
	let tmp7878: f32 = (tmp7874.v_o * tmp7877);
	let tmp7557: f32 = ((min(max((tmp828.x), (tmp828.y)), c_glsl_const_00.v_o) + (length(max(tmp828, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp835)));
	let tmp7966: f32 = (tmp7942 * tmp7948);
	let tmp7824: vec3<f32> = (tmp7823 * tmp7757);
	let tmp7565: f32 = (tmp7563 * tmp7564);
	let tmp7873: f32 = (tmp7869.v_o * tmp7872);
	let tmp7996: t_glsl_const_01 = c_glsl_const_01;
	let tmp7999: f32 = (tmp7997 + tmp7998);
	let tmp674: vec2<f32> = vec2<f32>((((min(max((tmp629.x), (tmp629.y)), c_glsl_const_00.v_o) + (length(max(tmp629, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp633))) + mix((tmp688.y), (tmp688.x), step(c_glsl_const_00.v_o, (tmp616.y)))), (abs((tmp616.y)) - (tmp692.v_height)));
	let tmp7569: f32 = (tmp7475);
	let tmp7868: f32 = (tmp7866 - tmp7867.v_o);
	let tmp8194: vec3<f32> = (tmp8192 - tmp8193);
	let tmp615: t_neo_elem_43_mod = u_neo_elem_43_mod;
	let tmp8028: f32 = length(tmp8027);
	let tmp7974: t_glsl_const_01 = c_glsl_const_01;
	let tmp8097: f32 = (u_neo_elem_45_transform.v_scale);
	let tmp7912: f32 = (tmp7910 - tmp7911.v_o);
	let tmp7905: f32 = (tmp7901.v_o * tmp7904);
	let tmp8556: t_neo_elem_40_transform = u_neo_elem_40_transform;
	let tmp7982: f32 = (tmp7948 * tmp7951);
	let tmp7983: f32 = (tmp7942 * tmp7945);
	let tmp8497: vec3<f32> = (((t_position(a_pos).v_pos)));
	let tmp758: f32 = mix((tmp765.y), (tmp765.x), step(c_glsl_const_00.v_o, tmp767));
	let tmp690: f32 = (tmp616.y);
	let tmp7987: f32 = (tmp7945 * tmp7951);
	let tmp7955: f32 = (tmp7953 + tmp7954);
	let tmp8375: vec3<f32> = (tmp8467);
	let tmp8030: f32 = (tmp8029.w);
	let tmp277: t_neo_elem_47_prim = u_neo_elem_47_prim;
	let tmp7895: f32 = (tmp7891.v_o * tmp7894);
	let tmp8033: f32 = (tmp8032.x);
	let tmp7952: t_glsl_const_01 = c_glsl_const_01;
	let tmp8036: f32 = (tmp8035.y);
	let tmp7970: f32 = (tmp7945 * tmp7948);
	let tmp7988: f32 = (tmp7942 * tmp7948);
	let tmp7900: f32 = (tmp7896.v_o * tmp7899);
	let tmp8039: f32 = (tmp8038.z);
	let tmp7989: f32 = (tmp7987 - tmp7988);
	let tmp8031: f32 = (tmp8030 / tmp8028);
	let tmp7653: f32 = (tmp7557);
	let tmp7959: t_glsl_const_01 = c_glsl_const_01;
	let tmp611: vec2<f32> = (tmp615.v_radius);
	let tmp7972: f32 = (tmp7970 + tmp7971);
	let tmp7991: t_glsl_const_01 = c_glsl_const_01;
	let tmp7913: mat3x3<f32> = mat3x3<f32>(tmp7868, tmp7873, tmp7878, tmp7883, tmp7890, tmp7895, tmp7900, tmp7905, tmp7912);
	let tmp539: vec3<f32> = tmp7824;
	let tmp7994: f32 = (tmp7992 + tmp7993);
	let tmp8034: f32 = (tmp8033 / tmp8028);
	let tmp8037: f32 = (tmp8036 / tmp8028);
	let tmp8040: f32 = (tmp8039 / tmp8028);
	let tmp402: f32 = mix(mix((tmp428.w), (tmp428.y), step(c_glsl_const_00.v_o, (tmp430.x))), mix((tmp428.z), (tmp428.x), step(c_glsl_const_00.v_o, (tmp430.x))), step(c_glsl_const_00.v_o, (tmp430.y)));
	let tmp321: vec2<f32> = ((abs(tmp353) - (tmp354.v_dims)) + vec2<f32>(mix(mix((tmp351.w), (tmp351.y), step(c_glsl_const_00.v_o, (tmp353.x))), mix((tmp351.z), (tmp351.x), step(c_glsl_const_00.v_o, (tmp353.x))), step(c_glsl_const_00.v_o, (tmp353.y))), mix(mix((tmp351.w), (tmp351.y), step(c_glsl_const_00.v_o, (tmp353.x))), mix((tmp351.z), (tmp351.x), step(c_glsl_const_00.v_o, (tmp353.x))), step(c_glsl_const_00.v_o, (tmp353.y)))));
	let tmp8000: f32 = (tmp7996.v_o * tmp7999);
	let tmp8001: t_glsl_const_02 = c_glsl_const_02;
	let tmp8486: vec3<f32> = (tmp8497);
	let tmp274: vec4<f32> = (tmp277.v_radius);
	let tmp276: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))) - ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) - ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) - ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((tmp8486)) - (u_neo_elem_47_transform.v_trans))) / vec3<f32>((u_neo_elem_47_transform.v_scale), (u_neo_elem_47_transform.v_scale), (u_neo_elem_47_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))) - ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) - ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) - ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).y) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).x) / length((u_neo_elem_47_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).w) / length((u_neo_elem_47_transform.v_quat)))) + ((((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat))) * (((u_neo_elem_47_transform.v_quat).z) / length((u_neo_elem_47_transform.v_quat)))))) - c_glsl_const_02.v_o)) * ((((((tmp8486)) - (u_neo_elem_47_transform.v_trans))) / vec3<f32>((u_neo_elem_47_transform.v_scale), (u_neo_elem_47_transform.v_scale), (u_neo_elem_47_transform.v_scale))))).z));
	let tmp7969: t_glsl_const_01 = c_glsl_const_01;
	let tmp8042: f32 = (tmp8031 * tmp8031);
	let tmp8043: f32 = (tmp8034 * tmp8034);
	let tmp8282: vec3<f32> = (u_neo_elem_46_transform.v_trans);
	let tmp8281: vec3<f32> = (tmp8375);
	let tmp7957: t_glsl_const_02 = c_glsl_const_02;
	let tmp7956: f32 = (tmp7952.v_o * tmp7955);
	let tmp7962: f32 = (tmp7960 - tmp7961);
	let tmp7964: t_glsl_const_01 = c_glsl_const_01;
	let tmp7659: f32 = (tmp7565);
	let tmp7967: f32 = (tmp7965 + tmp7966);
	let tmp8116: vec4<f32> = (u_neo_elem_47_transform.v_quat);
	let tmp8064: f32 = (tmp8031 * tmp8031);
	let tmp7981: t_glsl_const_01 = c_glsl_const_01;
	let tmp8065: f32 = (tmp8037 * tmp8037);
	let tmp7978: f32 = (tmp7974.v_o * tmp7977);
	let tmp7979: t_glsl_const_02 = c_glsl_const_02;
	let tmp8086: f32 = (tmp8031 * tmp8031);
	let tmp8087: f32 = (tmp8040 * tmp8040);
	let tmp7984: f32 = (tmp7982 - tmp7983);
	let tmp8096: vec3<f32> = (tmp8194);
	let tmp7986: t_glsl_const_01 = c_glsl_const_01;
	let tmp7847: vec3<f32> = (tmp8010);
	let tmp8098: vec3<f32> = vec3<f32>(tmp8097, tmp8097, tmp8097);
	let tmp8118: vec4<f32> = tmp8116;
	let tmp8121: vec4<f32> = tmp8116;
	let tmp8124: vec4<f32> = tmp8116;
	let tmp8127: vec4<f32> = tmp8116;
	let tmp7667: f32 = min(tmp7665, tmp7666);
	let tmp7662: f32 = (tmp7569);
	let tmp7654: f32 = (tmp8556.v_scale);
	let tmp7995: f32 = (tmp7991.v_o * tmp7994);
	let tmp8071: f32 = (tmp8037 * tmp8040);
	let tmp7655: f32 = (tmp7653 * tmp7654);
	let tmp8054: f32 = (tmp8034 * tmp8040);
	let tmp8283: vec3<f32> = (tmp8281 - tmp8282);
	let tmp8504: vec3<f32> = ((t_position(a_pos).v_pos));
	let tmp7755: f32 = (tmp7662);
	let tmp8072: f32 = (tmp8031 * tmp8034);
	let tmp8055: f32 = (tmp8031 * tmp8037);
	let tmp597: vec2<f32> = vec2<f32>((((min(max((tmp552.x), (tmp552.y)), c_glsl_const_00.v_o) + (length(max(tmp552, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp556))) + mix((tmp611.y), (tmp611.x), step(c_glsl_const_00.v_o, (tmp539.y)))), (abs((tmp539.y)) - (tmp615.v_height)));
	let tmp8186: f32 = (u_neo_elem_46_transform.v_scale);
	let tmp8088: f32 = (tmp8086 + tmp8087);
	let tmp8076: f32 = (tmp8034 * tmp8040);
	let tmp8119: f32 = (tmp8118.w);
	let tmp8122: f32 = (tmp8121.x);
	let tmp7980: f32 = (tmp7978 - tmp7979.v_o);
	let tmp7985: f32 = (tmp7981.v_o * tmp7984);
	let tmp8077: f32 = (tmp8031 * tmp8037);
	let tmp7914: vec3<f32> = (tmp7913 * tmp7847);
	let tmp8099: vec3<f32> = (tmp8096 / tmp8098);
	let tmp8050: f32 = (tmp8031 * tmp8040);
	let tmp8063: t_glsl_const_01 = c_glsl_const_01;
	let tmp8049: f32 = (tmp8034 * tmp8037);
	let tmp8044: f32 = (tmp8042 + tmp8043);
	let tmp538: t_neo_elem_44_mod = u_neo_elem_44_mod;
	let tmp7958: f32 = (tmp7956 - tmp7957.v_o);
	let tmp8060: f32 = (tmp8031 * tmp8040);
	let tmp8117: f32 = length(tmp8116);
	let tmp8081: f32 = (tmp8037 * tmp8040);
	let tmp7990: f32 = (tmp7986.v_o * tmp7989);
	let tmp8059: f32 = (tmp8034 * tmp8037);
	let tmp8082: f32 = (tmp8031 * tmp8034);
	let tmp8125: f32 = (tmp8124.y);
	let tmp200: t_neo_elem_48_prim = u_neo_elem_48_prim;
	let tmp7751: f32 = (tmp7659);
	let tmp613: f32 = (tmp539.y);
	let tmp8041: t_glsl_const_01 = c_glsl_const_01;
	let tmp8128: f32 = (tmp8127.z);
	let tmp8002: f32 = (tmp8000 - tmp8001.v_o);
	let tmp7963: f32 = (tmp7959.v_o * tmp7962);
	let tmp681: f32 = mix((tmp688.y), (tmp688.x), step(c_glsl_const_00.v_o, tmp690));
	let tmp8066: f32 = (tmp8064 + tmp8065);
	let tmp7968: f32 = (tmp7964.v_o * tmp7967);
	let tmp8085: t_glsl_const_01 = c_glsl_const_01;
	let tmp7973: f32 = (tmp7969.v_o * tmp7972);
	let tmp8464: vec3<f32> = (tmp8486);
	let tmp7754: f32 = (tmp7667);
	let tmp8120: f32 = (tmp8119 / tmp8117);
	let tmp8153: f32 = (tmp8120 * tmp8120);
	let tmp7937: vec3<f32> = (tmp8099);
	let tmp7748: f32 = (tmp7655);
	let tmp8123: f32 = (tmp8122 / tmp8117);
	let tmp8126: f32 = (tmp8125 / tmp8117);
	let tmp8129: f32 = (tmp8128 / tmp8117);
	let tmp8056: f32 = (tmp8054 + tmp8055);
	let tmp197: vec4<f32> = (tmp200.v_radius);
	let tmp7844: f32 = (tmp7751);
	let tmp8557: t_neo_elem_41_transform = u_neo_elem_41_transform;
	let tmp8205: vec4<f32> = (u_neo_elem_48_transform.v_quat);
	let tmp8132: f32 = (tmp8123 * tmp8123);
	let tmp8003: mat3x3<f32> = mat3x3<f32>(tmp7958, tmp7963, tmp7968, tmp7973, tmp7980, tmp7985, tmp7990, tmp7995, tmp8002);
	let tmp7647: f32 = ((min(max((tmp751.x), (tmp751.y)), c_glsl_const_00.v_o) + (length(max(tmp751, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp758)));
	let tmp8067: f32 = (tmp8063.v_o * tmp8066);
	let tmp8068: t_glsl_const_02 = c_glsl_const_02;
	let tmp8070: t_glsl_const_01 = c_glsl_const_01;
	let tmp8073: f32 = (tmp8071 - tmp8072);
	let tmp8075: t_glsl_const_01 = c_glsl_const_01;
	let tmp8078: f32 = (tmp8076 - tmp8077);
	let tmp8080: t_glsl_const_01 = c_glsl_const_01;
	let tmp8083: f32 = (tmp8081 + tmp8082);
	let tmp8089: f32 = (tmp8085.v_o * tmp8088);
	let tmp8090: t_glsl_const_02 = c_glsl_const_02;
	let tmp7756: f32 = min(tmp7754, tmp7755);
	let tmp8131: f32 = (tmp8120 * tmp8120);
	let tmp244: vec2<f32> = ((abs(tmp276) - (tmp277.v_dims)) + vec2<f32>(mix(mix((tmp274.w), (tmp274.y), step(c_glsl_const_00.v_o, (tmp276.x))), mix((tmp274.z), (tmp274.x), step(c_glsl_const_00.v_o, (tmp276.x))), step(c_glsl_const_00.v_o, (tmp276.y))), mix(mix((tmp274.w), (tmp274.y), step(c_glsl_const_00.v_o, (tmp276.x))), mix((tmp274.z), (tmp274.x), step(c_glsl_const_00.v_o, (tmp276.x))), step(c_glsl_const_00.v_o, (tmp276.y)))));
	let tmp325: f32 = mix(mix((tmp351.w), (tmp351.y), step(c_glsl_const_00.v_o, (tmp353.x))), mix((tmp351.z), (tmp351.x), step(c_glsl_const_00.v_o, (tmp353.x))), step(c_glsl_const_00.v_o, (tmp353.y)));
	let tmp8061: f32 = (tmp8059 + tmp8060);
	let tmp462: vec3<f32> = tmp7914;
	let tmp199: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp8205.w) / length(tmp8205)) * ((tmp8205.w) / length(tmp8205))) + (((tmp8205.x) / length(tmp8205)) * ((tmp8205.x) / length(tmp8205))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))) - (((tmp8205.w) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) + (((tmp8205.w) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))) + (((tmp8205.w) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))))), ((c_glsl_const_01.v_o * ((((tmp8205.w) / length(tmp8205)) * ((tmp8205.w) / length(tmp8205))) + (((tmp8205.y) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8205.y) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) - (((tmp8205.w) / length(tmp8205)) * ((tmp8205.x) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) - (((tmp8205.w) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.y) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) + (((tmp8205.w) / length(tmp8205)) * ((tmp8205.x) / length(tmp8205))))), ((c_glsl_const_01.v_o * ((((tmp8205.w) / length(tmp8205)) * ((tmp8205.w) / length(tmp8205))) + (((tmp8205.z) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))))) - c_glsl_const_02.v_o)) * (((((((tmp8504))) - (u_neo_elem_48_transform.v_trans))) / vec3<f32>((u_neo_elem_48_transform.v_scale), (u_neo_elem_48_transform.v_scale), (u_neo_elem_48_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp8205.w) / length(tmp8205)) * ((tmp8205.w) / length(tmp8205))) + (((tmp8205.x) / length(tmp8205)) * ((tmp8205.x) / length(tmp8205))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))) - (((tmp8205.w) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) + (((tmp8205.w) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))) + (((tmp8205.w) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))))), ((c_glsl_const_01.v_o * ((((tmp8205.w) / length(tmp8205)) * ((tmp8205.w) / length(tmp8205))) + (((tmp8205.y) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * ((((tmp8205.y) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) - (((tmp8205.w) / length(tmp8205)) * ((tmp8205.x) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.x) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) - (((tmp8205.w) / length(tmp8205)) * ((tmp8205.y) / length(tmp8205))))), (c_glsl_const_01.v_o * ((((tmp8205.y) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))) + (((tmp8205.w) / length(tmp8205)) * ((tmp8205.x) / length(tmp8205))))), ((c_glsl_const_01.v_o * ((((tmp8205.w) / length(tmp8205)) * ((tmp8205.w) / length(tmp8205))) + (((tmp8205.z) / length(tmp8205)) * ((tmp8205.z) / length(tmp8205))))) - c_glsl_const_02.v_o)) * (((((((tmp8504))) - (u_neo_elem_48_transform.v_trans))) / vec3<f32>((u_neo_elem_48_transform.v_scale), (u_neo_elem_48_transform.v_scale), (u_neo_elem_48_transform.v_scale))))).z));
	let tmp8371: vec3<f32> = (u_neo_elem_47_transform.v_trans);
	let tmp8370: vec3<f32> = (tmp8464);
	let tmp8498: vec3<f32> = (tmp8504);
	let tmp8216: vec4<f32> = tmp8205;
	let tmp8213: vec4<f32> = tmp8205;
	let tmp8210: vec4<f32> = tmp8205;
	let tmp534: vec2<f32> = (tmp538.v_radius);
	let tmp8207: vec4<f32> = tmp8205;
	let tmp8045: f32 = (tmp8041.v_o * tmp8044);
	let tmp8046: t_glsl_const_02 = c_glsl_const_02;
	let tmp8048: t_glsl_const_01 = c_glsl_const_01;
	let tmp8058: t_glsl_const_01 = c_glsl_const_01;
	let tmp8051: f32 = (tmp8049 - tmp8050);
	let tmp8053: t_glsl_const_01 = c_glsl_const_01;
	let tmp8187: vec3<f32> = vec3<f32>(tmp8186, tmp8186, tmp8186);
	let tmp8185: vec3<f32> = (tmp8283);
	let tmp8176: f32 = (tmp8129 * tmp8129);
	let tmp8175: f32 = (tmp8120 * tmp8120);
	let tmp8154: f32 = (tmp8126 * tmp8126);
	let tmp8144: f32 = (tmp8120 * tmp8126);
	let tmp7743: f32 = (tmp8557.v_scale);
	let tmp8004: vec3<f32> = (tmp8003 * tmp7937);
	let tmp8214: f32 = (tmp8213.y);
	let tmp8483: vec3<f32> = (tmp8498);
	let tmp604: f32 = mix((tmp611.y), (tmp611.x), step(c_glsl_const_00.v_o, tmp613));
	let tmp520: vec2<f32> = vec2<f32>((((min(max((tmp475.x), (tmp475.y)), c_glsl_const_00.v_o) + (length(max(tmp475, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp479))) + mix((tmp534.y), (tmp534.x), step(c_glsl_const_00.v_o, (tmp462.y)))), (abs((tmp462.y)) - (tmp538.v_height)));
	let tmp8211: f32 = (tmp8210.x);
	let tmp8372: vec3<f32> = (tmp8370 - tmp8371);
	let tmp7845: f32 = opp(tmp7844);
	let tmp536: f32 = (tmp462.y);
	let tmp8138: f32 = (tmp8123 * tmp8126);
	let tmp8208: f32 = (tmp8207.w);
	let tmp8084: f32 = (tmp8080.v_o * tmp8083);
	let tmp461: t_neo_elem_45_mod = u_neo_elem_45_mod;
	let tmp123: t_neo_elem_49_prim = u_neo_elem_49_prim;
	let tmp8148: f32 = (tmp8123 * tmp8126);
	let tmp8079: f32 = (tmp8075.v_o * tmp8078);
	let tmp8074: f32 = (tmp8070.v_o * tmp8073);
	let tmp8047: f32 = (tmp8045 - tmp8046.v_o);
	let tmp8509: vec3<f32> = (t_position(a_pos).v_pos);
	let tmp7840: f32 = (tmp7748);
	let tmp8206: f32 = length(tmp8205);
	let tmp7843: f32 = (tmp7756);
	let tmp8275: f32 = (u_neo_elem_47_transform.v_scale);
	let tmp8052: f32 = (tmp8048.v_o * tmp8051);
	let tmp8069: f32 = (tmp8067 - tmp8068.v_o);
	let tmp8188: vec3<f32> = (tmp8185 / tmp8187);
	let tmp8062: f32 = (tmp8058.v_o * tmp8061);
	let tmp8057: f32 = (tmp8053.v_o * tmp8056);
	let tmp8177: f32 = (tmp8175 + tmp8176);
	let tmp8217: f32 = (tmp8216.z);
	let tmp8091: f32 = (tmp8089 - tmp8090.v_o);
	let tmp8174: t_glsl_const_01 = c_glsl_const_01;
	let tmp8171: f32 = (tmp8120 * tmp8123);
	let tmp8170: f32 = (tmp8126 * tmp8129);
	let tmp8166: f32 = (tmp8120 * tmp8126);
	let tmp8165: f32 = (tmp8123 * tmp8129);
	let tmp8161: f32 = (tmp8120 * tmp8123);
	let tmp8160: f32 = (tmp8126 * tmp8129);
	let tmp8155: f32 = (tmp8153 + tmp8154);
	let tmp8130: t_glsl_const_01 = c_glsl_const_01;
	let tmp8139: f32 = (tmp8120 * tmp8129);
	let tmp7742: f32 = (tmp7647);
	let tmp8143: f32 = (tmp8123 * tmp8129);
	let tmp8133: f32 = (tmp8131 + tmp8132);
	let tmp8152: t_glsl_const_01 = c_glsl_const_01;
	let tmp8149: f32 = (tmp8120 * tmp8129);
	let tmp7934: f32 = (tmp7840);
	let tmp248: f32 = mix(mix((tmp274.w), (tmp274.y), step(c_glsl_const_00.v_o, (tmp276.x))), mix((tmp274.z), (tmp274.x), step(c_glsl_const_00.v_o, (tmp276.x))), step(c_glsl_const_00.v_o, (tmp276.y)));
	let tmp8460: vec3<f32> = (u_neo_elem_48_transform.v_trans);
	let tmp8242: f32 = ((tmp8208 / tmp8206) * (tmp8208 / tmp8206));
	let tmp8459: vec3<f32> = (tmp8483);
	let tmp8092: mat3x3<f32> = mat3x3<f32>(tmp8047, tmp8052, tmp8057, tmp8062, tmp8069, tmp8074, tmp8079, tmp8084, tmp8091);
	let tmp8137: t_glsl_const_01 = c_glsl_const_01;
	let tmp8221: f32 = ((tmp8211 / tmp8206) * (tmp8211 / tmp8206));
	let tmp8220: f32 = ((tmp8208 / tmp8206) * (tmp8208 / tmp8206));
	let tmp7744: f32 = (tmp7742 * tmp7743);
	let tmp8264: f32 = ((tmp8208 / tmp8206) * (tmp8208 / tmp8206));
	let tmp8135: t_glsl_const_02 = c_glsl_const_02;
	let tmp122: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))) - ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) - ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) - ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp8509))) - (u_neo_elem_49_transform.v_trans))) / vec3<f32>((u_neo_elem_49_transform.v_scale), (u_neo_elem_49_transform.v_scale), (u_neo_elem_49_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))) - ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) - ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) - ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).y) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).x) / length((u_neo_elem_49_transform.v_quat)))))), ((c_glsl_const_01.v_o * (((((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).w) / length((u_neo_elem_49_transform.v_quat)))) + ((((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat))) * (((u_neo_elem_49_transform.v_quat).z) / length((u_neo_elem_49_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp8509))) - (u_neo_elem_49_transform.v_trans))) / vec3<f32>((u_neo_elem_49_transform.v_scale), (u_neo_elem_49_transform.v_scale), (u_neo_elem_49_transform.v_scale))))).z));
	let tmp8243: f32 = ((tmp8214 / tmp8206) * (tmp8214 / tmp8206));
	let tmp8276: vec3<f32> = vec3<f32>(tmp8275, tmp8275, tmp8275);
	let tmp7736: f32 = ((min(max((tmp674.x), (tmp674.y)), c_glsl_const_00.v_o) + (length(max(tmp674, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp681)));
	let tmp8179: t_glsl_const_02 = c_glsl_const_02;
	let tmp8178: f32 = (tmp8174.v_o * tmp8177);
	let tmp8274: vec3<f32> = (tmp8372);
	let tmp8265: f32 = ((tmp8217 / tmp8206) * (tmp8217 / tmp8206));
	let tmp8026: vec3<f32> = (tmp8188);
	let tmp8558: t_neo_elem_42_transform = u_neo_elem_42_transform;
	let tmp8172: f32 = (tmp8170 + tmp8171);
	let tmp120: vec4<f32> = (tmp123.v_radius);
	let tmp167: vec2<f32> = ((abs(tmp199) - (tmp200.v_dims)) + vec2<f32>(mix(mix((tmp197.w), (tmp197.y), step(c_glsl_const_00.v_o, (tmp199.x))), mix((tmp197.z), (tmp197.x), step(c_glsl_const_00.v_o, (tmp199.x))), step(c_glsl_const_00.v_o, (tmp199.y))), mix(mix((tmp197.w), (tmp197.y), step(c_glsl_const_00.v_o, (tmp199.x))), mix((tmp197.z), (tmp197.x), step(c_glsl_const_00.v_o, (tmp199.x))), step(c_glsl_const_00.v_o, (tmp199.y)))));
	let tmp8169: t_glsl_const_01 = c_glsl_const_01;
	let tmp457: vec2<f32> = (tmp461.v_radius);
	let tmp8147: t_glsl_const_01 = c_glsl_const_01;
	let tmp8209: f32 = (tmp8208 / tmp8206);
	let tmp8164: t_glsl_const_01 = c_glsl_const_01;
	let tmp8162: f32 = (tmp8160 - tmp8161);
	let tmp8145: f32 = (tmp8143 + tmp8144);
	let tmp8218: f32 = (tmp8217 / tmp8206);
	let tmp8159: t_glsl_const_01 = c_glsl_const_01;
	let tmp8157: t_glsl_const_02 = c_glsl_const_02;
	let tmp8156: f32 = (tmp8152.v_o * tmp8155);
	let tmp385: vec3<f32> = tmp8004;
	let tmp8215: f32 = (tmp8214 / tmp8206);
	let tmp8505: vec3<f32> = (tmp8509);
	let tmp8134: f32 = (tmp8130.v_o * tmp8133);
	let tmp8305: vec4<f32> = (u_neo_elem_49_transform.v_quat);
	let tmp8212: f32 = (tmp8211 / tmp8206);
	let tmp8302: vec4<f32> = (u_neo_elem_49_transform.v_quat);
	let tmp7846: f32 = max(tmp7843, tmp7845);
	let tmp8299: vec4<f32> = (u_neo_elem_49_transform.v_quat);
	let tmp8142: t_glsl_const_01 = c_glsl_const_01;
	let tmp8296: vec4<f32> = (u_neo_elem_49_transform.v_quat);
	let tmp8294: vec4<f32> = (u_neo_elem_49_transform.v_quat);
	let tmp8150: f32 = (tmp8148 + tmp8149);
	let tmp8140: f32 = (tmp8138 - tmp8139);
	let tmp8167: f32 = (tmp8165 - tmp8166);
	let tmp8259: f32 = (tmp8215 * tmp8218);
	let tmp8227: f32 = (tmp8212 * tmp8215);
	let tmp8228: f32 = (tmp8209 * tmp8218);
	let tmp8232: f32 = (tmp8212 * tmp8218);
	let tmp8233: f32 = (tmp8209 * tmp8215);
	let tmp8237: f32 = (tmp8212 * tmp8215);
	let tmp8238: f32 = (tmp8209 * tmp8218);
	let tmp8515: t_position = t_position(a_pos);
	let tmp8364: f32 = (u_neo_elem_48_transform.v_scale);
	let tmp8241: t_glsl_const_01 = c_glsl_const_01;
	let tmp8244: f32 = (tmp8242 + tmp8243);
	let tmp8249: f32 = (tmp8215 * tmp8218);
	let tmp8250: f32 = (tmp8209 * tmp8212);
	let tmp8254: f32 = (tmp8212 * tmp8218);
	let tmp443: vec2<f32> = vec2<f32>((((min(max((tmp398.x), (tmp398.y)), c_glsl_const_00.v_o) + (length(max(tmp398, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp402))) + mix((tmp457.y), (tmp457.x), step(c_glsl_const_00.v_o, (tmp385.y)))), (abs((tmp385.y)) - (tmp461.v_height)));
	let tmp8260: f32 = (tmp8209 * tmp8212);
	let tmp8263: t_glsl_const_01 = c_glsl_const_01;
	let tmp8266: f32 = (tmp8264 + tmp8265);
	let tmp8277: vec3<f32> = (tmp8274 / tmp8276);
	let tmp8295: f32 = length(tmp8294);
	let tmp8255: f32 = (tmp8209 * tmp8215);
	let tmp8306: f32 = (tmp8305.z);
	let tmp8303: f32 = (tmp8302.y);
	let tmp8300: f32 = (tmp8299.x);
	let tmp8297: f32 = (tmp8296.w);
	let tmp7935: f32 = opp(tmp7934);
	let tmp7837: f32 = (tmp7744);
	let tmp7832: f32 = (tmp8558.v_scale);
	let tmp7831: f32 = (tmp7736);
	let tmp7933: f32 = (tmp7846);
	let tmp8093: vec3<f32> = (tmp8092 * tmp8026);
	let tmp8495: vec3<f32> = (tmp8505);
	let tmp8136: f32 = (tmp8134 - tmp8135.v_o);
	let tmp8461: vec3<f32> = (tmp8459 - tmp8460);
	let tmp8141: f32 = (tmp8137.v_o * tmp8140);
	let tmp8146: f32 = (tmp8142.v_o * tmp8145);
	let tmp8151: f32 = (tmp8147.v_o * tmp8150);
	let tmp8158: f32 = (tmp8156 - tmp8157.v_o);
	let tmp8163: f32 = (tmp8159.v_o * tmp8162);
	let tmp8168: f32 = (tmp8164.v_o * tmp8167);
	let tmp8173: f32 = (tmp8169.v_o * tmp8172);
	let tmp8180: f32 = (tmp8178 - tmp8179.v_o);
	let tmp046: t_neo_elem_50_prim = u_neo_elem_50_prim;
	let tmp384: t_neo_elem_46_mod = u_neo_elem_46_mod;
	let tmp459: f32 = (tmp385.y);
	let tmp527: f32 = mix((tmp534.y), (tmp534.x), step(c_glsl_const_00.v_o, tmp536));
	let tmp8219: t_glsl_const_01 = c_glsl_const_01;
	let tmp8222: f32 = (tmp8220 + tmp8221);
	let tmp8261: f32 = (tmp8259 + tmp8260);
	let tmp8307: f32 = (tmp8306 / tmp8295);
	let tmp8304: f32 = (tmp8303 / tmp8295);
	let tmp8301: f32 = (tmp8300 / tmp8295);
	let tmp8332: f32 = (tmp8304 * tmp8304);
	let tmp090: vec2<f32> = ((abs(tmp122) - (tmp123.v_dims)) + vec2<f32>(mix(mix((tmp120.w), (tmp120.y), step(c_glsl_const_00.v_o, (tmp122.x))), mix((tmp120.z), (tmp120.x), step(c_glsl_const_00.v_o, (tmp122.x))), step(c_glsl_const_00.v_o, (tmp122.y))), mix(mix((tmp120.w), (tmp120.y), step(c_glsl_const_00.v_o, (tmp122.x))), mix((tmp120.z), (tmp120.x), step(c_glsl_const_00.v_o, (tmp122.x))), step(c_glsl_const_00.v_o, (tmp122.y)))));
	let tmp8245: f32 = (tmp8241.v_o * tmp8244);
	let tmp7936: f32 = max(tmp7933, tmp7935);
	let tmp171: f32 = mix(mix((tmp197.w), (tmp197.y), step(c_glsl_const_00.v_o, (tmp199.x))), mix((tmp197.z), (tmp197.x), step(c_glsl_const_00.v_o, (tmp199.x))), step(c_glsl_const_00.v_o, (tmp199.y)));
	let tmp308: vec3<f32> = tmp8093;
	let tmp7930: f32 = (tmp7837);
	let tmp8385: vec4<f32> = (u_neo_elem_50_transform.v_quat);
	let tmp045: vec2<f32> = (vec2<f32>((mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * ((tmp8385.w) / length((u_neo_elem_50_transform.v_quat)))) + ((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))) - (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) + (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))) + (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * ((tmp8385.w) / length((u_neo_elem_50_transform.v_quat)))) + ((((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) - (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) - (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) + (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * ((tmp8385.w) / length((u_neo_elem_50_transform.v_quat)))) + ((((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp8515.v_pos))) - (u_neo_elem_50_transform.v_trans))) / vec3<f32>((u_neo_elem_50_transform.v_scale), (u_neo_elem_50_transform.v_scale), (u_neo_elem_50_transform.v_scale))))).x, (mat3x3<f32>(((c_glsl_const_01.v_o * ((((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * ((tmp8385.w) / length((u_neo_elem_50_transform.v_quat)))) + ((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))) - (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) + (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))) + (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * ((tmp8385.w) / length((u_neo_elem_50_transform.v_quat)))) + ((((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))))) - c_glsl_const_02.v_o), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) - (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) - (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat)))))), (c_glsl_const_01.v_o * (((((u_neo_elem_50_transform.v_quat).y) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))) + (((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).x) / length((u_neo_elem_50_transform.v_quat)))))), ((c_glsl_const_01.v_o * ((((tmp8385.w) / length((u_neo_elem_50_transform.v_quat))) * ((tmp8385.w) / length((u_neo_elem_50_transform.v_quat)))) + ((((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat))) * (((u_neo_elem_50_transform.v_quat).z) / length((u_neo_elem_50_transform.v_quat)))))) - c_glsl_const_02.v_o)) * (((((((tmp8515.v_pos))) - (u_neo_elem_50_transform.v_trans))) / vec3<f32>((u_neo_elem_50_transform.v_scale), (u_neo_elem_50_transform.v_scale), (u_neo_elem_50_transform.v_scale))))).z));
	let tmp8258: t_glsl_const_01 = c_glsl_const_01;
	let tmp8559: t_neo_elem_43_transform = u_neo_elem_43_transform;
	let tmp8383: vec4<f32> = (u_neo_elem_50_transform.v_quat);
	let tmp8394: vec4<f32> = tmp8383;
	let tmp8256: f32 = (tmp8254 - tmp8255);
	let tmp8363: vec3<f32> = (tmp8461);
	let tmp8479: vec3<f32> = (u_neo_elem_49_transform.v_trans);
	let tmp8478: vec3<f32> = (tmp8495);
	let tmp7833: f32 = (tmp7831 * tmp7832);
	let tmp8309: f32 = ((tmp8297 / tmp8295) * (tmp8297 / tmp8295));
	let tmp8239: f32 = (tmp8237 + tmp8238);
	let tmp8310: f32 = (tmp8301 * tmp8301);
	let tmp7825: f32 = ((min(max((tmp597.x), (tmp597.y)), c_glsl_const_00.v_o) + (length(max(tmp597, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp604)));
	let tmp8365: vec3<f32> = vec3<f32>(tmp8364, tmp8364, tmp8364);
	let tmp8510: vec3<f32> = (tmp8515.v_pos);
	let tmp8236: t_glsl_const_01 = c_glsl_const_01;
	let tmp8115: vec3<f32> = (tmp8277);
	let tmp8253: t_glsl_const_01 = c_glsl_const_01;
	let tmp8224: t_glsl_const_02 = c_glsl_const_02;
	let tmp8391: vec4<f32> = tmp8383;
	let tmp8223: f32 = (tmp8219.v_o * tmp8222);
	let tmp380: vec2<f32> = (tmp384.v_radius);
	let tmp8251: f32 = (tmp8249 - tmp8250);
	let tmp8234: f32 = (tmp8232 + tmp8233);
	let tmp8231: t_glsl_const_01 = c_glsl_const_01;
	let tmp8353: f32 = ((tmp8297 / tmp8295) * (tmp8297 / tmp8295));
	let tmp8298: f32 = (tmp8297 / tmp8295);
	let tmp8388: vec4<f32> = tmp8383;
	let tmp8248: t_glsl_const_01 = c_glsl_const_01;
	let tmp8181: mat3x3<f32> = mat3x3<f32>(tmp8136, tmp8141, tmp8146, tmp8151, tmp8158, tmp8163, tmp8168, tmp8173, tmp8180);
	let tmp8354: f32 = (tmp8307 * tmp8307);
	let tmp8246: t_glsl_const_02 = c_glsl_const_02;
	let tmp8229: f32 = (tmp8227 - tmp8228);
	let tmp8226: t_glsl_const_01 = c_glsl_const_01;
	let tmp043: vec4<f32> = (tmp046.v_radius);
	let tmp8331: f32 = (tmp8298 * tmp8298);
	let tmp8268: t_glsl_const_02 = c_glsl_const_02;
	let tmp8267: f32 = (tmp8263.v_o * tmp8266);
	let tmp8317: f32 = (tmp8298 * tmp8307);
	let tmp8386: f32 = (tmp8385.w);
	let tmp8333: f32 = (tmp8331 + tmp8332);
	let tmp8349: f32 = (tmp8298 * tmp8301);
	let tmp8502: vec3<f32> = (tmp8510);
	let tmp8240: f32 = (tmp8236.v_o * tmp8239);
	let tmp8023: f32 = (tmp7936);
	let tmp8366: vec3<f32> = (tmp8363 / tmp8365);
	let tmp8480: vec3<f32> = (tmp8478 - tmp8479);
	let tmp8024: f32 = (tmp7930);
	let tmp307: t_neo_elem_47_mod = u_neo_elem_47_mod;
	let tmp7922: f32 = (tmp8559.v_scale);
	let tmp7921: f32 = (tmp7825);
	let tmp8338: f32 = (tmp8304 * tmp8307);
	let tmp8339: f32 = (tmp8298 * tmp8301);
	let tmp8235: f32 = (tmp8231.v_o * tmp8234);
	let tmp8352: t_glsl_const_01 = c_glsl_const_01;
	let tmp382: f32 = (tmp308.y);
	let tmp8343: f32 = (tmp8301 * tmp8307);
	let tmp8230: f32 = (tmp8226.v_o * tmp8229);
	let tmp450: f32 = mix((tmp457.y), (tmp457.x), step(c_glsl_const_00.v_o, tmp459));
	let tmp8344: f32 = (tmp8298 * tmp8304);
	let tmp8384: f32 = length(tmp8383);
	let tmp8316: f32 = (tmp8301 * tmp8304);
	let tmp8257: f32 = (tmp8253.v_o * tmp8256);
	let tmp8252: f32 = (tmp8248.v_o * tmp8251);
	let tmp8395: f32 = (tmp8394.z);
	let tmp8311: f32 = (tmp8309 + tmp8310);
	let tmp8355: f32 = (tmp8353 + tmp8354);
	let tmp8308: t_glsl_const_01 = c_glsl_const_01;
	let tmp8321: f32 = (tmp8301 * tmp8307);
	let tmp8322: f32 = (tmp8298 * tmp8304);
	let tmp366: vec2<f32> = vec2<f32>((((min(max((tmp321.x), (tmp321.y)), c_glsl_const_00.v_o) + (length(max(tmp321, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp325))) + mix((tmp380.y), (tmp380.x), step(c_glsl_const_00.v_o, tmp382))), (abs(tmp382) - (tmp384.v_height)));
	let tmp8453: f32 = (u_neo_elem_49_transform.v_scale);
	let tmp8269: f32 = (tmp8267 - tmp8268.v_o);
	let tmp8348: f32 = (tmp8304 * tmp8307);
	let tmp8326: f32 = (tmp8301 * tmp8304);
	let tmp8327: f32 = (tmp8298 * tmp8307);
	let tmp7927: f32 = (tmp7833);
	let tmp8225: f32 = (tmp8223 - tmp8224.v_o);
	let tmp8330: t_glsl_const_01 = c_glsl_const_01;
	let tmp8247: f32 = (tmp8245 - tmp8246.v_o);
	let tmp8392: f32 = (tmp8391.y);
	let tmp8182: vec3<f32> = (tmp8181 * tmp8115);
	let tmp8262: f32 = (tmp8258.v_o * tmp8261);
	let tmp8389: f32 = (tmp8388.x);
	let tmp8396: f32 = (tmp8395 / tmp8384);
	let tmp8393: f32 = (tmp8392 / tmp8384);
	let tmp8390: f32 = (tmp8389 / tmp8384);
	let tmp8323: f32 = (tmp8321 + tmp8322);
	let tmp8325: t_glsl_const_01 = c_glsl_const_01;
	let tmp8328: f32 = (tmp8326 + tmp8327);
	let tmp8334: f32 = (tmp8330.v_o * tmp8333);
	let tmp8335: t_glsl_const_02 = c_glsl_const_02;
	let tmp303: vec2<f32> = (tmp307.v_radius);
	let tmp8560: t_neo_elem_44_transform = u_neo_elem_44_transform;
	let tmp8337: t_glsl_const_01 = c_glsl_const_01;
	let tmp8340: f32 = (tmp8338 - tmp8339);
	let tmp8342: t_glsl_const_01 = c_glsl_const_01;
	let tmp8345: f32 = (tmp8343 - tmp8344);
	let tmp8204: vec3<f32> = (tmp8366);
	let tmp8347: t_glsl_const_01 = c_glsl_const_01;
	let tmp8350: f32 = (tmp8348 + tmp8349);
	let tmp013: vec2<f32> = ((abs(tmp045) - (tmp046.v_dims)) + vec2<f32>(mix(mix((tmp043.w), (tmp043.y), step(c_glsl_const_00.v_o, (tmp045.x))), mix((tmp043.z), (tmp043.x), step(c_glsl_const_00.v_o, (tmp045.x))), step(c_glsl_const_00.v_o, (tmp045.y))), mix(mix((tmp043.w), (tmp043.y), step(c_glsl_const_00.v_o, (tmp045.x))), mix((tmp043.z), (tmp043.x), step(c_glsl_const_00.v_o, (tmp045.x))), step(c_glsl_const_00.v_o, (tmp045.y)))));
	let tmp8357: t_glsl_const_02 = c_glsl_const_02;
	let tmp8025: f32 = min(tmp8023, tmp8024);
	let tmp8491: vec3<f32> = (u_neo_elem_50_transform.v_trans);
	let tmp8490: vec3<f32> = (tmp8502);
	let tmp7915: f32 = ((min(max((tmp520.x), (tmp520.y)), c_glsl_const_00.v_o) + (length(max(tmp520, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp527)));
	let tmp7923: f32 = (tmp7921 * tmp7922);
	let tmp8020: f32 = (tmp7927);
	let tmp8356: f32 = (tmp8352.v_o * tmp8355);
	let tmp8398: f32 = ((tmp8386 / tmp8384) * (tmp8386 / tmp8384));
	let tmp8454: vec3<f32> = vec3<f32>(tmp8453, tmp8453, tmp8453);
	let tmp8452: vec3<f32> = (tmp8480);
	let tmp8387: f32 = (tmp8386 / tmp8384);
	let tmp8399: f32 = (tmp8390 * tmp8390);
	let tmp231: vec3<f32> = tmp8182;
	let tmp094: f32 = mix(mix((tmp120.w), (tmp120.y), step(c_glsl_const_00.v_o, (tmp122.x))), mix((tmp120.z), (tmp120.x), step(c_glsl_const_00.v_o, (tmp122.x))), step(c_glsl_const_00.v_o, (tmp122.y)));
	let tmp8270: mat3x3<f32> = mat3x3<f32>(tmp8225, tmp8230, tmp8235, tmp8240, tmp8247, tmp8252, tmp8257, tmp8262, tmp8269);
	let tmp8420: f32 = (tmp8387 * tmp8387);
	let tmp8443: f32 = (tmp8396 * tmp8396);
	let tmp8442: f32 = (tmp8387 * tmp8387);
	let tmp8421: f32 = (tmp8393 * tmp8393);
	let tmp8312: f32 = (tmp8308.v_o * tmp8311);
	let tmp8313: t_glsl_const_02 = c_glsl_const_02;
	let tmp8315: t_glsl_const_01 = c_glsl_const_01;
	let tmp8318: f32 = (tmp8316 - tmp8317);
	let tmp8320: t_glsl_const_01 = c_glsl_const_01;
	let tmp8011: f32 = (tmp7915);
	let tmp8314: f32 = (tmp8312 - tmp8313.v_o);
	let tmp8411: f32 = (tmp8387 * tmp8393);
	let tmp8346: f32 = (tmp8342.v_o * tmp8345);
	let tmp8438: f32 = (tmp8387 * tmp8390);
	let tmp8112: f32 = (tmp8025);
	let tmp289: vec2<f32> = vec2<f32>((((min(max((tmp244.x), (tmp244.y)), c_glsl_const_00.v_o) + (length(max(tmp244, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp248))) + mix((tmp303.y), (tmp303.x), step(c_glsl_const_00.v_o, (tmp231.y)))), (abs((tmp231.y)) - (tmp307.v_height)));
	let tmp8271: vec3<f32> = (tmp8270 * tmp8204);
	let tmp8433: f32 = (tmp8387 * tmp8393);
	let tmp8472: f32 = (u_neo_elem_50_transform.v_scale);
	let tmp8400: f32 = (tmp8398 + tmp8399);
	let tmp8336: f32 = (tmp8334 - tmp8335.v_o);
	let tmp8329: f32 = (tmp8325.v_o * tmp8328);
	let tmp8341: f32 = (tmp8337.v_o * tmp8340);
	let tmp8444: f32 = (tmp8442 + tmp8443);
	let tmp8351: f32 = (tmp8347.v_o * tmp8350);
	let tmp8428: f32 = (tmp8387 * tmp8390);
	let tmp8017: f32 = (tmp7923);
	let tmp8427: f32 = (tmp8393 * tmp8396);
	let tmp8419: t_glsl_const_01 = c_glsl_const_01;
	let tmp8416: f32 = (tmp8387 * tmp8396);
	let tmp8319: f32 = (tmp8315.v_o * tmp8318);
	let tmp8455: vec3<f32> = (tmp8452 / tmp8454);
	let tmp8415: f32 = (tmp8390 * tmp8393);
	let tmp8410: f32 = (tmp8390 * tmp8396);
	let tmp8441: t_glsl_const_01 = c_glsl_const_01;
	let tmp8397: t_glsl_const_01 = c_glsl_const_01;
	let tmp8324: f32 = (tmp8320.v_o * tmp8323);
	let tmp373: f32 = mix((tmp380.y), (tmp380.x), step(c_glsl_const_00.v_o, tmp382));
	let tmp8437: f32 = (tmp8393 * tmp8396);
	let tmp305: f32 = (tmp231.y);
	let tmp8406: f32 = (tmp8387 * tmp8396);
	let tmp8432: f32 = (tmp8390 * tmp8396);
	let tmp230: t_neo_elem_48_mod = u_neo_elem_48_mod;
	let tmp8492: vec3<f32> = (tmp8490 - tmp8491);
	let tmp8422: f32 = (tmp8420 + tmp8421);
	let tmp8012: f32 = (tmp8560.v_scale);
	let tmp8358: f32 = (tmp8356 - tmp8357.v_o);
	let tmp8405: f32 = (tmp8390 * tmp8393);
	let tmp8113: f32 = (tmp8020);
	let tmp8409: t_glsl_const_01 = c_glsl_const_01;
	let tmp8114: f32 = min(tmp8112, tmp8113);
	let tmp8412: f32 = (tmp8410 + tmp8411);
	let tmp8005: f32 = ((min(max((tmp443.x), (tmp443.y)), c_glsl_const_00.v_o) + (length(max(tmp443, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp450)));
	let tmp8561: t_neo_elem_45_transform = u_neo_elem_45_transform;
	let tmp8414: t_glsl_const_01 = c_glsl_const_01;
	let tmp8402: t_glsl_const_02 = c_glsl_const_02;
	let tmp8401: f32 = (tmp8397.v_o * tmp8400);
	let tmp8293: vec3<f32> = (tmp8455);
	let tmp8473: vec3<f32> = vec3<f32>(tmp8472, tmp8472, tmp8472);
	let tmp8471: vec3<f32> = (tmp8492);
	let tmp8417: f32 = (tmp8415 + tmp8416);
	let tmp8426: t_glsl_const_01 = c_glsl_const_01;
	let tmp8446: t_glsl_const_02 = c_glsl_const_02;
	let tmp8445: f32 = (tmp8441.v_o * tmp8444);
	let tmp8429: f32 = (tmp8427 - tmp8428);
	let tmp8424: t_glsl_const_02 = c_glsl_const_02;
	let tmp8423: f32 = (tmp8419.v_o * tmp8422);
	let tmp8431: t_glsl_const_01 = c_glsl_const_01;
	let tmp8109: f32 = (tmp8017);
	let tmp8013: f32 = (tmp8011 * tmp8012);
	let tmp8359: mat3x3<f32> = mat3x3<f32>(tmp8314, tmp8319, tmp8324, tmp8329, tmp8336, tmp8341, tmp8346, tmp8351, tmp8358);
	let tmp226: vec2<f32> = (tmp230.v_radius);
	let tmp8404: t_glsl_const_01 = c_glsl_const_01;
	let tmp154: vec3<f32> = tmp8271;
	let tmp017: f32 = mix(mix((tmp043.w), (tmp043.y), step(c_glsl_const_00.v_o, (tmp045.x))), mix((tmp043.z), (tmp043.x), step(c_glsl_const_00.v_o, (tmp045.x))), step(c_glsl_const_00.v_o, (tmp045.y)));
	let tmp8434: f32 = (tmp8432 - tmp8433);
	let tmp8407: f32 = (tmp8405 - tmp8406);
	let tmp8436: t_glsl_const_01 = c_glsl_const_01;
	let tmp8439: f32 = (tmp8437 + tmp8438);
	let tmp212: vec2<f32> = vec2<f32>((((min(max((tmp167.x), (tmp167.y)), c_glsl_const_00.v_o) + (length(max(tmp167, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp171))) + mix((tmp226.y), (tmp226.x), step(c_glsl_const_00.v_o, (tmp154.y)))), (abs((tmp154.y)) - (tmp230.v_height)));
	let tmp8403: f32 = (tmp8401 - tmp8402.v_o);
	let tmp8413: f32 = (tmp8409.v_o * tmp8412);
	let tmp8101: f32 = (tmp8561.v_scale);
	let tmp8430: f32 = (tmp8426.v_o * tmp8429);
	let tmp8474: vec3<f32> = (tmp8471 / tmp8473);
	let tmp8201: f32 = (tmp8114);
	let tmp8360: vec3<f32> = (tmp8359 * tmp8293);
	let tmp153: t_neo_elem_49_mod = u_neo_elem_49_mod;
	let tmp296: f32 = mix((tmp303.y), (tmp303.x), step(c_glsl_const_00.v_o, tmp305));
	let tmp8408: f32 = (tmp8404.v_o * tmp8407);
	let tmp8447: f32 = (tmp8445 - tmp8446.v_o);
	let tmp8100: f32 = (tmp8005);
	let tmp8440: f32 = (tmp8436.v_o * tmp8439);
	let tmp8425: f32 = (tmp8423 - tmp8424.v_o);
	let tmp8435: f32 = (tmp8431.v_o * tmp8434);
	let tmp228: f32 = (tmp154.y);
	let tmp8106: f32 = (tmp8013);
	let tmp8202: f32 = (tmp8109);
	let tmp8418: f32 = (tmp8414.v_o * tmp8417);
	let tmp8203: f32 = min(tmp8201, tmp8202);
	let tmp8198: f32 = (tmp8106);
	let tmp8102: f32 = (tmp8100 * tmp8101);
	let tmp8094: f32 = ((min(max((tmp366.x), (tmp366.y)), c_glsl_const_00.v_o) + (length(max(tmp366, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp373)));
	let tmp8448: mat3x3<f32> = mat3x3<f32>(tmp8403, tmp8408, tmp8413, tmp8418, tmp8425, tmp8430, tmp8435, tmp8440, tmp8447);
	let tmp8562: t_neo_elem_46_transform = u_neo_elem_46_transform;
	let tmp149: vec2<f32> = (tmp153.v_radius);
	let tmp077: vec3<f32> = tmp8360;
	let tmp8382: vec3<f32> = (tmp8474);
	let tmp8190: f32 = (tmp8562.v_scale);
	let tmp135: vec2<f32> = vec2<f32>((((min(max((tmp090.x), (tmp090.y)), c_glsl_const_00.v_o) + (length(max(tmp090, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp094))) + mix((tmp149.y), (tmp149.x), step(c_glsl_const_00.v_o, (tmp077.y)))), (abs((tmp077.y)) - (tmp153.v_height)));
	let tmp8195: f32 = (tmp8102);
	let tmp8189: f32 = (tmp8094);
	let tmp219: f32 = mix((tmp226.y), (tmp226.x), step(c_glsl_const_00.v_o, tmp228));
	let tmp076: t_neo_elem_50_mod = u_neo_elem_50_mod;
	let tmp8290: f32 = (tmp8203);
	let tmp8449: vec3<f32> = (tmp8448 * tmp8382);
	let tmp8291: f32 = (tmp8198);
	let tmp151: f32 = (tmp077.y);
	let tmp072: vec2<f32> = (tmp076.v_radius);
	let tmp8191: f32 = (tmp8189 * tmp8190);
	let tmp8287: f32 = (tmp8195);
	let tmp8563: t_neo_elem_47_transform = u_neo_elem_47_transform;
	let tmp000: vec3<f32> = tmp8449;
	let tmp8292: f32 = min(tmp8290, tmp8291);
	let tmp8183: f32 = ((min(max((tmp289.x), (tmp289.y)), c_glsl_const_00.v_o) + (length(max(tmp289, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp296)));
	let tmp8279: f32 = (tmp8563.v_scale);
	let tmp142: f32 = mix((tmp149.y), (tmp149.x), step(c_glsl_const_00.v_o, tmp151));
	let tmp8278: f32 = (tmp8183);
	let tmp074: f32 = (tmp000.y);
	let tmp8380: f32 = (tmp8287);
	let tmp058: vec2<f32> = vec2<f32>((((min(max((tmp013.x), (tmp013.y)), c_glsl_const_00.v_o) + (length(max(tmp013, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp017))) + mix((tmp072.y), (tmp072.x), step(c_glsl_const_00.v_o, tmp074))), (abs(tmp074) - (tmp076.v_height)));
	let tmp8379: f32 = (tmp8292);
	let tmp8284: f32 = (tmp8191);
	let tmp8381: f32 = min(tmp8379, tmp8380);
	let tmp8280: f32 = (tmp8278 * tmp8279);
	let tmp8272: f32 = ((min(max((tmp212.x), (tmp212.y)), c_glsl_const_00.v_o) + (length(max(tmp212, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp219)));
	let tmp8564: t_neo_elem_48_transform = u_neo_elem_48_transform;
	let tmp8376: f32 = (tmp8284);
	let tmp8468: f32 = (tmp8381);
	let tmp8368: f32 = (tmp8564.v_scale);
	let tmp065: f32 = mix((tmp072.y), (tmp072.x), step(c_glsl_const_00.v_o, tmp074));
	let tmp8373: f32 = (tmp8280);
	let tmp8469: f32 = (tmp8376);
	let tmp8367: f32 = (tmp8272);
	let tmp8361: f32 = ((min(max((tmp135.x), (tmp135.y)), c_glsl_const_00.v_o) + (length(max(tmp135, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp142)));
	let tmp8470: f32 = min(tmp8468, tmp8469);
	let tmp8565: t_neo_elem_49_transform = u_neo_elem_49_transform;
	let tmp8369: f32 = (tmp8367 * tmp8368);
	let tmp8465: f32 = (tmp8373);
	let tmp8487: f32 = (tmp8470);
	let tmp8456: f32 = (tmp8361);
	let tmp8462: f32 = (tmp8369);
	let tmp8457: f32 = (tmp8565.v_scale);
	let tmp8488: f32 = (tmp8465);
	let tmp8450: f32 = ((min(max((tmp058.x), (tmp058.y)), c_glsl_const_00.v_o) + (length(max(tmp058, vec2<f32>(c_glsl_const_00.v_o, c_glsl_const_00.v_o))) - tmp065)));
	let tmp8489: f32 = min(tmp8487, tmp8488);
	let tmp8458: f32 = (tmp8456 * tmp8457);
	let tmp8484: f32 = (tmp8462);
	let tmp8566: t_neo_elem_50_transform = u_neo_elem_50_transform;
	let tmp8499: f32 = (tmp8489);
	let tmp8500: f32 = (tmp8484);
	let tmp8475: f32 = (tmp8450);
	let tmp8476: f32 = (tmp8566.v_scale);
	let tmp8481: f32 = (tmp8458);
	let tmp8477: f32 = (tmp8475 * tmp8476);
	let tmp8501: f32 = min(tmp8499, tmp8500);
	let tmp8496: f32 = (tmp8481);
	let tmp8493: f32 = (tmp8477);
	let tmp8506: f32 = (tmp8501);
	let tmp8507: f32 = (tmp8496);
	let tmp8508: f32 = min(tmp8506, tmp8507);
	let tmp8503: f32 = (tmp8493);
	let tmp8511: f32 = (tmp8508);
	let tmp8512: f32 = (tmp8503);
	let tmp8513: f32 = min(tmp8511, tmp8512);
	return t_outlet(tmp8513);
}

