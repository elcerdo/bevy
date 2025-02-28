fn signed_distance_function(pos_: vec3<f32>) -> f32 {
    let pos = pos_ - vec3(0.0, 0.0, 2.0);
    let aa = length(pos - vec3(.2, 0, 0)) - 0.6;
    let bb = length(pos + vec3(.2, 0, 0)) - 0.6;
    return min(aa, bb);
}