//// PREAMBLE

fn signed_distance_function(pos_: vec3<f32>) -> f32 {
	var pos = pos_;
	pos += vec3(0.0, 0.0, 0.4);
	pos /= 1.5;
    return compute_main_digraph(pos).v_dist * 1.5;
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

fn customModf(xx : f32) -> f32 {
    return modf(xx).fract;
}

fn customModf2(xx : vec2<f32>) -> vec2<f32> {
    return modf(xx).fract;
}

fn customModf3(xx : vec3<f32>) -> vec3<f32> {
    return modf(xx).fract;
}

fn customModf4(xx : vec4<f32>) -> vec4<f32> {
    return modf(xx).fract;
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

struct t_hole_params {
	v_pos1: vec3<f32>,
	v_pos2: vec3<f32>,
	v_pos3: vec3<f32>,
	v_pos4: vec3<f32>,
	v_pos5: vec3<f32>,
	v_pos6: vec3<f32>,
	v_pos7: vec3<f32>,
	v_pos8: vec3<f32>,
}

struct t_carving_params {
	v_inset: f32,
}

struct t_cheese_params {
	v_angle1: f32,
	v_angle2: f32,
}

struct t_plank_consts {
	v_height: f32,
	v_radius: f32,
	v_elong_width: f32,
	v_elong_depth: f32,
	v_handle_width: f32,
	v_handle_depth: f32,
}

struct t_zero {
	v_value: f32,
}

struct t_hole_consts {
	v_radius1_1: f32,
	v_radius1_2: f32,
	v_radius2_1: f32,
	v_radius2_2: f32,
	v_radius3_1: f32,
	v_offset1_2: vec3<f32>,
	v_radius3_2: f32,
	v_offset2_2: vec3<f32>,
	v_offset3_2: vec3<f32>,
	v_radius4: f32,
	v_radius5: f32,
	v_radius6: f32,
	v_radius7: f32,
	v_radius8: f32,
}

struct t_one {
	v_value: f32,
}

struct t_pi {
	v_value: f32,
}

struct t_carving_consts {
	v_depth: f32,
	v_thickness: f32,
	v_hole_radius: f32,
}

struct t_plank_holes_consts {
	v_border: f32,
	v_length: f32,
	v_radius_fac: f32,
}

struct t_angle_const {
	v_half: f32,
	v_full: f32,
}

struct t_two {
	v_value: f32,
}

struct t_cheese_consts {
	v_height: f32,
	v_radius: f32,
	v_height2_fac: f32,
	v_radius2_fac: f32,
	v_radius3_fac: f32,
	v_inflate: f32,
	v_offset_angle: f32,
	v_min_angle: f32,
}

struct t_cheese_pose_consts {
	v_angle: f32,
	v_x: f32,
	v_z: f32,
}

struct t_position {
	v_pos: vec3<f32>,
}
struct t_outlet {
	v_dist: f32,
}

//// INSTANCES

const u_hole_params: t_hole_params = t_hole_params(vec3(-0.015, 0.061, -0.185), vec3(0, 0.069, -0.352), vec3(0, 0.023, 0), vec3(-0.231, 0.053, -0.296), vec3(-0.169, 0.031, -0.163), vec3(0.015, -0.092, -0.259), vec3(-0.23, -0.093, -0.223), vec3(-0.092, 0.108, -0.282));
const u_carving_params: t_carving_params = t_carving_params(f32(0.057));
const u_cheese_params: t_cheese_params = t_cheese_params(f32(0), f32(44));

const c_plank_consts: t_plank_consts = t_plank_consts(f32(0.028), f32(0.038), f32(0.304), f32(0.37), f32(0.032), f32(0.18));
const c_zero: t_zero = t_zero(f32(0));
const c_hole_consts: t_hole_consts = t_hole_consts(f32(0.04), f32(0.025), f32(0.035), f32(0.016), f32(0.036), vec3(0, 0.032, 0.04), f32(0.037), vec3(-0.031, 0.015, 0), vec3(-0.038, -0.046, 0), f32(0.048), f32(0.034), f32(0.073), f32(0.065), f32(0.047));
const c_one: t_one = t_one(f32(1));
const c_pi: t_pi = t_pi(f32(3.1415927));
const c_carving_consts: t_carving_consts = t_carving_consts(f32(0.004), f32(0.012), f32(0.106));
const c_plank_holes_consts: t_plank_holes_consts = t_plank_holes_consts(f32(0.034), f32(0.053), f32(0.702));
const c_angle_const: t_angle_const = t_angle_const(f32(180), f32(360));
const c_two: t_two = t_two(f32(2));
const c_cheese_consts: t_cheese_consts = t_cheese_consts(f32(0.091), f32(0.465), f32(0), f32(0.973), f32(0.798), f32(0), f32(137.273), f32(5));
const c_cheese_pose_consts: t_cheese_pose_consts = t_cheese_pose_consts(f32(125), f32(0.162), f32(-0.192));

//// IMPLEMENTATIONS

// FID[0422] ComposeFuncType::Terminal main:(v3 pos)->(sc dist)
// FID[0421] ComposeFuncType::Inlet position:()->(v3 pos)
// FID[0423] ComposeFuncType::Outlet outlet:(sc dist)->()
fn compute_main_digraph(a_pos: vec3<f32>) -> t_outlet {
	let tmp477: t_angle_const = c_angle_const;
	let tmp382: t_two = c_two;
	let tmp475: t_pi = c_pi;
	let tmp379: t_plank_consts = c_plank_consts;
	let tmp380: t_carving_consts = c_carving_consts;
	let tmp381: f32 = (tmp379.v_height * tmp382.v_value);
	let tmp514: t_angle_const = c_angle_const;
	let tmp476: f32 = (tmp475.v_value / tmp477.v_half);
	let tmp517: f32 = (u_cheese_params.v_angle2 + c_cheese_consts.v_offset_angle);
	let tmp512: t_pi = c_pi;
	let tmp373: t_plank_holes_consts = c_plank_holes_consts;
	let tmp474: f32 = (tmp476 * tmp517);
	let tmp366: f32 = ((c_plank_holes_consts.v_length - (c_plank_consts.v_radius * c_plank_holes_consts.v_radius_fac)) + (c_plank_consts.v_radius * c_plank_holes_consts.v_radius_fac));
	let tmp451: t_angle_const = c_angle_const;
	let tmp513: f32 = (tmp512.v_value / tmp514.v_half);
	let tmp364: f32 = (((c_plank_consts.v_elong_depth + c_plank_consts.v_handle_depth) + c_plank_consts.v_radius) + c_plank_consts.v_handle_depth);
	let tmp378: f32 = (tmp381 - tmp380.v_depth);
	let tmp377: t_zero = c_zero;
	let tmp449: t_pi = c_pi;
	let tmp369: f32 = (tmp366 + tmp373.v_border);
	let tmp450: f32 = (tmp449.v_value / tmp451.v_half);
	let tmp365: f32 = (tmp364 + c_plank_consts.v_radius);
	let tmp376: vec3<f32> = vec3<f32>(tmp377.v_value, tmp378, tmp377.v_value);
	let tmp508: f32 = (tmp474 - ((c_pi.v_value / c_angle_const.v_half) * (u_cheese_params.v_angle1 + c_cheese_consts.v_offset_angle)));
	let tmp356: f32 = (c_plank_consts.v_elong_depth + c_plank_consts.v_handle_depth);
	let tmp511: f32 = (tmp513 * c_cheese_consts.v_min_angle);
	let tmp406: t_plank_consts = c_plank_consts;
	let tmp312: f32 = (cos(c_zero.v_value) * sin((tmp450 * c_cheese_pose_consts.v_angle)));
	let tmp367: f32 = (tmp365 - tmp369);
	let tmp448: f32 = (tmp450 * c_cheese_pose_consts.v_angle);
	let tmp359: t_zero = c_zero;
	let tmp357: f32 = (tmp356 + c_plank_consts.v_radius);
	let tmp355: t_zero = c_zero;
	let tmp384: t_carving_params = u_carving_params;
	let tmp471: t_pi = c_pi;
	let tmp260: t_one = c_one;
	let tmp473: t_angle_const = c_angle_const;
	let tmp294: vec3<f32> = ((((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * c_one.v_value) - tmp376);
	let tmp469: t_cheese_params = u_cheese_params;
	let tmp126: vec3<f32> = vec3<f32>(vec4<f32>(max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).x, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).y, (abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).z)), c_zero.v_value)).x, vec4<f32>(max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).x, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).y, (abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).z)), c_zero.v_value)).y, vec4<f32>(max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).x, max((abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).y, (abs((tmp294 * c_one.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).z)), c_zero.v_value)).z);
	let tmp142: vec2<f32> = vec2<f32>(tmp126.x, tmp126.z);
	let tmp280: t_one = c_one;
	let tmp144: t_zero = c_zero;
	let tmp509: f32 = max(tmp508, tmp511);
	let tmp452: t_zero = c_zero;
	let tmp275: t_one = c_one;
	let tmp510: t_cheese_consts = c_cheese_consts;
	let tmp316: f32 = (cos(tmp452.v_value) * sin(tmp448));
	let tmp325: f32 = (sin(tmp452.v_value) * sin(tmp448));
	let tmp321: f32 = (sin(tmp452.v_value) * sin(tmp448));
	let tmp408: t_cheese_consts = c_cheese_consts;
	let tmp372: f32 = (c_plank_consts.v_radius - (c_plank_consts.v_radius * c_plank_holes_consts.v_radius_fac));
	let tmp368: f32 = (c_plank_consts.v_handle_width - c_plank_holes_consts.v_border);
	let tmp309: f32 = cos(tmp452.v_value);
	let tmp310: f32 = sin(tmp452.v_value);
	let tmp306: f32 = cos(tmp452.v_value);
	let tmp305: f32 = sin(tmp452.v_value);
	let tmp259: vec3<f32> = (((((mat3x3<f32>((tmp306 * cos(tmp448)), ((tmp312 * tmp310) - (tmp305 * tmp309)), ((tmp316 * tmp309) + (tmp305 * tmp310)), (tmp305 * cos(tmp448)), ((tmp321 * tmp310) + (tmp306 * tmp309)), ((tmp325 * tmp309) - (tmp306 * tmp310)), opp(sin(tmp448)), (cos(tmp448) * tmp310), (cos(tmp448) * tmp309)) * ((t_position(a_pos).v_pos * c_one.v_value) - vec3<f32>(c_cheese_pose_consts.v_x, (tmp408.v_height + tmp406.v_height), c_cheese_pose_consts.v_z))) * c_one.v_value) * tmp275.v_value) * c_one.v_value) * tmp260.v_value);
	let tmp358: vec3<f32> = vec3<f32>(tmp359.v_value, tmp359.v_value, tmp367);
	let tmp354: vec3<f32> = vec3<f32>(tmp355.v_value, tmp355.v_value, tmp357);
	let tmp308: f32 = sin(tmp448);
	let tmp307: f32 = cos(tmp448);
	let tmp095: vec3<f32> = vec3<f32>(vec4<f32>(max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).x, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).y, (abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).z)), c_zero.v_value)).x, vec4<f32>(max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).x, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).y, (abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).z)), c_zero.v_value)).y, vec4<f32>(max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).x, max((abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).y, (abs((tmp294 * tmp280.v_value)) - vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), c_zero.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset))).z)), c_zero.v_value)).z);
	let tmp328: f32 = (tmp306 * tmp310);
	let tmp313: f32 = (tmp312 * tmp310);
	let tmp143: vec3<f32> = tmp126;
	let tmp322: f32 = (tmp321 * tmp310);
	let tmp263: t_one = c_one;
	let tmp337: t_one = c_one;
	let tmp454: t_hole_params = u_hole_params;
	let tmp326: f32 = (tmp325 * tmp309);
	let tmp507: f32 = (((tmp471.v_value / tmp473.v_half) * (tmp469.v_angle1 + tmp510.v_offset_angle)) + tmp509);
	let tmp145: vec3<f32> = vec3<f32>((c_plank_consts.v_elong_width - tmp384.v_inset), tmp144.v_value, (c_plank_consts.v_elong_depth - tmp384.v_inset));
	let tmp319: f32 = (tmp305 * tmp310);
	let tmp274: vec3<f32> = (((mat3x3<f32>((tmp306 * tmp307), (tmp313 - (tmp305 * tmp309)), ((tmp316 * tmp309) + tmp319), (tmp305 * tmp307), (tmp322 + (tmp306 * tmp309)), (tmp326 - tmp328), opp(tmp308), (tmp307 * tmp310), (tmp307 * tmp309)) * ((t_position(a_pos).v_pos * c_one.v_value) - vec3<f32>(c_cheese_pose_consts.v_x, (tmp408.v_height + tmp406.v_height), c_cheese_pose_consts.v_z))) * c_one.v_value) * tmp275.v_value);
	let tmp266: t_one = c_one;
	let tmp446: t_pi = c_pi;
	let tmp386: t_plank_consts = c_plank_consts;
	let tmp385: f32 = (c_plank_consts.v_elong_depth - tmp384.v_inset);
	let tmp317: f32 = (tmp316 * tmp309);
	let tmp383: f32 = (c_plank_consts.v_elong_width - tmp384.v_inset);
	let tmp281: vec3<f32> = (tmp294 * tmp280.v_value);
	let tmp458: t_hole_params = u_hole_params;
	let tmp146: vec3<f32> = abs(tmp281);
	let tmp315: f32 = (tmp305 * tmp309);
	let tmp472: f32 = (tmp471.v_value / tmp473.v_half);
	let tmp447: t_cheese_pose_consts = c_cheese_pose_consts;
	let tmp388: t_two = c_two;
	let tmp324: f32 = (tmp306 * tmp309);
	let tmp141: f32 = length(tmp142);
	let tmp407: f32 = (tmp408.v_height + tmp406.v_height);
	let tmp516: f32 = (tmp469.v_angle1 + tmp510.v_offset_angle);
	let tmp113: t_zero = c_zero;
	let tmp111: vec2<f32> = vec2<f32>(tmp095.x, tmp095.z);
	let tmp456: t_hole_params = u_hole_params;
	let tmp152: vec3<f32> = (tmp146 - tmp145);
	let tmp445: t_zero = c_zero;
	let tmp515: f32 = (tmp507 + tmp446.v_value);
	let tmp429: f32 = (cos(tmp445.v_value) * sin(tmp515));
	let tmp301: t_one = c_one;
	let tmp265: vec3<f32> = (tmp274 * tmp266.v_value);
	let tmp297: vec3<f32> = ((((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * tmp337.v_value) - tmp358);
	let tmp284: vec3<f32> = (((((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * tmp337.v_value) * tmp301.v_value) - tmp354);
	let tmp425: f32 = (cos(tmp445.v_value) * sin(tmp515));
	let tmp064: vec3<f32> = vec3<f32>(vec4<f32>(max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).x, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).y, (abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).z)), c_zero.v_value)).x, vec4<f32>(max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).x, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).y, (abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).z)), c_zero.v_value)).y, vec4<f32>(max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).x, max((abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).y, (abs(tmp284) - vec3<f32>(c_plank_consts.v_handle_width, c_zero.v_value, c_plank_consts.v_handle_depth)).z)), c_zero.v_value)).z);
	let tmp254: t_one = c_one;
	let tmp251: t_one = c_one;
	let tmp247: vec3<f32> = (tmp259 - tmp454.v_pos1);
	let tmp244: vec3<f32> = (tmp259 - tmp456.v_pos2);
	let tmp405: vec3<f32> = vec3<f32>(tmp447.v_x, tmp407, tmp447.v_z);
	let tmp241: vec3<f32> = ((tmp265 * c_one.v_value) - tmp458.v_pos3);
	let tmp224: t_one = c_one;
	let tmp221: t_one = c_one;
	let tmp374: f32 = (c_plank_holes_consts.v_length - (c_plank_consts.v_radius * c_plank_holes_consts.v_radius_fac));
	let tmp218: t_one = c_one;
	let tmp262: vec3<f32> = (tmp274 * tmp263.v_value);
	let tmp214: vec3<f32> = ((tmp247 * tmp224.v_value) - c_hole_consts.v_offset1_2);
	let tmp211: vec3<f32> = ((tmp244 * tmp221.v_value) - c_hole_consts.v_offset2_2);
	let tmp208: vec3<f32> = ((tmp241 * tmp218.v_value) - c_hole_consts.v_offset3_2);
	let tmp158: vec2<f32> = vec2<f32>(((((mat3x3<f32>((tmp306 * tmp307), (tmp313 - tmp315), (tmp317 + tmp319), (tmp305 * tmp307), (tmp322 + tmp324), (tmp326 - tmp328), opp(tmp308), (tmp307 * tmp310), (tmp307 * tmp309)) * ((t_position(a_pos).v_pos * c_one.v_value) - tmp405)) * c_one.v_value) * c_one.v_value) * c_one.v_value).x, ((((mat3x3<f32>((tmp306 * tmp307), (tmp313 - tmp315), (tmp317 + tmp319), (tmp305 * tmp307), (tmp322 + tmp324), (tmp326 - tmp328), opp(tmp308), (tmp307 * tmp310), (tmp307 * tmp309)) * ((t_position(a_pos).v_pos * c_one.v_value) - tmp405)) * c_one.v_value) * c_one.v_value) * c_one.v_value).z);
	let tmp470: f32 = (tmp472 * tmp516);
	let tmp155: f32 = max(tmp152.y, tmp152.z);
	let tmp151: vec3<f32> = vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value);
	let tmp390: f32 = (tmp386.v_radius - c_carving_consts.v_thickness);
	let tmp387: f32 = (tmp386.v_height * tmp388.v_value);
	let tmp371: f32 = (tmp368 + tmp372);
	let tmp147: vec3<f32> = (tmp146 - tmp145);
	let tmp112: vec3<f32> = tmp095;
	let tmp500: f32 = (sin(tmp445.v_value) * sin(tmp470));
	let tmp338: vec3<f32> = (((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * tmp337.v_value);
	let tmp139: vec2<f32> = vec2<f32>(tmp141, tmp143.y);
	let tmp496: f32 = (sin(tmp445.v_value) * sin(tmp470));
	let tmp115: vec3<f32> = abs(tmp281);
	let tmp114: vec3<f32> = vec3<f32>(tmp383, tmp113.v_value, tmp385);
	let tmp491: f32 = (cos(tmp445.v_value) * sin(tmp470));
	let tmp110: f32 = length(tmp111);
	let tmp487: f32 = (cos(tmp445.v_value) * sin(tmp470));
	let tmp082: t_zero = c_zero;
	let tmp080: vec2<f32> = vec2<f32>(tmp064.x, tmp064.z);
	let tmp049: t_zero = c_zero;
	let tmp047: vec2<f32> = vec2<f32>(vec3<f32>(vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).x, vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).y, vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).z).x, vec3<f32>(vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).x, vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).y, vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).z).z);
	let tmp257: t_one = c_one;
	let tmp031: vec3<f32> = vec3<f32>(vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).x, vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).y, vec4<f32>(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).x, max((abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).y, (abs(tmp297) - vec3<f32>(tmp371, tmp049.v_value, tmp374)).z)), c_zero.v_value)).z);
	let tmp331: f32 = (tmp307 * tmp309);
	let tmp330: f32 = (tmp307 * tmp310);
	let tmp329: f32 = opp(tmp308);
	let tmp327: f32 = (tmp326 - tmp328);
	let tmp323: f32 = (tmp322 + tmp324);
	let tmp434: f32 = (sin(tmp445.v_value) * sin(tmp515));
	let tmp320: f32 = (tmp305 * tmp307);
	let tmp438: f32 = (sin(tmp445.v_value) * sin(tmp515));
	let tmp318: f32 = (tmp317 + tmp319);
	let tmp314: f32 = (tmp313 - tmp315);
	let tmp311: f32 = (tmp306 * tmp307);
	let tmp360: t_plank_consts = c_plank_consts;
	let tmp204: f32 = length(tmp211);
	let tmp480: f32 = sin(tmp445.v_value);
	let tmp422: f32 = cos(tmp445.v_value);
	let tmp421: f32 = sin(tmp515);
	let tmp419: f32 = cos(tmp445.v_value);
	let tmp418: f32 = sin(tmp445.v_value);
	let tmp423: f32 = sin(tmp445.v_value);
	let tmp485: f32 = sin(tmp445.v_value);
	let tmp484: f32 = cos(tmp445.v_value);
	let tmp483: f32 = sin(tmp470);
	let tmp481: f32 = cos(tmp445.v_value);
	let tmp138: vec2<f32> = abs(tmp139);
	let tmp149: t_zero = c_zero;
	let tmp116: vec3<f32> = (tmp115 - tmp114);
	let tmp420: f32 = cos(tmp515);
	let tmp223: vec3<f32> = (tmp247 * tmp224.v_value);
	let tmp159: f32 = length(tmp158);
	let tmp140: vec2<f32> = vec2<f32>(tmp390, tmp387);
	let tmp464: t_hole_params = u_hole_params;
	let tmp220: vec3<f32> = (tmp244 * tmp221.v_value);
	let tmp375: t_plank_consts = c_plank_consts;
	let tmp501: f32 = (tmp500 * tmp484);
	let tmp050: vec3<f32> = vec3<f32>(tmp371, tmp049.v_value, tmp374);
	let tmp206: f32 = length(tmp208);
	let tmp202: f32 = length(tmp214);
	let tmp482: f32 = cos(tmp470);
	let tmp051: vec3<f32> = abs(tmp297);
	let tmp121: vec3<f32> = tmp116;
	let tmp361: t_plank_holes_consts = c_plank_holes_consts;
	let tmp046: f32 = length(tmp047);
	let tmp016: vec2<f32> = vec2<f32>(vec3<f32>(vec4<f32>(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).y, (abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).x, vec4<f32>(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).y, (abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).y, vec4<f32>(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).y, (abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).z).x, vec3<f32>(vec4<f32>(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).y, (abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).x, vec4<f32>(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).y, (abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).y, vec4<f32>(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).x, max((abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).y, (abs((tmp338 * tmp301.v_value)) - vec3<f32>(c_plank_consts.v_elong_width, c_zero.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).z).z);
	let tmp300: vec3<f32> = (tmp338 * tmp301.v_value);
	let tmp081: vec3<f32> = tmp064;
	let tmp303: mat3x3<f32> = mat3x3<f32>(tmp311, tmp314, tmp318, tmp320, tmp323, tmp327, tmp329, tmp330, tmp331);
	let tmp018: t_zero = c_zero;
	let tmp217: vec3<f32> = (tmp241 * tmp218.v_value);
	let tmp157: vec3<f32> = ((((tmp303 * ((t_position(a_pos).v_pos * c_one.v_value) - tmp405)) * c_one.v_value) * c_one.v_value) * c_one.v_value);
	let tmp048: vec3<f32> = tmp031;
	let tmp466: t_hole_params = u_hole_params;
	let tmp253: vec3<f32> = (tmp262 * tmp254.v_value);
	let tmp250: vec3<f32> = (tmp262 * tmp251.v_value);
	let tmp468: t_hole_params = u_hole_params;
	let tmp460: t_hole_params = u_hole_params;
	let tmp462: t_hole_params = u_hole_params;
	let tmp441: f32 = (tmp419 * tmp423);
	let tmp154: f32 = max(tmp152.x, tmp155);
	let tmp079: f32 = length(tmp080);
	let tmp083: vec3<f32> = vec3<f32>(c_plank_consts.v_handle_width, tmp082.v_value, c_plank_consts.v_handle_depth);
	let tmp256: vec3<f32> = (tmp265 * tmp257.v_value);
	let tmp084: vec3<f32> = abs(tmp284);
	let tmp000: vec3<f32> = vec3<f32>(vec4<f32>(max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).x, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).y, (abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).x, vec4<f32>(max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).x, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).y, (abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).y, vec4<f32>(max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).x, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).y, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)), vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value)).z, min(max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).x, max((abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).y, (abs(tmp300) - vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth)).z)), c_zero.v_value)).z);
	let tmp439: f32 = (tmp438 * tmp422);
	let tmp437: f32 = (tmp419 * tmp422);
	let tmp435: f32 = (tmp434 * tmp423);
	let tmp432: f32 = (tmp418 * tmp423);
	let tmp430: f32 = (tmp429 * tmp422);
	let tmp428: f32 = (tmp418 * tmp422);
	let tmp426: f32 = (tmp425 * tmp423);
	let tmp403: t_two = c_two;
	let tmp503: f32 = (tmp481 * tmp485);
	let tmp398: t_two = c_two;
	let tmp488: f32 = (tmp487 * tmp485);
	let tmp150: vec3<f32> = max(tmp147, tmp151);
	let tmp363: t_two = c_two;
	let tmp490: f32 = (tmp480 * tmp484);
	let tmp108: vec2<f32> = vec2<f32>(tmp110, tmp112.y);
	let tmp341: vec3<f32> = ((t_position(a_pos).v_pos * c_one.v_value) - tmp405);
	let tmp492: f32 = (tmp491 * tmp484);
	let tmp120: vec3<f32> = vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value);
	let tmp494: f32 = (tmp480 * tmp485);
	let tmp124: f32 = max(tmp121.y, tmp121.z);
	let tmp497: f32 = (tmp496 * tmp485);
	let tmp499: f32 = (tmp481 * tmp484);
	let tmp404: t_cheese_consts = c_cheese_consts;
	let tmp052: vec3<f32> = (tmp051 - tmp050);
	let tmp410: f32 = (tmp404.v_radius * tmp404.v_radius2_fac);
	let tmp370: f32 = (tmp360.v_radius * tmp361.v_radius_fac);
	let tmp213: t_zero = c_zero;
	let tmp137: vec2<f32> = (tmp138 - tmp140);
	let tmp198: f32 = length(tmp220);
	let tmp506: f32 = (tmp482 * tmp484);
	let tmp210: t_zero = c_zero;
	let tmp153: f32 = min(tmp154, tmp149.v_value);
	let tmp089: vec3<f32> = vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value);
	let tmp207: f32 = (tmp206 - c_hole_consts.v_radius3_2);
	let tmp196: f32 = length(tmp223);
	let tmp444: f32 = (tmp420 * tmp422);
	let tmp443: f32 = (tmp420 * tmp423);
	let tmp442: f32 = opp(tmp421);
	let tmp457: t_hole_consts = c_hole_consts;
	let tmp440: f32 = (tmp439 - tmp441);
	let tmp118: t_zero = c_zero;
	let tmp502: f32 = (tmp501 - tmp503);
	let tmp304: vec3<f32> = (tmp303 * tmp341);
	let tmp436: f32 = (tmp435 + tmp437);
	let tmp015: f32 = length(tmp016);
	let tmp433: f32 = (tmp418 * tmp420);
	let tmp090: vec3<f32> = (tmp084 - tmp083);
	let tmp431: f32 = (tmp430 + tmp432);
	let tmp057: vec3<f32> = tmp052;
	let tmp019: vec3<f32> = vec3<f32>(c_plank_consts.v_elong_width, tmp018.v_value, c_plank_consts.v_elong_depth);
	let tmp427: f32 = (tmp426 - tmp428);
	let tmp020: vec3<f32> = abs(tmp300);
	let tmp424: f32 = (tmp419 * tmp420);
	let tmp093: f32 = max(tmp090.y, tmp090.z);
	let tmp504: f32 = opp(tmp483);
	let tmp414: t_one = c_one;
	let tmp409: f32 = (tmp404.v_radius * tmp404.v_radius3_fac);
	let tmp205: f32 = (tmp204 - c_hole_consts.v_radius2_2);
	let tmp017: vec3<f32> = tmp000;
	let tmp486: f32 = (tmp481 * tmp482);
	let tmp453: t_hole_consts = c_hole_consts;
	let tmp397: f32 = (c_plank_consts.v_radius / tmp398.v_value);
	let tmp235: vec3<f32> = (tmp253 - tmp462.v_pos5);
	let tmp395: t_carving_params = u_carving_params;
	let tmp455: t_hole_consts = c_hole_consts;
	let tmp156: vec3<f32> = tmp150;
	let tmp489: f32 = (tmp488 - tmp490);
	let tmp203: f32 = (tmp202 - tmp453.v_radius1_2);
	let tmp362: f32 = (tmp360.v_height * tmp363.v_value);
	let tmp351: t_position = t_position(a_pos);
	let tmp044: vec2<f32> = vec2<f32>(tmp046, tmp048.y);
	let tmp349: t_one = c_one;
	let tmp107: vec2<f32> = abs(tmp108);
	let tmp161: vec2<f32> = vec2<f32>(tmp159, tmp157.y);
	let tmp505: f32 = (tmp482 * tmp485);
	let tmp109: vec2<f32> = vec2<f32>(tmp375.v_radius, tmp375.v_height);
	let tmp402: f32 = (c_carving_consts.v_depth * tmp403.v_value);
	let tmp232: vec3<f32> = (tmp253 - tmp464.v_pos6);
	let tmp238: vec3<f32> = (tmp256 - tmp460.v_pos4);
	let tmp200: f32 = length(tmp217);
	let tmp229: vec3<f32> = (tmp250 - tmp466.v_pos7);
	let tmp493: f32 = (tmp492 + tmp494);
	let tmp119: vec3<f32> = max(tmp116, tmp120);
	let tmp226: vec3<f32> = (tmp250 - tmp468.v_pos8);
	let tmp498: f32 = (tmp497 + tmp499);
	let tmp085: vec3<f32> = (tmp084 - tmp083);
	let tmp056: vec3<f32> = vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value);
	let tmp123: f32 = max(tmp121.x, tmp124);
	let tmp060: f32 = max(tmp057.y, tmp057.z);
	let tmp495: f32 = (tmp480 * tmp482);
	let tmp077: vec2<f32> = vec2<f32>(tmp079, tmp081.y);
	let tmp132: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp415: t_zero = c_zero;
	let tmp216: t_zero = c_zero;
	let tmp287: t_one = c_one;
	let tmp463: t_hole_consts = c_hole_consts;
	let tmp461: t_hole_consts = c_hole_consts;
	let tmp029: f32 = max((tmp020 - tmp019).y, (tmp020 - tmp019).z);
	let tmp393: t_plank_consts = c_plank_consts;
	let tmp459: t_hole_consts = c_hole_consts;
	let tmp025: vec3<f32> = vec3<f32>(c_zero.v_value, c_zero.v_value, c_zero.v_value);
	let tmp087: t_zero = c_zero;
	let tmp054: t_zero = c_zero;
	let tmp013: vec2<f32> = vec2<f32>(tmp015, tmp017.y);
	let tmp026: vec3<f32> = (tmp020 - tmp019);
	let tmp411: vec3<f32> = vec3<f32>(tmp410, tmp409, tmp410);
	let tmp135: t_zero = c_zero;
	let tmp125: vec3<f32> = tmp119;
	let tmp288: vec3<f32> = (tmp304 * tmp287.v_value);
	let tmp413: vec3<f32> = vec3<f32>(tmp414.v_value, tmp415.v_value, tmp415.v_value);
	let tmp399: f32 = (tmp395.v_inset - tmp397);
	let tmp348: vec3<f32> = (tmp351.v_pos * tmp349.v_value);
	let tmp021: vec3<f32> = (tmp020 - tmp019);
	let tmp106: vec2<f32> = (tmp107 - tmp109);
	let tmp353: t_plank_consts = c_plank_consts;
	let tmp416: mat3x3<f32> = mat3x3<f32>(tmp424, tmp427, tmp431, tmp433, tmp436, tmp440, tmp442, tmp443, tmp444);
	let tmp392: f32 = (c_carving_consts.v_hole_radius - tmp402);
	let tmp344: t_one = c_one;
	let tmp215: f32 = (tmp203 + tmp216.v_value);
	let tmp212: f32 = (tmp205 + tmp213.v_value);
	let tmp209: f32 = (tmp207 + tmp210.v_value);
	let tmp201: f32 = (tmp200 - tmp457.v_radius3_1);
	let tmp199: f32 = (tmp198 - tmp455.v_radius2_1);
	let tmp197: f32 = (tmp196 - tmp453.v_radius1_1);
	let tmp194: f32 = length(tmp226);
	let tmp192: f32 = length(tmp229);
	let tmp190: f32 = length(tmp232);
	let tmp188: f32 = length(tmp235);
	let tmp186: f32 = length(tmp238);
	let tmp045: vec2<f32> = vec2<f32>(tmp370, tmp362);
	let tmp271: t_one = c_one;
	let tmp162: vec2<f32> = abs(tmp161);
	let tmp160: vec2<f32> = vec2<f32>(tmp404.v_radius, tmp404.v_height);
	let tmp148: vec4<f32> = vec4<f32>(tmp156.x, tmp156.y, tmp156.z, tmp153);
	let tmp277: t_one = c_one;
	let tmp136: f32 = vmax2(tmp137);
	let tmp133: vec2<f32> = max(tmp137, tmp132);
	let tmp122: f32 = min(tmp123, tmp118.v_value);
	let tmp101: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp092: f32 = max(tmp090.x, tmp093);
	let tmp088: vec3<f32> = max(tmp085, tmp089);
	let tmp478: mat3x3<f32> = mat3x3<f32>(tmp486, tmp489, tmp493, tmp495, tmp498, tmp502, tmp504, tmp505, tmp506);
	let tmp078: vec2<f32> = vec2<f32>(tmp353.v_radius, tmp353.v_height);
	let tmp076: vec2<f32> = abs(tmp077);
	let tmp059: f32 = max(tmp057.x, tmp060);
	let tmp055: vec3<f32> = max(tmp052, tmp056);
	let tmp467: t_hole_consts = c_hole_consts;
	let tmp465: t_hole_consts = c_hole_consts;
	let tmp043: vec2<f32> = abs(tmp044);
	let tmp272: vec3<f32> = ((tmp288 * tmp277.v_value) * tmp271.v_value);
	let tmp037: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp023: t_zero = c_zero;
	let tmp177: t_one = c_one;
	let tmp225: f32 = min(tmp197, tmp215);
	let tmp105: f32 = vmax2(tmp106);
	let tmp187: f32 = (tmp186 - tmp459.v_radius4);
	let tmp189: f32 = (tmp188 - tmp461.v_radius5);
	let tmp191: f32 = (tmp190 - tmp463.v_radius6);
	let tmp243: t_zero = c_zero;
	let tmp234: t_zero = c_zero;
	let tmp195: f32 = (tmp194 - tmp467.v_radius8);
	let tmp070: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp246: t_zero = c_zero;
	let tmp102: vec2<f32> = max(tmp106, tmp101);
	let tmp171: vec3<f32> = (tmp272 / tmp411);
	let tmp394: f32 = (tmp393.v_elong_width - tmp399);
	let tmp042: vec2<f32> = (tmp043 - tmp045);
	let tmp231: t_zero = c_zero;
	let tmp396: f32 = (tmp393.v_elong_depth - tmp399);
	let tmp479: vec3<f32> = (tmp478 * tmp413);
	let tmp345: vec3<f32> = (tmp348 * tmp344.v_value);
	let tmp075: vec2<f32> = (tmp076 - tmp078);
	let tmp401: f32 = (tmp392 + tmp393.v_height);
	let tmp417: vec3<f32> = (tmp416 * tmp413);
	let tmp163: vec2<f32> = (tmp162 - tmp160);
	let tmp134: f32 = min(tmp136, tmp135.v_value);
	let tmp173: vec3<f32> = (tmp411 * tmp411);
	let tmp249: t_zero = c_zero;
	let tmp219: f32 = min(tmp201, tmp209);
	let tmp130: f32 = length(tmp133);
	let tmp091: f32 = min(tmp092, tmp087.v_value);
	let tmp240: t_zero = c_zero;
	let tmp058: f32 = min(tmp059, tmp054.v_value);
	let tmp335: t_one = c_one;
	let tmp268: t_one = c_one;
	let tmp128: vec4<f32> = tmp148;
	let tmp222: f32 = min(tmp199, tmp212);
	let tmp012: vec2<f32> = abs(tmp013);
	let tmp014: vec2<f32> = vec2<f32>(tmp353.v_radius, tmp353.v_height);
	let tmp104: t_zero = c_zero;
	let tmp278: vec3<f32> = (tmp288 * tmp277.v_value);
	let tmp228: t_zero = c_zero;
	let tmp117: vec4<f32> = vec4<f32>(tmp125.x, tmp125.y, tmp125.z, tmp122);
	let tmp094: vec3<f32> = tmp088;
	let tmp193: f32 = (tmp192 - tmp465.v_radius7);
	let tmp061: vec3<f32> = tmp055;
	let tmp024: vec3<f32> = max(tmp021, tmp025);
	let tmp237: t_zero = c_zero;
	let tmp028: f32 = max(tmp026.x, tmp029);
	let tmp168: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp172: f32 = length(tmp171);
	let tmp097: vec4<f32> = tmp117;
	let tmp334: vec3<f32> = (tmp345 * tmp335.v_value);
	let tmp269: vec3<f32> = (tmp278 * tmp268.v_value);
	let tmp165: t_zero = c_zero;
	let tmp041: f32 = vmax2(tmp042);
	let tmp176: f32 = (tmp172 - tmp177.v_value);
	let tmp038: vec2<f32> = max(tmp042, tmp037);
	let tmp230: f32 = (tmp193 + tmp231.v_value);
	let tmp245: f32 = (tmp222 + tmp246.v_value);
	let tmp242: f32 = (tmp219 + tmp243.v_value);
	let tmp027: f32 = min(tmp028, tmp023.v_value);
	let tmp184: vec3<f32> = normalize(tmp417);
	let tmp040: t_zero = c_zero;
	let tmp248: f32 = (tmp225 + tmp249.v_value);
	let tmp073: t_zero = c_zero;
	let tmp174: vec3<f32> = (tmp272 / tmp173);
	let tmp006: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp030: vec3<f32> = tmp024;
	let tmp127: f32 = (tmp128.w + (tmp134 + tmp130));
	let tmp227: f32 = (tmp195 + tmp228.v_value);
	let tmp239: f32 = (tmp187 + tmp240.v_value);
	let tmp236: f32 = (tmp189 + tmp237.v_value);
	let tmp391: vec3<f32> = vec3<f32>(tmp394, tmp401, tmp396);
	let tmp103: f32 = min(tmp105, tmp104.v_value);
	let tmp099: f32 = length(tmp102);
	let tmp131: f32 = (tmp134 + tmp130);
	let tmp086: vec4<f32> = vec4<f32>(tmp094.x, tmp094.y, tmp094.z, tmp091);
	let tmp011: vec2<f32> = (tmp012 - tmp014);
	let tmp233: f32 = (tmp191 + tmp234.v_value);
	let tmp167: vec2<f32> = max(tmp163, tmp168);
	let tmp074: f32 = vmax2(tmp075);
	let tmp071: vec2<f32> = max(tmp075, tmp070);
	let tmp164: f32 = vmax2(tmp163);
	let tmp181: vec3<f32> = normalize(tmp479);
	let tmp053: vec4<f32> = vec4<f32>(tmp061.x, tmp061.y, tmp061.z, tmp058);
	let tmp258: f32 = min(tmp242, tmp239);
	let tmp033: vec4<f32> = tmp053;
	let tmp066: vec4<f32> = tmp086;
	let tmp178: f32 = (tmp176 * tmp172);
	let tmp009: t_zero = c_zero;
	let tmp072: f32 = min(tmp074, tmp073.v_value);
	let tmp175: f32 = length(tmp174);
	let tmp022: vec4<f32> = vec4<f32>(tmp030.x, tmp030.y, tmp030.z, tmp027);
	let tmp170: f32 = length(tmp167);
	let tmp166: f32 = min(tmp164, tmp165.v_value);
	let tmp252: f32 = min(tmp230, tmp227);
	let tmp255: f32 = min(tmp236, tmp233);
	let tmp180: f32 = dot(tmp269, tmp181);
	let tmp129: f32 = min(tmp131, tmp127);
	let tmp010: f32 = vmax2(tmp011);
	let tmp261: f32 = min(tmp248, tmp245);
	let tmp007: vec2<f32> = max(tmp011, tmp006);
	let tmp035: f32 = length(tmp038);
	let tmp039: f32 = min(tmp041, tmp040.v_value);
	let tmp068: f32 = length(tmp071);
	let tmp291: vec3<f32> = (tmp334 - tmp391);
	let tmp183: f32 = dot(tmp269, tmp184);
	let tmp096: f32 = (tmp097.w + (tmp103 + tmp099));
	let tmp100: f32 = (tmp103 + tmp099);
	let tmp412: t_zero = c_zero;
	let tmp002: vec4<f32> = tmp022;
	let tmp069: f32 = (tmp072 + tmp068);
	let tmp036: f32 = (tmp039 + tmp035);
	let tmp264: f32 = min(tmp255, tmp252);
	let tmp182: f32 = (tmp180 - tmp412.v_value);
	let tmp062: f32 = length(tmp291);
	let tmp032: f32 = (tmp033.w + tmp036);
	let tmp282: f32 = opp(tmp129);
	let tmp179: f32 = (tmp178 / tmp175);
	let tmp389: t_carving_consts = c_carving_consts;
	let tmp267: f32 = min(tmp261, tmp258);
	let tmp185: f32 = (tmp183 - tmp412.v_value);
	let tmp098: f32 = min(tmp100, tmp096);
	let tmp065: f32 = (tmp066.w + tmp069);
	let tmp008: f32 = min(tmp010, tmp009.v_value);
	let tmp169: f32 = (tmp166 + tmp170);
	let tmp004: f32 = length(tmp007);
	let tmp283: f32 = max(tmp098, tmp282);
	let tmp293: t_zero = c_zero;
	let tmp286: t_zero = c_zero;
	let tmp299: t_zero = c_zero;
	let tmp273: f32 = max(tmp169, tmp179);
	let tmp067: f32 = min(tmp069, tmp065);
	let tmp063: f32 = (tmp062 - tmp389.v_hole_radius);
	let tmp034: f32 = min(tmp036, tmp032);
	let tmp296: t_zero = c_zero;
	let tmp276: f32 = min(tmp267, tmp264);
	let tmp270: f32 = max(tmp182, tmp185);
	let tmp001: f32 = (tmp002.w + (tmp008 + tmp004));
	let tmp005: f32 = (tmp008 + tmp004);
	let tmp289: f32 = opp(tmp276);
	let tmp279: f32 = max(tmp273, tmp270);
	let tmp295: f32 = (tmp283 + tmp296.v_value);
	let tmp292: f32 = (tmp063 + tmp293.v_value);
	let tmp003: f32 = min(tmp005, tmp001);
	let tmp285: f32 = (tmp067 + tmp286.v_value);
	let tmp298: f32 = (tmp034 + tmp299.v_value);
	let tmp302: f32 = min(tmp003, tmp285);
	let tmp339: f32 = opp(tmp298);
	let tmp290: f32 = max(tmp279, tmp289);
	let tmp336: f32 = min(tmp295, tmp292);
	let tmp333: t_zero = c_zero;
	let tmp340: f32 = max(tmp302, tmp339);
	let tmp343: t_zero = c_zero;
	let tmp346: f32 = opp(tmp336);
	let tmp332: f32 = (tmp290 + tmp333.v_value);
	let tmp347: f32 = max(tmp340, tmp346);
	let tmp342: f32 = (tmp332 + tmp343.v_value);
	let tmp350: f32 = min(tmp347, tmp342);
	return t_outlet(tmp350);
}

