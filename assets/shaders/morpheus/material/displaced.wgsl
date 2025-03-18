// Morpheus displaced shader

#import bevy_pbr::{
    mesh_functions,
    view_transformations,
}

// @group(2) @binding(0) var pattern: texture_storage_2d<rgba32float, read>;
@group(2) @binding(0) var pattern_texture: texture_2d<f32>;
@group(2) @binding(1) var pattern_sampler: sampler;

struct Vertex {
    @builtin(instance_index) instance_index: u32,
    @builtin(vertex_index) vertex_index: u32,
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) world_position: vec3<f32>,
    @location(1) world_normal: vec3<f32>,
}

@vertex
fn vertex(in: Vertex) -> VertexOutput {

    let ii: u32 = in.vertex_index / 4;
    // let loc = vec2(f32(ii / 8), f32(ii % 8)) / 7.0;
    // var color_ = textureLoad(pattern_texture, pattern_sampler, loc);
    let loc = vec2(u32(ii / 8) * 128 + 64, u32(ii % 8) * 128 + 64);
    var color_: vec4<f32> = textureLoad(pattern_texture, loc, 0);
    
    var pos = in.position;
    pos.x += 2 * color_.x;
    pos.z += 2 * color_.y;

    let world_from_local = mesh_functions::get_world_from_local(in.instance_index);
    var out: VertexOutput;
    out.world_position = mesh_functions::mesh_position_local_to_world(world_from_local, vec4(pos, 1.0)).xyz;
    out.world_normal = mesh_functions::mesh_normal_local_to_world(in.normal, in.instance_index);
    out.clip_position = view_transformations::position_world_to_clip(out.world_position);
    return out;
}

@fragment
fn fragment(
    in: VertexOutput,
) -> @location(0) vec4<f32> {
    // let eye_position = view_transformations::position_ndc_to_world(vec3(0.0, 0.0, -1.0));
    // let world_direction = normalize(in.world_position - eye_position);

    // var pos = in.world_position - bbox_center;
    // var dist = signed_distance_function(pos);
    // for (var kk=0; kk<64; kk++) {
    //     if (dist <= 0.0) { break; }
    //     if (length(pos) > sqrt(3.0)) { break; }
    //     pos += world_direction * dist;
    //     dist = signed_distance_function(pos);
    // }

    // if dist > 1e-3 {
    //     return vec4(0.0);
    // }

    // let hh = 1e-3;
    // let world_grad = normalize(vec3(
    //     signed_distance_function(pos + vec3(hh, 0.0, 0.0)) - signed_distance_function(pos - vec3(hh, 0.0, 0.0)), 
    //     signed_distance_function(pos + vec3(0.0, hh, 0.0)) - signed_distance_function(pos - vec3(0.0, hh, 0.0)), 
    //     signed_distance_function(pos + vec3(0.0, 0.0, hh)) - signed_distance_function(pos - vec3(0.0, 0.0, hh)), 
    // ));
    // let view_grad = normalize(view_transformations::direction_world_to_view(world_grad));
    // var color = textureSample(matcap_texture, matcap_sampler, (view_grad.xy + 1.0) / 2.0);

    let color = vec4(1.0);
    
    return color;
}
