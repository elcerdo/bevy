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

struct t_main_shape {
	v_height: f32,
	v_radius: f32,
	v_min: f32,
	v_max: f32,
	v_int: f32,
	v_thickness: f32,
}

struct t_material {
	v_col_a: f32,
	v_col_b: vec3<f32>,
	v_rough_a: f32,
	v_rough_b: f32,
	v_o4: f32,
	v_o5: f32,
}

struct t_middle_lines {
	v_freq: f32,
	v_pos: f32,
	v_contrast: f32,
	v_int: f32,
}

struct t_interior {
	v_offset: f32,
	v_smoothing: f32,
	v_o2: f32,
}

struct t_cylinders_top_down {
	v_height: f32,
	v_rad: f32,
}

struct t_debug_params {
	v_o0: vec3<f32>,
	v_o1: f32,
}

struct t_minus_one {
	v_value: f32,
}

struct t_half {
	v_value: f32,
}

struct t_one {
	v_value: f32,
}

struct t_zero {
	v_value: f32,
}

struct t_position {
	v_pos: vec3<f32>,
}
struct t_outlet {
	v_dist: f32,
	v_basecolor: vec3<f32>,
	v_roughness: f32,
	v_metallic: f32,
}

//// INSTANCES

const u_main_shape: t_main_shape = t_main_shape(f32(0.41), f32(0.395), f32(0.04), f32(0.09), f32(0.06), f32(0.004));
const u_material: t_material = t_material(f32(0.65), vec3(0.537, 0.352, 0.107), f32(0.2), f32(0.11), f32(0.5), f32(0.5));
const u_middle_lines: t_middle_lines = t_middle_lines(f32(30), f32(0.153), f32(0.896), f32(0.06));
const u_interior: t_interior = t_interior(f32(-0.1), f32(0.2), f32(0.535));
const u_cylinders_top_down: t_cylinders_top_down = t_cylinders_top_down(f32(0.017), f32(0.009));
const u_debug_params: t_debug_params = t_debug_params(vec3(-1, -1, 0), f32(-0.19));

const c_minus_one: t_minus_one = t_minus_one(f32(-1));
const c_half: t_half = t_half(f32(0.5));
const c_one: t_one = t_one(f32(1));
const c_zero: t_zero = t_zero(f32(0));

//// IMPLEMENTATIONS

