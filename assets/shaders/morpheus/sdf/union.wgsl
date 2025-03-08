fn signed_distance_function(pos: vec3<f32>) -> f32 {
    let aa = length(pos - vec3(.2, 0, 0)) - 0.6;
    let bb = length(pos + vec3(.2, 0, 0)) - 0.6;
    return min(aa, bb);
}