// FID[0346] ComposeFuncType::Terminal main:(v3 pos)->(sc dist,v3 basecolor,sc roughness,sc metallic)
// FID[0347] ComposeFuncType::Inlet position:()->(v3 pos)
// FID[0348] ComposeFuncType::Outlet outlet:(sc dist,v3 basecolor,sc roughness,sc metallic)->()
fn compute_main_digraph(a_pos: vec3<f32>) -> t_outlet {
	let tmp049: t_position = t_position(a_pos);
	let tmp035: t_zero = c_zero;
	let tmp063: t_one = c_one;
	let tmp036: vec3<f32> = vec3<f32>(tmp035.v_value, tmp063.v_value, tmp035.v_value);
	let tmp052: vec3<f32> = tmp049.v_pos;
	let tmp056: f32 = (tmp052.y / u_main_shape.v_height);
	let tmp057: t_one = c_one;
	let tmp068: vec3<f32> = (tmp036 * u_middle_lines.v_freq);
	let tmp054: t_half = c_half;
	let tmp055: f32 = (tmp056 + tmp057.v_value);
	let tmp064: f32 = dot(t_position(a_pos).v_pos, tmp068);
	let tmp047: t_one = c_one;
	let tmp051: t_zero = c_zero;
	let tmp065: f32 = (tmp064 + u_middle_lines.v_freq);
	let tmp053: f32 = (tmp055 * tmp054.v_value);
	let tmp067: t_half = c_half;
	let tmp050: t_one = c_one;
	let tmp040: f32 = (u_middle_lines.v_pos * u_middle_lines.v_contrast);
	let tmp062: t_middle_lines = u_middle_lines;
	let tmp039: f32 = (tmp047.v_value - tmp040);
	let tmp041: f32 = (tmp062.v_pos * tmp062.v_contrast);
	let tmp059: t_zero = c_zero;
	let tmp046: f32 = (tmp047.v_value - tmp062.v_pos);
	let tmp066: f32 = (tmp065 * tmp067.v_value);
	let tmp058: f32 = smoothstep(tmp051.v_value, tmp050.v_value, tmp053);
	let tmp069: f32 = fractOfPositiveAndNegativeValue(tmp066);
	let tmp061: f32 = smoothstep(tmp062.v_pos, tmp041, tmp058);
	let tmp048: f32 = smoothstep(tmp046, tmp039, tmp058);
	let tmp116: t_one = c_one;
	let tmp074: f32 = (c_one.v_value - tmp059.v_value);
	let tmp076: t_half = c_half;
	let tmp095: t_one = c_one;
	let tmp104: vec3<f32> = ((((t_position(a_pos).v_pos * c_one.v_value) * tmp095.v_value) * c_one.v_value) * vec3<f32>(u_middle_lines.v_int, c_zero.v_value, u_middle_lines.v_int));
	let tmp102: vec3<f32> = (tmp104 * (smoothstep((c_one.v_value - c_one.v_value), min(((c_one.v_value - c_one.v_value) + tmp074), c_one.v_value), abs((tmp069 - tmp076.v_value))) * abs((c_one.v_value - (tmp061 + tmp048)))));
	let tmp099: t_one = c_one;
	let tmp073: t_one = c_one;
	let tmp027: t_minus_one = c_minus_one;
	let tmp096: vec3<f32> = ((t_position(a_pos).v_pos * c_one.v_value) * tmp095.v_value);
	let tmp060: t_one = c_one;
	let tmp044: t_one = c_one;
	let tmp115: vec3<f32> = (((tmp096 * tmp099.v_value) * c_one.v_value) * tmp116.v_value);
	let tmp071: f32 = ((tmp073.v_value - tmp060.v_value) + tmp074);
	let tmp113: vec3<f32> = (((tmp096 * tmp099.v_value) - tmp102) * vec3<f32>(u_main_shape.v_int, c_zero.v_value, u_main_shape.v_int));
	let tmp045: f32 = (tmp061 + tmp048);
	let tmp077: f32 = (tmp069 - tmp076.v_value);
	let tmp079: vec3<f32> = t_position(a_pos).v_pos;
	let tmp149: vec2<f32> = vec2<f32>((tmp115 - vec3<f32>(c_zero.v_value, u_main_shape.v_height, c_zero.v_value)).x, (tmp115 - vec3<f32>(c_zero.v_value, u_main_shape.v_height, c_zero.v_value)).z);
	let tmp119: vec3<f32> = (tmp115 - vec3<f32>(c_zero.v_value, u_main_shape.v_height, c_zero.v_value));
	let tmp084: t_one = c_one;
	let tmp031: t_zero = c_zero;
	let tmp043: f32 = (tmp044.v_value - tmp045);
	let tmp098: vec3<f32> = (tmp096 * tmp099.v_value);
	let tmp283: t_one = c_one;
	let tmp025: t_zero = c_zero;
	let tmp037: t_middle_lines = u_middle_lines;
	let tmp252: t_one = c_one;
	let tmp135: vec2<f32> = vec2<f32>((tmp115 - vec3<f32>(tmp025.v_value, (u_main_shape.v_height * tmp027.v_value), tmp025.v_value)).x, (tmp115 - vec3<f32>(tmp025.v_value, (u_main_shape.v_height * tmp027.v_value), tmp025.v_value)).z);
	let tmp075: f32 = min(tmp071, tmp073.v_value);
	let tmp203: vec3<f32> = ((t_position(a_pos).v_pos * c_one.v_value) * vec3<f32>(tmp037.v_int, c_zero.v_value, tmp037.v_int));
	let tmp122: vec3<f32> = (tmp115 - vec3<f32>(tmp025.v_value, (u_main_shape.v_height * tmp027.v_value), tmp025.v_value));
	let tmp078: f32 = abs(tmp077);
	let tmp103: vec3<f32> = (tmp098 - tmp102);
	let tmp072: f32 = (tmp073.v_value - tmp060.v_value);
	let tmp083: f32 = (tmp079.y / u_main_shape.v_height);
	let tmp271: vec3<f32> = (((((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * tmp252.v_value) * c_one.v_value) * vec3<f32>(tmp037.v_int, c_zero.v_value, tmp037.v_int));
	let tmp108: t_one = c_one;
	let tmp000: t_zero = c_zero;
	let tmp028: f32 = (u_main_shape.v_height * tmp027.v_value);
	let tmp111: vec3<f32> = (tmp113 * smoothstep(u_main_shape.v_min, u_main_shape.v_max, ((tmp083 + tmp084.v_value) * c_half.v_value)));
	let tmp107: vec3<f32> = (tmp098 * tmp108.v_value);
	let tmp282: vec3<f32> = ((((((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * tmp252.v_value) * c_one.v_value) * c_one.v_value) * tmp283.v_value);
	let tmp112: vec3<f32> = (tmp103 - tmp111);
	let tmp134: f32 = length(tmp135);
	let tmp253: vec3<f32> = (((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * tmp252.v_value);
	let tmp001: vec3<f32> = vec3<f32>(tmp037.v_int, tmp000.v_value, tmp037.v_int);
	let tmp280: vec3<f32> = (((tmp253 * c_one.v_value) - (tmp271 * (smoothstep(tmp072, tmp075, tmp078) * abs(tmp043)))) * vec3<f32>(u_main_shape.v_int, c_zero.v_value, u_main_shape.v_int));
	let tmp070: f32 = smoothstep(tmp072, tmp075, tmp078);
	let tmp150: vec3<f32> = tmp119;
	let tmp042: f32 = abs(tmp043);
	let tmp136: vec3<f32> = tmp122;
	let tmp026: vec3<f32> = vec3<f32>(tmp025.v_value, tmp028, tmp025.v_value);
	let tmp163: vec2<f32> = vec2<f32>(tmp112.x, tmp112.z);
	let tmp269: vec3<f32> = (tmp271 * (tmp070 * tmp042));
	let tmp081: t_half = c_half;
	let tmp082: f32 = (tmp083 + tmp084.v_value);
	let tmp201: vec3<f32> = (tmp203 * (tmp070 * tmp042));
	let tmp261: t_one = c_one;
	let tmp032: vec3<f32> = vec3<f32>(tmp031.v_value, u_main_shape.v_height, tmp031.v_value);
	let tmp208: vec3<f32> = (((t_position(a_pos).v_pos * c_one.v_value) - tmp201) * vec3<f32>(u_main_shape.v_int, c_zero.v_value, u_main_shape.v_int));
	let tmp177: vec2<f32> = vec2<f32>(tmp107.x, tmp107.z);
	let tmp148: f32 = length(tmp149);
	let tmp002: t_zero = c_zero;
	let tmp178: vec3<f32> = tmp107;
	let tmp164: vec3<f32> = tmp112;
	let tmp202: vec3<f32> = ((t_position(a_pos).v_pos * c_one.v_value) - tmp201);
	let tmp270: vec3<f32> = ((tmp253 * tmp261.v_value) - tmp269);
	let tmp080: f32 = (tmp082 * tmp081.v_value);
	let tmp302: vec2<f32> = vec2<f32>((tmp282 - tmp026).x, (tmp282 - tmp026).z);
	let tmp289: vec3<f32> = (tmp282 - tmp026);
	let tmp286: vec3<f32> = (tmp282 - tmp032);
	let tmp278: vec3<f32> = (tmp280 * smoothstep(u_main_shape.v_min, u_main_shape.v_max, tmp080));
	let tmp275: t_one = c_one;
	let tmp258: vec3<f32> = (((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) * tmp001);
	let tmp132: vec2<f32> = vec2<f32>(tmp134, tmp136.y);
	let tmp176: f32 = length(tmp177);
	let tmp146: vec2<f32> = vec2<f32>(tmp148, tmp150.y);
	let tmp206: vec3<f32> = (tmp208 * smoothstep(u_main_shape.v_min, u_main_shape.v_max, tmp080));
	let tmp162: f32 = length(tmp163);
	let tmp003: vec3<f32> = vec3<f32>(u_main_shape.v_int, tmp002.v_value, u_main_shape.v_int);
	let tmp038: f32 = (tmp070 * tmp042);
	let tmp316: vec2<f32> = vec2<f32>(tmp286.x, tmp286.z);
	let tmp260: vec3<f32> = (tmp253 * tmp261.v_value);
	let tmp301: f32 = length(tmp302);
	let tmp274: vec3<f32> = (tmp260 * tmp275.v_value);
	let tmp133: vec2<f32> = vec2<f32>((u_cylinders_top_down.v_rad + u_main_shape.v_radius), u_cylinders_top_down.v_height);
	let tmp221: vec2<f32> = vec2<f32>((tmp202 - tmp206).x, (tmp202 - tmp206).z);
	let tmp266: vec3<f32> = ((((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) - (tmp258 * tmp038)) * tmp003);
	let tmp145: vec2<f32> = abs(tmp146);
	let tmp207: vec3<f32> = (tmp202 - tmp206);
	let tmp279: vec3<f32> = (tmp270 - tmp278);
	let tmp344: vec2<f32> = vec2<f32>(tmp274.x, tmp274.z);
	let tmp317: vec3<f32> = tmp286;
	let tmp160: vec2<f32> = vec2<f32>(tmp162, tmp164.y);
	let tmp147: vec2<f32> = vec2<f32>(((u_main_shape.v_radius + u_cylinders_top_down.v_rad) + (u_main_shape.v_radius * u_main_shape.v_int)), u_cylinders_top_down.v_height);
	let tmp256: vec3<f32> = (tmp258 * tmp038);
	let tmp085: f32 = smoothstep(u_main_shape.v_min, u_main_shape.v_max, tmp080);
	let tmp303: vec3<f32> = tmp289;
	let tmp330: vec2<f32> = vec2<f32>(tmp279.x, tmp279.z);
	let tmp131: vec2<f32> = abs(tmp132);
	let tmp033: f32 = (u_main_shape.v_radius + u_cylinders_top_down.v_rad);
	let tmp023: f32 = (u_main_shape.v_radius * u_main_shape.v_int);
	let tmp174: vec2<f32> = vec2<f32>(tmp176, tmp178.y);
	let tmp315: f32 = length(tmp316);
	let tmp022: f32 = (u_cylinders_top_down.v_rad + u_main_shape.v_radius);
	let tmp173: vec2<f32> = abs(tmp174);
	let tmp024: f32 = (tmp033 + tmp023);
	let tmp264: vec3<f32> = (tmp266 * tmp085);
	let tmp144: vec2<f32> = (tmp145 - tmp147);
	let tmp159: vec2<f32> = abs(tmp160);
	let tmp125: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp257: vec3<f32> = (((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value) - tmp256);
	let tmp222: vec3<f32> = tmp207;
	let tmp130: vec2<f32> = (tmp131 - tmp133);
	let tmp220: f32 = length(tmp221);
	let tmp331: vec3<f32> = tmp279;
	let tmp175: vec2<f32> = vec2<f32>(u_main_shape.v_radius, (u_main_shape.v_height + u_main_shape.v_height));
	let tmp034: t_cylinders_top_down = u_cylinders_top_down;
	let tmp345: vec3<f32> = tmp274;
	let tmp329: f32 = length(tmp330);
	let tmp343: f32 = length(tmp344);
	let tmp139: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp299: vec2<f32> = vec2<f32>(tmp301, tmp303.y);
	let tmp161: vec2<f32> = vec2<f32>(u_main_shape.v_radius, u_main_shape.v_height);
	let tmp313: vec2<f32> = vec2<f32>(tmp315, tmp317.y);
	let tmp218: vec2<f32> = vec2<f32>(tmp220, tmp222.y);
	let tmp129: f32 = vmax2(tmp130);
	let tmp153: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp358: vec2<f32> = vec2<f32>((tmp257 - tmp264).x, (tmp257 - tmp264).z);
	let tmp167: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp128: t_zero = c_zero;
	let tmp142: t_zero = c_zero;
	let tmp298: vec2<f32> = abs(tmp299);
	let tmp265: vec3<f32> = (tmp257 - tmp264);
	let tmp029: f32 = (u_main_shape.v_height + u_main_shape.v_height);
	let tmp030: t_main_shape = u_main_shape;
	let tmp341: vec2<f32> = vec2<f32>(tmp343, tmp345.y);
	let tmp172: vec2<f32> = (tmp173 - tmp175);
	let tmp158: vec2<f32> = (tmp159 - tmp161);
	let tmp327: vec2<f32> = vec2<f32>(tmp329, tmp331.y);
	let tmp126: vec2<f32> = max(tmp130, tmp125);
	let tmp140: vec2<f32> = max(tmp144, tmp139);
	let tmp182: f32 = opp((((min(vmax2((abs(tmp218) - vec2<f32>(u_main_shape.v_radius, u_main_shape.v_height))), c_zero.v_value) + length(max((abs(tmp218) - vec2<f32>(u_main_shape.v_radius, u_main_shape.v_height)), vec2<f32>(c_zero.v_value, c_zero.v_value)))) + c_zero.v_value) + c_zero.v_value));
	let tmp314: vec2<f32> = vec2<f32>(tmp024, tmp034.v_height);
	let tmp143: f32 = vmax2(tmp144);
	let tmp312: vec2<f32> = abs(tmp313);
	let tmp300: vec2<f32> = vec2<f32>(tmp022, tmp034.v_height);
	let tmp157: f32 = vmax2(tmp158);
	let tmp359: vec3<f32> = tmp265;
	let tmp168: vec2<f32> = max(tmp172, tmp167);
	let tmp297: vec2<f32> = (tmp298 - tmp300);
	let tmp141: f32 = min(tmp143, tmp142.v_value);
	let tmp137: f32 = length(tmp140);
	let tmp217: vec2<f32> = abs(tmp218);
	let tmp292: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp156: t_zero = c_zero;
	let tmp328: vec2<f32> = vec2<f32>(u_main_shape.v_radius, u_main_shape.v_height);
	let tmp171: f32 = vmax2(tmp172);
	let tmp326: vec2<f32> = abs(tmp327);
	let tmp170: t_zero = c_zero;
	let tmp342: vec2<f32> = vec2<f32>(tmp030.v_radius, tmp029);
	let tmp127: f32 = min(tmp129, tmp128.v_value);
	let tmp154: vec2<f32> = max(tmp158, tmp153);
	let tmp123: f32 = length(tmp126);
	let tmp340: vec2<f32> = abs(tmp341);
	let tmp219: vec2<f32> = vec2<f32>(u_main_shape.v_radius, u_main_shape.v_height);
	let tmp311: vec2<f32> = (tmp312 - tmp314);
	let tmp196: f32 = (tmp182 - (dot((t_position(a_pos).v_pos * c_one.v_value), normalize(vec3<f32>(c_zero.v_value, c_minus_one.v_value, c_zero.v_value))) - u_interior.v_offset));
	let tmp306: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp357: f32 = length(tmp358);
	let tmp138: f32 = (tmp141 + tmp137);
	let tmp233: f32 = opp((((min(vmax2((abs(vec2<f32>(tmp357, tmp359.y)) - vec2<f32>(u_main_shape.v_radius, u_main_shape.v_height))), c_zero.v_value) + length(max((abs(vec2<f32>(tmp357, tmp359.y)) - vec2<f32>(u_main_shape.v_radius, u_main_shape.v_height)), vec2<f32>(c_zero.v_value, c_zero.v_value)))) + c_zero.v_value) + c_zero.v_value));
	let tmp211: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp186: f32 = abs(tmp196);
	let tmp086: t_main_shape = u_main_shape;
	let tmp169: f32 = min(tmp171, tmp170.v_value);
	let tmp165: f32 = length(tmp168);
	let tmp155: f32 = min(tmp157, tmp156.v_value);
	let tmp151: f32 = length(tmp154);
	let tmp355: vec2<f32> = vec2<f32>(tmp357, tmp359.y);
	let tmp124: f32 = (tmp127 + tmp123);
	let tmp120: t_zero = c_zero;
	let tmp320: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp117: t_zero = c_zero;
	let tmp295: t_zero = c_zero;
	let tmp309: t_zero = c_zero;
	let tmp325: vec2<f32> = (tmp326 - tmp328);
	let tmp334: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp339: vec2<f32> = (tmp340 - tmp342);
	let tmp310: f32 = vmax2(tmp311);
	let tmp307: vec2<f32> = max(tmp311, tmp306);
	let tmp216: vec2<f32> = (tmp217 - tmp219);
	let tmp296: f32 = vmax2(tmp297);
	let tmp293: vec2<f32> = max(tmp297, tmp292);
	let tmp335: vec2<f32> = max(tmp339, tmp334);
	let tmp118: f32 = (tmp138 + tmp117.v_value);
	let tmp356: vec2<f32> = vec2<f32>(tmp086.v_radius, tmp086.v_height);
	let tmp166: f32 = (tmp169 + tmp165);
	let tmp195: f32 = (u_interior.v_smoothing - tmp186);
	let tmp308: f32 = min(tmp310, tmp309.v_value);
	let tmp354: vec2<f32> = abs(tmp355);
	let tmp152: f32 = (tmp155 + tmp151);
	let tmp193: t_zero = c_zero;
	let tmp294: f32 = min(tmp296, tmp295.v_value);
	let tmp215: f32 = vmax2(tmp216);
	let tmp321: vec2<f32> = max(tmp325, tmp320);
	let tmp212: vec2<f32> = max(tmp216, tmp211);
	let tmp324: f32 = vmax2(tmp325);
	let tmp290: f32 = length(tmp293);
	let tmp247: f32 = (tmp233 - (dot(((t_position(a_pos).v_pos * c_one.v_value) * c_one.v_value), normalize(vec3<f32>(c_zero.v_value, c_minus_one.v_value, c_zero.v_value))) - u_interior.v_offset));
	let tmp109: t_zero = c_zero;
	let tmp337: t_zero = c_zero;
	let tmp323: t_zero = c_zero;
	let tmp214: t_zero = c_zero;
	let tmp338: f32 = vmax2(tmp339);
	let tmp121: f32 = (tmp124 + tmp120.v_value);
	let tmp198: t_one = c_one;
	let tmp304: f32 = length(tmp307);
	let tmp287: t_zero = c_zero;
	let tmp291: f32 = (tmp294 + tmp290);
	let tmp237: f32 = abs(tmp247);
	let tmp194: f32 = max(tmp195, tmp193.v_value);
	let tmp305: f32 = (tmp308 + tmp304);
	let tmp353: vec2<f32> = (tmp354 - tmp356);
	let tmp014: t_position = t_position(a_pos);
	let tmp332: f32 = length(tmp335);
	let tmp224: vec3<f32> = normalize(vec3<f32>(c_zero.v_value, c_minus_one.v_value, c_zero.v_value));
	let tmp209: f32 = length(tmp212);
	let tmp322: f32 = min(tmp324, tmp323.v_value);
	let tmp213: f32 = min(tmp215, tmp214.v_value);
	let tmp318: f32 = length(tmp321);
	let tmp015: t_minus_one = c_minus_one;
	let tmp197: vec3<f32> = (tmp014.v_pos * tmp198.v_value);
	let tmp114: f32 = min(tmp118, tmp121);
	let tmp110: f32 = (tmp152 + tmp109.v_value);
	let tmp348: vec2<f32> = vec2<f32>(c_zero.v_value, c_zero.v_value);
	let tmp106: f32 = opp(tmp166);
	let tmp100: t_zero = c_zero;
	let tmp016: t_zero = c_zero;
	let tmp284: t_zero = c_zero;
	let tmp336: f32 = min(tmp338, tmp337.v_value);
	let tmp092: t_one = c_one;
	let tmp333: f32 = (tmp336 + tmp332);
	let tmp105: f32 = max(tmp114, tmp106);
	let tmp101: f32 = (tmp110 + tmp100.v_value);
	let tmp244: t_zero = c_zero;
	let tmp352: f32 = vmax2(tmp353);
	let tmp246: f32 = (u_interior.v_smoothing - tmp237);
	let tmp285: f32 = (tmp305 + tmp284.v_value);
	let tmp249: t_one = c_one;
	let tmp204: t_zero = c_zero;
	let tmp088: t_position = t_position(a_pos);
	let tmp351: t_zero = c_zero;
	let tmp210: f32 = (tmp213 + tmp209);
	let tmp091: vec3<f32> = (tmp014.v_pos * tmp092.v_value);
	let tmp180: vec3<f32> = normalize(u_debug_params.v_o0);
	let tmp276: t_zero = c_zero;
	let tmp288: f32 = (tmp291 + tmp287.v_value);
	let tmp319: f32 = (tmp322 + tmp318);
	let tmp192: f32 = (tmp194 / u_interior.v_smoothing);
	let tmp349: vec2<f32> = max(tmp353, tmp348);
	let tmp225: f32 = dot(tmp197, tmp224);
	let tmp228: t_one = c_one;
	let tmp017: vec3<f32> = vec3<f32>(tmp016.v_value, tmp015.v_value, tmp016.v_value);
	let tmp361: vec3<f32> = normalize(tmp017);
	let tmp181: f32 = dot(tmp091, tmp180);
	let tmp191: f32 = (tmp192 * tmp192);
	let tmp267: t_zero = c_zero;
	let tmp350: f32 = min(tmp352, tmp351.v_value);
	let tmp245: f32 = max(tmp246, tmp244.v_value);
	let tmp097: f32 = min(tmp101, tmp105);
	let tmp281: f32 = min(tmp285, tmp288);
	let tmp248: vec3<f32> = ((tmp088.v_pos * tmp228.v_value) * tmp249.v_value);
	let tmp227: vec3<f32> = (tmp088.v_pos * tmp228.v_value);
	let tmp189: t_half = c_half;
	let tmp199: t_zero = c_zero;
	let tmp277: f32 = (tmp319 + tmp276.v_value);
	let tmp273: f32 = opp(tmp333);
	let tmp205: f32 = (tmp210 + tmp204.v_value);
	let tmp223: f32 = (tmp225 - u_interior.v_offset);
	let tmp346: f32 = length(tmp349);
	let tmp232: t_one = c_one;
	let tmp183: f32 = opp(tmp223);
	let tmp362: f32 = dot(tmp248, tmp361);
	let tmp272: f32 = max(tmp281, tmp273);
	let tmp188: f32 = (tmp189.v_value * tmp189.v_value);
	let tmp262: t_zero = c_zero;
	let tmp268: f32 = (tmp277 + tmp267.v_value);
	let tmp347: f32 = (tmp350 + tmp346);
	let tmp179: f32 = (tmp181 - u_debug_params.v_o1);
	let tmp094: f32 = abs(tmp097);
	let tmp200: f32 = (tmp205 + tmp199.v_value);
	let tmp231: vec3<f32> = (tmp227 * tmp232.v_value);
	let tmp243: f32 = (tmp245 / u_interior.v_smoothing);
	let tmp190: f32 = (tmp191 * u_interior.v_smoothing);
	let tmp364: vec3<f32> = normalize(u_debug_params.v_o0);
	let tmp090: f32 = opp(tmp179);
	let tmp093: f32 = (tmp094 - u_main_shape.v_thickness);
	let tmp263: f32 = (tmp347 + tmp262.v_value);
	let tmp259: f32 = min(tmp268, tmp272);
	let tmp187: f32 = (tmp190 * tmp188);
	let tmp254: t_zero = c_zero;
	let tmp185: f32 = max(tmp200, tmp183);
	let tmp020: t_debug_params = u_debug_params;
	let tmp240: t_half = c_half;
	let tmp018: t_interior = u_interior;
	let tmp242: f32 = (tmp243 * tmp243);
	let tmp365: f32 = dot(tmp231, tmp364);
	let tmp360: f32 = (tmp362 - tmp018.v_offset);
	let tmp089: f32 = max(tmp093, tmp090);
	let tmp234: f32 = opp(tmp360);
	let tmp021: t_main_shape = u_main_shape;
	let tmp251: f32 = abs(tmp259);
	let tmp241: f32 = (tmp242 * tmp018.v_smoothing);
	let tmp255: f32 = (tmp263 + tmp254.v_value);
	let tmp363: f32 = (tmp365 - tmp020.v_o1);
	let tmp184: f32 = (tmp185 + tmp187);
	let tmp239: f32 = (tmp240.v_value * tmp240.v_value);
	let tmp250: f32 = (tmp251 - tmp021.v_thickness);
	let tmp013: f32 = (tmp184 - tmp089);
	let tmp012: t_zero = c_zero;
	let tmp238: f32 = (tmp241 * tmp239);
	let tmp230: f32 = opp(tmp363);
	let tmp236: f32 = max(tmp255, tmp234);
	let tmp009: t_material = u_material;
	let tmp008: vec3<f32> = vec3<f32>(tmp009.v_col_a, tmp009.v_col_a, tmp009.v_col_a);
	let tmp005: t_zero = c_zero;
	let tmp004: t_one = c_one;
	let tmp229: f32 = max(tmp250, tmp230);
	let tmp019: vec3<f32> = vec3<f32>(step(tmp012.v_value, tmp013), step(tmp012.v_value, tmp013), step(tmp012.v_value, tmp013));
	let tmp011: f32 = step(tmp012.v_value, tmp013);
	let tmp235: f32 = (tmp236 + tmp238);
	let tmp007: f32 = mix(tmp009.v_rough_b, tmp009.v_rough_a, tmp011);
	let tmp006: f32 = mix(tmp005.v_value, tmp004.v_value, tmp011);
	let tmp226: f32 = min(tmp235, tmp229);
	let tmp010: vec3<f32> = mix(tmp009.v_col_b, tmp008, tmp019);
	return t_outlet(tmp226, tmp010, tmp007, tmp006);
}

